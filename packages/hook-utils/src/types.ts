/**
 * Raw JSON received on stdin from Claude Code hook system.
 * Shape varies by hook event type.
 */
export interface HookInput {
  /** The hook event type (PreToolUse, PostToolUse, etc.) */
  hook_event?: string;
  /** Tool name being invoked */
  tool_name?: string;
  /** Tool input parameters */
  tool_input?: Record<string, unknown>;
  /** Tool result (PostToolUse only) */
  tool_result?: string;
  /** Whether the tool errored */
  is_error?: boolean;
  /** User prompt text (UserPromptSubmit only) */
  user_prompt?: string;
  /** Session ID */
  session_id?: string;
  /** Additional fields passed by Claude Code */
  [key: string]: unknown;
}

/**
 * Result mode determines exit code and output routing.
 *
 * - allow:   exit 0, no output (hook permits the action or is informational)
 * - block:   exit 2, JSON {"decision":"block","reason":"..."} to stdout
 * - warn:    exit 0, message to stderr (hook advises but doesn't block)
 * - notify:  exit 0, JSON {"decision":"approve","systemMessage":"..."} to stdout
 *            (injects advisory message into Claude's conversation context)
 */
export type HookResultMode = 'allow' | 'block' | 'warn' | 'notify';

/** Result returned by a hook's evaluate() function. */
export interface HookResult {
  mode: HookResultMode;
  /** Reason for blocking — required when mode is 'block' */
  reason?: string;
  /** Warning or info message — used when mode is 'warn' */
  message?: string;
  /** System message injected into conversation — used when mode is 'notify' */
  systemMessage?: string;
}

/** Signature for hook evaluate functions. */
export type HookEvaluateFn = (input: HookInput) => HookResult | Promise<HookResult>;
