#!/usr/bin/env python3
"""MCP Server Evaluation Harness

Runs Q&A pairs against an MCP server using Claude as the agent. Supports stdio,
SSE, and HTTP (streamable) transports. Outputs a markdown report with accuracy
metrics and per-task agent feedback on tool quality.

Usage:
  # stdio — script launches the server automatically
  python evaluation.py -t stdio -c python -a my_server.py evaluation.xml

  # SSE — start server before running
  python evaluation.py -t sse -u https://example.com/mcp \\
    -H "Authorization: Bearer token" evaluation.xml

  # HTTP streamable
  python evaluation.py -t http -u https://example.com/mcp evaluation.xml

  # Save report to file
  python evaluation.py -t stdio -c python -a my_server.py -o report.md evaluation.xml

Requirements:
  pip install anthropic mcp
  export ANTHROPIC_API_KEY=your_key
"""

import argparse
import asyncio
import json
import os
import re
import sys
import time
import traceback
import xml.etree.ElementTree as ET
from abc import ABC, abstractmethod
from contextlib import AsyncExitStack
from pathlib import Path
from typing import Any

from anthropic import Anthropic
from mcp import ClientSession, StdioServerParameters
from mcp.client.sse import sse_client
from mcp.client.stdio import stdio_client
from mcp.client.streamable_http import streamablehttp_client


# ---------------------------------------------------------------------------
# Evaluation prompt
# ---------------------------------------------------------------------------

EVALUATION_PROMPT = """You are an AI assistant with access to tools.

When given a task, you MUST:
1. Use the available tools to complete the task
2. Provide a summary of each step in your approach, wrapped in <summary> tags
3. Provide feedback on the tools provided, wrapped in <feedback> tags
4. Provide your final response, wrapped in <response> tags

Summary Requirements:
- In your <summary> tags, explain:
  - The steps you took to complete the task
  - Which tools you used, in what order, and why
  - The inputs you provided to each tool
  - The outputs you received from each tool
  - How you arrived at the final response

Feedback Requirements:
- In your <feedback> tags, provide constructive feedback on the tools:
  - Comment on tool names: Are they clear and descriptive?
  - Comment on input parameters: Are they well-documented? Are required vs optional clear?
  - Comment on descriptions: Do they accurately describe what the tool does?
  - Comment on errors encountered: Did any tool fail or return too many tokens?
  - Identify specific areas for improvement and explain why they would help
  - Be specific and actionable

Response Requirements:
- Your response should be concise and directly address what was asked
- Always wrap your final response in <response> tags
- If you cannot solve the task, return <response>NOT_FOUND</response>
- For numeric responses, provide just the number
- For IDs, provide just the ID
- For names or text, provide the exact text requested
- Your response should appear last"""


# ---------------------------------------------------------------------------
# MCP connection classes (inlined — no separate connections module required)
# ---------------------------------------------------------------------------

class MCPConnection(ABC):
    """Base class for MCP server connections."""

    def __init__(self):
        self.session = None
        self._stack = None

    @abstractmethod
    def _create_context(self):
        """Create the transport context for this connection type."""

    async def __aenter__(self):
        self._stack = AsyncExitStack()
        await self._stack.__aenter__()
        try:
            ctx = self._create_context()
            result = await self._stack.enter_async_context(ctx)

            if len(result) == 2:
                read, write = result
            elif len(result) == 3:
                read, write, _ = result
            else:
                raise ValueError(f"Unexpected context result length: {len(result)}")

            session_ctx = ClientSession(read, write)
            self.session = await self._stack.enter_async_context(session_ctx)
            await self.session.initialize()
            return self
        except BaseException:
            await self._stack.__aexit__(None, None, None)
            raise

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self._stack:
            await self._stack.__aexit__(exc_type, exc_val, exc_tb)
        self.session = None
        self._stack = None

    async def list_tools(self) -> list[dict[str, Any]]:
        """Retrieve available tools from the MCP server."""
        response = await self.session.list_tools()
        return [
            {
                "name": tool.name,
                "description": tool.description,
                "input_schema": tool.inputSchema,
            }
            for tool in response.tools
        ]

    async def call_tool(self, tool_name: str, arguments: dict[str, Any]) -> Any:
        """Call a tool on the MCP server with the provided arguments."""
        result = await self.session.call_tool(tool_name, arguments=arguments)
        return result.content


class MCPConnectionStdio(MCPConnection):
    """MCP connection via standard input/output (child process)."""

    def __init__(self, command: str, args: list[str] = None, env: dict[str, str] = None):
        super().__init__()
        self.command = command
        self.args = args or []
        self.env = env

    def _create_context(self):
        return stdio_client(
            StdioServerParameters(command=self.command, args=self.args, env=self.env)
        )


class MCPConnectionSSE(MCPConnection):
    """MCP connection via Server-Sent Events."""

    def __init__(self, url: str, headers: dict[str, str] = None):
        super().__init__()
        self.url = url
        self.headers = headers or {}

    def _create_context(self):
        return sse_client(url=self.url, headers=self.headers)


class MCPConnectionHTTP(MCPConnection):
    """MCP connection via Streamable HTTP."""

    def __init__(self, url: str, headers: dict[str, str] = None):
        super().__init__()
        self.url = url
        self.headers = headers or {}

    def _create_context(self):
        return streamablehttp_client(url=self.url, headers=self.headers)


def create_connection(
    transport: str,
    command: str = None,
    args: list[str] = None,
    env: dict[str, str] = None,
    url: str = None,
    headers: dict[str, str] = None,
) -> MCPConnection:
    """Factory: create the appropriate MCPConnection for the given transport.

    Args:
        transport: "stdio", "sse", or "http"
        command:   Command to run (stdio only)
        args:      Command arguments (stdio only)
        env:       Environment variables to pass to the server process (stdio only)
        url:       Server URL (sse and http only)
        headers:   HTTP headers (sse and http only)

    Returns:
        An MCPConnection instance (not yet connected).

    Raises:
        ValueError: If required arguments are missing or transport is unknown.
    """
    transport = transport.lower()

    if transport == "stdio":
        if not command:
            raise ValueError("--command is required for stdio transport")
        return MCPConnectionStdio(command=command, args=args, env=env)

    elif transport == "sse":
        if not url:
            raise ValueError("--url is required for sse transport")
        return MCPConnectionSSE(url=url, headers=headers)

    elif transport in ("http", "streamable_http", "streamable-http"):
        if not url:
            raise ValueError("--url is required for http transport")
        return MCPConnectionHTTP(url=url, headers=headers)

    else:
        raise ValueError(
            f"Unknown transport '{transport}'. Supported: stdio, sse, http"
        )


# ---------------------------------------------------------------------------
# Evaluation file parsing
# ---------------------------------------------------------------------------

def parse_evaluation_file(file_path: Path) -> list[dict[str, Any]]:
    """Parse an XML evaluation file and return a list of question/answer dicts."""
    try:
        tree = ET.parse(file_path)
        root = tree.getroot()
        evaluations = []

        for qa_pair in root.findall(".//qa_pair"):
            question_elem = qa_pair.find("question")
            answer_elem = qa_pair.find("answer")

            if question_elem is not None and answer_elem is not None:
                evaluations.append({
                    "question": (question_elem.text or "").strip(),
                    "answer": (answer_elem.text or "").strip(),
                })

        return evaluations

    except ET.ParseError as e:
        print(f"XML parse error in {file_path}: {e}", file=sys.stderr)
        return []
    except Exception as e:
        print(f"Error reading evaluation file {file_path}: {e}", file=sys.stderr)
        return []


def extract_xml_content(text: str, tag: str) -> str | None:
    """Extract the last occurrence of content within <tag>...</tag>."""
    pattern = rf"<{tag}>(.*?)</{tag}>"
    matches = re.findall(pattern, text, re.DOTALL)
    return matches[-1].strip() if matches else None


# ---------------------------------------------------------------------------
# Agent loop
# ---------------------------------------------------------------------------

async def agent_loop(
    client: Anthropic,
    model: str,
    question: str,
    tools: list[dict[str, Any]],
    connection: MCPConnection,
) -> tuple[str, dict[str, Any]]:
    """Run the agentic tool-use loop until the model produces a final response.

    Returns:
        (response_text, tool_metrics) where tool_metrics maps tool_name to
        {"count": int, "durations": [float, ...]}.
    """
    messages = [{"role": "user", "content": question}]

    response = await asyncio.to_thread(
        client.messages.create,
        model=model,
        max_tokens=4096,
        system=EVALUATION_PROMPT,
        messages=messages,
        tools=tools,
    )
    messages.append({"role": "assistant", "content": response.content})

    tool_metrics: dict[str, dict[str, Any]] = {}

    while response.stop_reason == "tool_use":
        tool_use = next(
            block for block in response.content if block.type == "tool_use"
        )
        tool_name = tool_use.name
        tool_input = tool_use.input

        tool_start = time.time()
        try:
            tool_result = await connection.call_tool(tool_name, tool_input)
            tool_response = (
                json.dumps(tool_result)
                if isinstance(tool_result, (dict, list))
                else str(tool_result)
            )
        except Exception as e:
            tool_response = f"Error executing tool {tool_name}: {e}\n"
            tool_response += traceback.format_exc()
        tool_duration = time.time() - tool_start

        if tool_name not in tool_metrics:
            tool_metrics[tool_name] = {"count": 0, "durations": []}
        tool_metrics[tool_name]["count"] += 1
        tool_metrics[tool_name]["durations"].append(round(tool_duration, 3))

        messages.append({
            "role": "user",
            "content": [{
                "type": "tool_result",
                "tool_use_id": tool_use.id,
                "content": tool_response,
            }],
        })

        response = await asyncio.to_thread(
            client.messages.create,
            model=model,
            max_tokens=4096,
            system=EVALUATION_PROMPT,
            messages=messages,
            tools=tools,
        )
        messages.append({"role": "assistant", "content": response.content})

    response_text = next(
        (block.text for block in response.content if hasattr(block, "text")),
        None,
    )
    return response_text or "", tool_metrics


# ---------------------------------------------------------------------------
# Single task evaluation
# ---------------------------------------------------------------------------

async def evaluate_single_task(
    client: Anthropic,
    model: str,
    qa_pair: dict[str, Any],
    tools: list[dict[str, Any]],
    connection: MCPConnection,
    task_index: int,
) -> dict[str, Any]:
    """Evaluate one QA pair and return a result dict."""
    start_time = time.time()
    print(f"  Task {task_index + 1}: {qa_pair['question'][:80]}...")

    response_text, tool_metrics = await agent_loop(
        client, model, qa_pair["question"], tools, connection
    )

    response_value = extract_xml_content(response_text, "response")
    summary = extract_xml_content(response_text, "summary")
    feedback = extract_xml_content(response_text, "feedback")

    duration = time.time() - start_time
    num_tool_calls = sum(
        len(m["durations"]) for m in tool_metrics.values()
    )

    is_correct = (response_value == qa_pair["answer"]) if response_value else False

    return {
        "question": qa_pair["question"],
        "expected": qa_pair["answer"],
        "actual": response_value,
        "score": int(is_correct),
        "total_duration": duration,
        "tool_calls": tool_metrics,
        "num_tool_calls": num_tool_calls,
        "summary": summary,
        "feedback": feedback,
    }


# ---------------------------------------------------------------------------
# Report generation
# ---------------------------------------------------------------------------

REPORT_HEADER = """\
# Evaluation Report

## Summary

- **Accuracy**: {correct}/{total} ({accuracy:.1f}%)
- **Average task duration**: {avg_duration:.2f}s
- **Average tool calls per task**: {avg_tool_calls:.2f}
- **Total tool calls**: {total_tool_calls}

---
"""

TASK_TEMPLATE = """\

### Task {task_num}

**Question**: {question}
**Expected**: `{expected}`
**Actual**: `{actual}`
**Result**: {indicator}
**Duration**: {duration:.2f}s
**Tool calls**: {tool_call_count}

<details>
<summary>Tool call breakdown</summary>

```json
{tool_calls_json}
```

</details>

**Summary**

{summary}

**Tool feedback**

{feedback}

---"""


def build_report(qa_pairs: list[dict], results: list[dict]) -> str:
    """Build a markdown evaluation report from results."""
    correct = sum(r["score"] for r in results)
    total = len(results)
    accuracy = (correct / total * 100) if total else 0.0
    avg_duration = sum(r["total_duration"] for r in results) / total if total else 0.0
    avg_tool_calls = sum(r["num_tool_calls"] for r in results) / total if total else 0.0
    total_tool_calls = sum(r["num_tool_calls"] for r in results)

    report = REPORT_HEADER.format(
        correct=correct,
        total=total,
        accuracy=accuracy,
        avg_duration=avg_duration,
        avg_tool_calls=avg_tool_calls,
        total_tool_calls=total_tool_calls,
    )

    for i, (qa_pair, result) in enumerate(zip(qa_pairs, results)):
        report += TASK_TEMPLATE.format(
            task_num=i + 1,
            question=qa_pair["question"],
            expected=qa_pair["answer"],
            actual=result["actual"] or "N/A",
            indicator="PASS" if result["score"] else "FAIL",
            duration=result["total_duration"],
            tool_call_count=result["num_tool_calls"],
            tool_calls_json=json.dumps(result["tool_calls"], indent=2),
            summary=result["summary"] or "N/A",
            feedback=result["feedback"] or "N/A",
        )

    return report


# ---------------------------------------------------------------------------
# Main evaluation runner
# ---------------------------------------------------------------------------

async def run_evaluation(
    eval_path: Path,
    connection: MCPConnection,
    model: str = "claude-opus-4-5-20251101",
) -> str:
    """Load tools and Q&A pairs, run all tasks, return the markdown report."""
    print("Starting evaluation...")
    client = Anthropic()

    tools = await connection.list_tools()
    print(f"  Loaded {len(tools)} tools from MCP server")

    qa_pairs = parse_evaluation_file(eval_path)
    if not qa_pairs:
        print("No Q&A pairs found in evaluation file.", file=sys.stderr)
        sys.exit(1)
    print(f"  Loaded {len(qa_pairs)} evaluation tasks")

    results = []
    for i, qa_pair in enumerate(qa_pairs):
        result = await evaluate_single_task(client, model, qa_pair, tools, connection, i)
        results.append(result)
        status = "PASS" if result["score"] else "FAIL"
        print(f"    -> {status} ({result['num_tool_calls']} tool calls, {result['total_duration']:.1f}s)")

    report = build_report(qa_pairs, results)
    correct = sum(r["score"] for r in results)
    print(f"\nAccuracy: {correct}/{len(results)} ({correct / len(results) * 100:.1f}%)")

    return report


# ---------------------------------------------------------------------------
# CLI argument parsing helpers
# ---------------------------------------------------------------------------

def parse_headers(header_list: list[str]) -> dict[str, str]:
    """Parse 'Key: Value' header strings into a dict."""
    headers = {}
    for header in (header_list or []):
        if ":" in header:
            key, value = header.split(":", 1)
            headers[key.strip()] = value.strip()
        else:
            print(f"Warning: ignoring malformed header: {header!r}", file=sys.stderr)
    return headers


def parse_env_vars(env_list: list[str]) -> dict[str, str]:
    """Parse 'KEY=VALUE' environment variable strings into a dict."""
    env = {}
    for entry in (env_list or []):
        if "=" in entry:
            key, value = entry.split("=", 1)
            env[key.strip()] = value.strip()
        else:
            print(f"Warning: ignoring malformed env var: {entry!r}", file=sys.stderr)
    return env


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

async def main():
    parser = argparse.ArgumentParser(
        description="Evaluate MCP servers using Q&A pairs",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python evaluation.py -t stdio -c python -a my_server.py eval.xml
  python evaluation.py -t sse -u https://example.com/mcp -H "Authorization: Bearer tok" eval.xml
  python evaluation.py -t http -u https://example.com/mcp -o report.md eval.xml
        """,
    )

    parser.add_argument(
        "eval_file",
        type=Path,
        help="Path to evaluation XML file",
    )
    parser.add_argument(
        "-t", "--transport",
        choices=["stdio", "sse", "http"],
        default="stdio",
        help="Transport type (default: stdio)",
    )
    parser.add_argument(
        "-m", "--model",
        default="claude-opus-4-5-20251101",
        help="Claude model to use (default: claude-opus-4-5-20251101)",
    )
    parser.add_argument(
        "-o", "--output",
        type=Path,
        help="Write report to this file instead of stdout",
    )

    stdio_group = parser.add_argument_group("stdio options")
    stdio_group.add_argument("-c", "--command", help="Command to launch the MCP server")
    stdio_group.add_argument("-a", "--args", nargs="+", help="Arguments for the server command")
    stdio_group.add_argument(
        "-e", "--env",
        nargs="+",
        metavar="KEY=VALUE",
        help="Environment variables to pass to the server process",
    )

    remote_group = parser.add_argument_group("sse/http options")
    remote_group.add_argument("-u", "--url", help="MCP server URL")
    remote_group.add_argument(
        "-H", "--header",
        nargs="+",
        dest="headers",
        metavar="'Key: Value'",
        help="HTTP headers",
    )

    args = parser.parse_args()

    if not args.eval_file.exists():
        print(f"Error: evaluation file not found: {args.eval_file}", file=sys.stderr)
        sys.exit(1)

    headers = parse_headers(args.headers) if args.headers else None
    env_vars = parse_env_vars(args.env) if args.env else None

    try:
        connection = create_connection(
            transport=args.transport,
            command=args.command,
            args=args.args,
            env=env_vars,
            url=args.url,
            headers=headers,
        )
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"Connecting via {args.transport}...")

    async with connection:
        print("Connected.")
        report = await run_evaluation(args.eval_file, connection, args.model)

    if args.output:
        args.output.write_text(report, encoding="utf-8")
        print(f"Report written to {args.output}")
    else:
        print("\n" + report)


if __name__ == "__main__":
    asyncio.run(main())
