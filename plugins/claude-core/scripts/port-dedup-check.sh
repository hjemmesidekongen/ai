#!/usr/bin/env bash
set -euo pipefail
# claude-core — Stop hook: warn if skill/command names exist in multiple plugins
# Advisory only — exit 0 always, JSON output.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Find all ecosystem.json files into an array
ECOSYSTEM_FILES=()
while IFS= read -r f; do
  ECOSYSTEM_FILES+=("$f")
done < <(find "$PROJECT_DIR/plugins" -path '*/.claude-plugin/ecosystem.json' 2>/dev/null || true)
[ ${#ECOSYSTEM_FILES[@]} -eq 0 ] && exit 0

# Extract and compare component names across plugins
DUPES=$(python3 -c "
import json, sys, os
from collections import defaultdict

components = defaultdict(list)
for path in sys.argv[1:]:
    try:
        with open(path) as f:
            data = json.load(f)
        plugin = path.split('/plugins/')[1].split('/')[0] if '/plugins/' in path else os.path.basename(os.path.dirname(os.path.dirname(path)))
        for kind in ('skills', 'commands', 'agents'):
            for name in data.get(kind, []):
                components[f'{kind}:{name}'].append(plugin)
    except (json.JSONDecodeError, FileNotFoundError, IndexError):
        continue

dupes = {k: v for k, v in components.items() if len(v) > 1}
if dupes:
    parts = []
    for comp, plugins in dupes.items():
        parts.append(f'{comp} in [{\", \".join(plugins)}]')
    print('; '.join(parts))
" "${ECOSYSTEM_FILES[@]}" 2>/dev/null || true)

if [ -n "$DUPES" ]; then
  DUPES="${DUPES//\"/\'}"
  echo "{\"decision\":\"approve\",\"reason\":\"Duplicate components detected.\",\"systemMessage\":\"Port dedup warning: ${DUPES}. Consider removing duplicates.\"}"
fi

exit 0
