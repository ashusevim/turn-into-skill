#!/usr/bin/env bash
# local-search.sh <keyword> [keyword...] — Layer 0 dedup: grep installed skills.
# Searches global (~/.agents/skills, ~/.config/opencode/skills) and project (.agents/skills, skills/).
# Prints "name | dir | description" per hit. Exit 0 always (no hits = empty output).
set -uo pipefail
DIRS=("$HOME/.agents/skills" "$HOME/.config/opencode/skills" "./.agents/skills" "./skills")
seen=""
for d in "${DIRS[@]}"; do
  [[ -d "$d" ]] || continue
  while IFS= read -r f; do
    for kw in "$@"; do
      if grep -qi "$kw" "$f"; then
        name="$(grep '^name:' "$f" | head -1)"
        [[ "$seen" == *"$f"* ]] || { echo "$name | $f"; seen="$seen $f"; }
        break
      fi
    done
  done < <(find "$d" -maxdepth 2 -name SKILL.md 2>/dev/null)
done
