#!/usr/bin/env bash
# drift-check.sh [skill-dir...] — skill CI gate.
# Per skill: smoke test + source-drift detection (URL sources hashed, compared).
# Exit 0 = all green. Non-zero names failures. First run baselines hashes.
set -uo pipefail
DIR0="$(cd "$(dirname "$0")" && pwd)"
ROOT="$DIR0"
for _ in 1 2 3 4; do
  [[ -d "$ROOT/.git" ]] && break
  ROOT="$(dirname "$ROOT")"
done
cd "$ROOT"
HASHDIR=".skill-ci/hashes"
mkdir -p "$HASHDIR"
PASS=0; FAIL=0
ok(){ echo "ok - $1"; PASS=$((PASS+1)); }
bad(){ echo "FAIL - $1"; FAIL=$((FAIL+1)); }

SMOKE=""
for c in "skills/turn-into-skill/scripts/smoke-skill.sh" "scripts/smoke-skill.sh"; do
  [[ -x "$c" ]] && SMOKE="$c" && break
done

DIRS=()
if [[ $# -gt 0 ]]; then DIRS=("$@");
else
  while IFS= read -r f; do DIRS+=("$(dirname "$f")"); done < <(
    find . -maxdepth 3 -name SKILL.md -not -path "./examples/*" -not -path "./.agents/*" -not -path "*/node_modules/*" 2>/dev/null)
fi
[[ ${#DIRS[@]} -gt 0 ]] || { echo "no skills found"; exit 1; }

for d in "${DIRS[@]}"; do
  name="$(basename "$d")"
  if [[ -n "$SMOKE" ]]; then
    bash "$SMOKE" "$d" >/dev/null 2>&1 && ok "$name smoke" || { bad "$name smoke"; continue; }
  fi
  src="$(grep -E '^source: ' "$d/SKILL.md" | head -1 | sed 's/^source: //')"
  [[ -n "$src" ]] || { bad "$name has no source:"; continue; }
  if [[ "$src" =~ ^https?:// ]]; then
    body="$(curl -sL --max-time 60 "$src" 2>/dev/null)"
    [[ -n "$body" ]] || { bad "$name source unreachable: $src"; continue; }
    sum="$(printf '%s' "$body" | sha256sum | cut -d' ' -f1)"
    hashfile="$HASHDIR/$name.sha"
    if [[ ! -f "$hashfile" ]]; then
      printf '%s  %s\n' "$sum" "$src" > "$hashfile"
      ok "$name source baselined"
    elif grep -q "^$sum " "$hashfile"; then
      ok "$name source unchanged"
    else
      bad "$name SOURCE CHANGED since baseline — run --update on $d (source: $src)"
    fi
  else
    ok "$name source is local ($src), smoke only"
  fi
done
echo "---"
echo "pass=$PASS fail=$FAIL"
[[ "$FAIL" -eq 0 ]]
