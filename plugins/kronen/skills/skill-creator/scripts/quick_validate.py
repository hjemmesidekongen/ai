#!/usr/bin/env python3
"""Quick validation script for skills — no external dependencies."""

import re
import sys
from pathlib import Path


def parse_frontmatter(content):
    """Extract YAML frontmatter as a dict using regex (no pyyaml needed)."""
    match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return None
    text = match.group(1)
    # Simple top-level key extraction (handles string, bool, int, list markers)
    result = {}
    for line in text.split("\n"):
        m = re.match(r"^([a-z_][a-z0-9_]*):\s*(.*)", line)
        if m:
            result[m.group(1)] = m.group(2).strip()
    return result


def validate_skill(skill_path):
    """Basic validation of a skill's SKILL.md frontmatter."""
    skill_path = Path(skill_path)

    skill_md = skill_path / "SKILL.md"
    if not skill_md.exists():
        return False, "SKILL.md not found"

    content = skill_md.read_text()
    if not content.startswith("---"):
        return False, "No YAML frontmatter found"

    frontmatter = parse_frontmatter(content)
    if frontmatter is None:
        return False, "Invalid frontmatter format"

    # Our required fields
    REQUIRED_FIELDS = {
        "name", "description", "user_invocable", "interactive",
        "depends_on", "reads", "writes", "checkpoint", "model_tier"
    }

    # Check required fields
    missing = REQUIRED_FIELDS - set(frontmatter.keys())
    if missing:
        return False, f"Missing required field(s): {', '.join(sorted(missing))}"

    # Validate name
    name = frontmatter.get("name", "").strip().strip("'\"")
    if not name:
        return False, "Name is empty"
    if not re.match(r"^[a-z0-9-]+$", name):
        return False, f"Name '{name}' should be kebab-case"
    if name.startswith("-") or name.endswith("-") or "--" in name:
        return False, f"Name '{name}' has invalid hyphen placement"
    if len(name) > 64:
        return False, f"Name too long ({len(name)} chars, max 64)"

    # Check name matches directory
    dir_name = skill_path.name
    if name != dir_name:
        return False, f"Name '{name}' does not match directory '{dir_name}'"

    # Check line count
    lines = content.count("\n") + 1
    if lines > 80:
        return False, f"SKILL.md is {lines} lines (max 80)"

    # Check for hyphenated user-invocable (wrong)
    if re.search(r"^user-invocable:", content, re.MULTILINE):
        return False, "Uses 'user-invocable' (hyphen) — should be 'user_invocable'"

    # Check _source block exists
    if "_source:" not in content:
        return False, "Missing _source block"

    return True, "Valid"


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python quick_validate.py <skill_directory>")
        sys.exit(1)

    valid, message = validate_skill(sys.argv[1])
    print(message)
    sys.exit(0 if valid else 1)
