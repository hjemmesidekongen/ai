#!/usr/bin/env bash
#
# check-file-conflicts.sh
#
# Validates that no two parallel tasks in the same wave claim
# overlapping files_written paths. Reads a plan YAML file and
# checks each wave for conflicts.
#
# Usage: ./check-file-conflicts.sh <plan-file.yml>
# Exit 0: No conflicts found
# Exit 1: Conflicts found (details printed to stderr)
# Exit 2: Usage error or missing dependencies

set -euo pipefail

# --- Dependencies ---

check_dependencies() {
  local missing=()
  for cmd in yq; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "ERROR: Missing required commands: ${missing[*]}" >&2
    echo "Install yq: brew install yq (macOS) or snap install yq (Linux)" >&2
    exit 2
  fi
}

# --- Usage ---

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <plan-file.yml>" >&2
  exit 2
fi

PLAN_FILE="$1"

if [[ ! -f "$PLAN_FILE" ]]; then
  echo "ERROR: Plan file not found: $PLAN_FILE" >&2
  exit 2
fi

check_dependencies

# --- Path comparison functions ---

# Split "file.yml#section" into file and section parts.
split_path() {
  local path="$1"
  local file="${path%%#*}"
  local section=""
  if [[ "$path" == *"#"* ]]; then
    section="${path#*#}"
  fi
  echo "$file" "$section"
}

# Normalize a path by removing trailing slashes and wildcards for
# directory comparison.
normalize_dir() {
  local path="$1"
  # Remove trailing glob patterns for directory comparison
  path="${path%%/\*\*}"
  path="${path%%/\*}"
  path="${path%%\*}"
  # Remove trailing slash
  path="${path%/}"
  echo "$path"
}

# Check if two paths overlap.
# Returns 0 (true) if they overlap, 1 (false) if they don't.
paths_overlap() {
  local path_a="$1"
  local path_b="$2"

  local file_a section_a file_b section_b
  read -r file_a section_a <<< "$(split_path "$path_a")"
  read -r file_b section_b <<< "$(split_path "$path_b")"

  # Step 1: Do the base files/globs match?
  if ! files_match "$file_a" "$file_b"; then
    return 1
  fi

  # Step 2: Both have sections — compare them
  if [[ -n "$section_a" && -n "$section_b" ]]; then
    if [[ "$section_a" == "$section_b" ]]; then
      return 0
    else
      return 1
    fi
  fi

  # Step 3: At least one has no section (whole-file claim) — overlap
  return 0
}

# Check if two file paths or globs refer to overlapping locations.
# Returns 0 (true) if they match, 1 (false) if they don't.
files_match() {
  local a="$1"
  local b="$2"

  # Exact match
  if [[ "$a" == "$b" ]]; then
    return 0
  fi

  # Check if one is a parent directory glob of the other
  local dir_a dir_b
  dir_a="$(normalize_dir "$a")"
  dir_b="$(normalize_dir "$b")"

  # a contains b: "assets" contains "assets/icons"
  if [[ "$dir_b" == "$dir_a"/* || "$dir_b" == "$dir_a" ]]; then
    return 0
  fi

  # b contains a: "assets/icons" is under "assets"
  if [[ "$dir_a" == "$dir_b"/* || "$dir_a" == "$dir_b" ]]; then
    return 0
  fi

  return 1
}

# --- Main conflict detection ---

conflict_count=0

# Get the number of waves
num_waves=$(yq '.plan.waves | length' "$PLAN_FILE")

for ((w = 0; w < num_waves; w++)); do
  wave_num=$(yq ".plan.waves[$w].wave" "$PLAN_FILE")
  is_parallel=$(yq ".plan.waves[$w].parallel" "$PLAN_FILE")

  # Only check parallel waves — sequential waves have no concurrency
  if [[ "$is_parallel" != "true" ]]; then
    continue
  fi

  # Get task ids in this wave
  num_tasks=$(yq ".plan.waves[$w].tasks | length" "$PLAN_FILE")

  if [[ "$num_tasks" -lt 2 ]]; then
    continue
  fi

  # Collect files_written per task
  declare -A task_files=()
  task_ids=()

  for ((t = 0; t < num_tasks; t++)); do
    task_id=$(yq ".plan.waves[$w].tasks[$t]" "$PLAN_FILE")
    task_ids+=("$task_id")

    # Find this task in the tasks array and get its files_written
    files=$(yq ".plan.tasks[] | select(.id == \"$task_id\") | .files_written[]" "$PLAN_FILE" 2>/dev/null || true)
    task_files["$task_id"]="$files"
  done

  # Pairwise comparison within the wave
  for ((i = 0; i < ${#task_ids[@]}; i++)); do
    for ((j = i + 1; j < ${#task_ids[@]}; j++)); do
      id_a="${task_ids[$i]}"
      id_b="${task_ids[$j]}"

      # Compare each path from task A against each path from task B
      while IFS= read -r path_a; do
        [[ -z "$path_a" ]] && continue
        while IFS= read -r path_b; do
          [[ -z "$path_b" ]] && continue

          if paths_overlap "$path_a" "$path_b"; then
            echo "CONFLICT in wave $wave_num: task $id_a ($path_a) overlaps with task $id_b ($path_b)" >&2
            ((conflict_count++))
          fi
        done <<< "${task_files[$id_b]}"
      done <<< "${task_files[$id_a]}"
    done
  done

  unset task_files
done

# --- Report ---

if [[ $conflict_count -gt 0 ]]; then
  echo "" >&2
  echo "FAILED: $conflict_count file ownership conflict(s) found." >&2
  echo "Run the file-ownership skill to resolve conflicts before execution." >&2
  exit 1
fi

echo "OK: No file ownership conflicts found across $num_waves waves."
exit 0
