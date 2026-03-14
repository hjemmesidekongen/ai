#!/usr/bin/env bash
# kronen — SessionStart hook: sync plugin operating rules and profile config
# Reads .ai/project.yml → resolves profile → applies overrides → compiles cache → generates .claude/rules/kronen.md
# When project.yml absent: defaults all hooks to enabled (secure default).
# Uses content hashing to avoid unnecessary writes. Always exits 0.
set -euo pipefail
umask 077

# --- Environment ---
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
TEMPLATE="$PLUGIN_ROOT/resources/operating-rules.md"
PROFILES_DIR="$PLUGIN_ROOT/resources/profiles"
CONFIG="$PROJECT_DIR/.ai/project.yml"
RULES_DIR="$PROJECT_DIR/.claude/rules"
RULES_FILE="$RULES_DIR/kronen.md"
META_FILE="$RULES_DIR/.kronen-sync-meta"
CACHE_DIR="$PROJECT_DIR/.ai/context"
CACHE_FILE="$CACHE_DIR/kronen-profile-cache"

# Read hook input from stdin (required by hook protocol)
cat > /dev/null 2>&1 || true

# --- Safety: non-overridable flags ---
readonly SAFETY_FLAGS=("scope_guard" "push_protection")

# --- Helpers ---
warn() { echo "=== Kronen Rules Sync Warning ===" >&2; echo "$1" >&2; echo "=== End Warning ===" >&2; }

is_safety_flag() {
  local key="$1"
  for sf in "${SAFETY_FLAGS[@]}"; do
    [[ "$key" == "$sf" ]] && return 0
  done
  return 1
}

# Atomic write: temp file in same directory, then mv
atomic_write() {
  local target="$1" content="$2" dir
  dir=$(dirname "$target")

  # Symlink checks on parent directory
  if [ -L "$dir" ]; then
    warn "Parent directory $dir is a symlink — skipping write to $target"
    return 1
  fi

  mkdir -p "$dir"
  local tmpfile
  tmpfile=$(mktemp "$dir/.kronen-sync-XXXXXX") || return 1
  printf '%s\n' "$content" > "$tmpfile"
  mv "$tmpfile" "$target"

  # Post-mv verification: must be regular file, not symlink
  if [ -L "$target" ]; then
    rm -f "$target" 2>/dev/null
    warn "Target $target became a symlink after write — removed"
    return 1
  fi

  chmod 600 "$target"
}

# Extract a simple YAML value (flat key: value only, no nested)
yaml_val() {
  local file="$1" key="$2"
  local line
  line=$(grep "^${key}:" "$file" 2>/dev/null | head -1) || true
  if [ -n "$line" ]; then
    echo "$line" | sed "s/^${key}:[[:space:]]*//" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/"
  fi
}

# Extract nested YAML value (parent.child — one level deep)
yaml_nested_val() {
  local file="$1" parent="$2" child="$3"
  # Find lines under parent: section, extract child value
  awk -v p="$parent:" -v c="$child:" '
    $0 ~ "^"p { inside=1; next }
    inside && /^[^ ]/ { inside=0 }
    inside && $0 ~ "^  "c { sub(/^  [^:]+:[[:space:]]*/, ""); gsub(/^["'\'']|["'\'']$/, ""); print; exit }
  ' "$file" 2>/dev/null
}

# Validate dev command against safe pattern
validate_command() {
  local cmd="$1"
  if [[ -n "$cmd" ]] && ! [[ "$cmd" =~ ^[a-zA-Z0-9_./\ -]+$ ]]; then
    warn "Dev command rejected (unsafe characters): $cmd"
    echo ""
    return
  fi
  echo "$cmd"
}

# --- Profile resolution ---
resolve_profile() {
  local profile_name="$1"

  # Sanitize profile name: alphanumeric, dash, underscore only
  profile_name=$(echo "$profile_name" | tr -cd 'a-zA-Z0-9_-')
  if [ -z "$profile_name" ]; then
    warn "Empty profile name after sanitization — using defaults"
    return 1
  fi

  local profile_file="$PROFILES_DIR/${profile_name}.yml"

  # Path traversal check: after sanitization (alphanumeric/dash/underscore only),
  # the name cannot contain slashes or dots, so traversal is structurally impossible.
  # Belt-and-suspenders: verify the file is inside the profiles directory.
  local resolved profiles_real
  resolved=$(cd "$PROFILES_DIR" 2>/dev/null && pwd -P)/"${profile_name}.yml"
  profiles_real=$(cd "$PROFILES_DIR" 2>/dev/null && pwd -P)

  case "$resolved" in
    "$profiles_real"/*) ;; # path is within profiles dir — safe
    *)
      warn "Profile name '$profile_name' resolves outside profiles directory — using defaults"
      return 1
      ;;
  esac

  if [ ! -f "$profile_file" ]; then
    warn "Profile '$profile_name' not found at $profile_file — using defaults"
    return 1
  fi

  echo "$profile_file"
}

# --- Default flags (secure default: everything enabled) ---
KRONEN_TDD_GATE="enabled"
KRONEN_TRACING="light"
KRONEN_DOC_CHECKPOINT="enabled"
KRONEN_VERIFICATION="strict"
KRONEN_SCOPE_GUARD="enabled"
KRONEN_PUSH_PROTECTION="enabled"

# --- Read project config ---
if [ -f "$CONFIG" ]; then
  PROFILE_NAME=$(yaml_val "$CONFIG" "profile")

  # Load profile preset
  if [ -n "$PROFILE_NAME" ]; then
    PROFILE_FILE=$(resolve_profile "$PROFILE_NAME") || true
    if [ -n "${PROFILE_FILE:-}" ] && [ -f "$PROFILE_FILE" ]; then
      KRONEN_TDD_GATE=$(yaml_val "$PROFILE_FILE" "tdd_gate" || echo "enabled")
      KRONEN_TRACING=$(yaml_val "$PROFILE_FILE" "tracing" || echo "light")
      KRONEN_DOC_CHECKPOINT=$(yaml_val "$PROFILE_FILE" "doc_checkpoint" || echo "enabled")
      KRONEN_VERIFICATION=$(yaml_val "$PROFILE_FILE" "verification" || echo "strict")
    fi
  fi

  # Apply overrides (with safety flag skip)
  for key in tdd_gate tracing doc_checkpoint verification scope_guard push_protection; do
    override_val=$(awk -v k="    $key:" '
      /^overrides:/ { in_o=1; next }
      in_o && /^[^ ]/ { in_o=0 }
      in_o && /^  hooks:/ { in_h=1; next }
      in_h && /^  [^ ]/ && !/^    / { in_h=0 }
      in_h && index($0, k)==1 { sub(/^    [^:]+:[[:space:]]*/, ""); gsub(/["'"'"']/, ""); print; exit }
    ' "$CONFIG" 2>/dev/null || true)

    if [ -n "$override_val" ]; then
      # Safety flag check: skip with warning
      if is_safety_flag "$key"; then
        if [ "$override_val" != "enabled" ]; then
          warn "Cannot override safety flag '$key' — forced to enabled"
        fi
        continue
      fi

      # Apply the override
      local_var="KRONEN_$(echo "$key" | tr '[:lower:]' '[:upper:]')"
      eval "$local_var=\"$override_val\""
    fi
  done

  # Validate dev commands (nested under dev: section)
  DEV_TEST=$(validate_command "$(yaml_nested_val "$CONFIG" "dev" "test" 2>/dev/null || true)") || DEV_TEST=""
  DEV_BUILD=$(validate_command "$(yaml_nested_val "$CONFIG" "dev" "build" 2>/dev/null || true)") || DEV_BUILD=""
  DEV_LINT=$(validate_command "$(yaml_nested_val "$CONFIG" "dev" "lint" 2>/dev/null || true)") || DEV_LINT=""
else
  DEV_TEST=""
  DEV_BUILD=""
  DEV_LINT=""
fi

# Force safety flags (defense in depth — even if skip failed somehow)
KRONEN_SCOPE_GUARD="enabled"
KRONEN_PUSH_PROTECTION="enabled"

# --- Compile profile cache ---
CACHE_CONTENT="# kronen-profile-cache (auto-generated by rules-sync.sh — do not edit)
KRONEN_TDD_GATE=$KRONEN_TDD_GATE
KRONEN_TRACING=$KRONEN_TRACING
KRONEN_DOC_CHECKPOINT=$KRONEN_DOC_CHECKPOINT
KRONEN_VERIFICATION=$KRONEN_VERIFICATION
KRONEN_SCOPE_GUARD=$KRONEN_SCOPE_GUARD
KRONEN_PUSH_PROTECTION=$KRONEN_PUSH_PROTECTION
KRONEN_DEV_TEST=$DEV_TEST
KRONEN_DEV_BUILD=$DEV_BUILD
KRONEN_DEV_LINT=$DEV_LINT"

# --- Generate rules file ---
if [ ! -f "$TEMPLATE" ]; then
  warn "Operating rules template not found at $TEMPLATE — skipping rules sync"
  exit 0
fi

RULES_CONTENT="<!-- Generated by kronen. Do not edit manually. Changes will be overwritten by rules-sync.sh -->
$(cat "$TEMPLATE")"

# --- Content hash comparison ---
NEW_HASH=$(printf '%s\n%s' "$RULES_CONTENT" "$CACHE_CONTENT" | shasum -a 256 | cut -d' ' -f1)

if [ -f "$META_FILE" ]; then
  # Strict regex: hash must be exactly 64 hex chars
  OLD_HASH=$(head -1 "$META_FILE" 2>/dev/null | grep -E '^[a-f0-9]{64}$' || echo "")
  if [ "$NEW_HASH" = "$OLD_HASH" ]; then
    # Content unchanged — fast path exit
    exit 0
  fi
fi

# --- Write files ---

# Symlink check on rules target
if [ -L "$RULES_FILE" ]; then
  warn "Rules file $RULES_FILE is a symlink — skipping sync"
  exit 0
fi

atomic_write "$RULES_FILE" "$RULES_CONTENT" || {
  warn "Failed to write rules file"
  exit 0
}

atomic_write "$CACHE_FILE" "$CACHE_CONTENT" || {
  warn "Failed to write cache file"
  exit 0
}

# Write meta (hash for next comparison)
atomic_write "$META_FILE" "$NEW_HASH" || true

echo "Kronen rules synced (profile: ${PROFILE_NAME:-default})"
exit 0
