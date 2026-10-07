#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
SKILL="$ROOT/skills/turn-into-skill/SKILL.md"
CMD="$ROOT/commands/turn-into-skill.md"
SMOKE="$ROOT/skills/turn-into-skill/scripts/smoke-skill.sh"
PASS=0; FAIL=0
ok(){ echo "ok - $1"; PASS=$((PASS+1)); }
bad(){ echo "FAIL - $1"; FAIL=$((FAIL+1)); }

[[ -f "$SKILL" ]] && ok "SKILL.md exists" || bad "SKILL.md missing"
[[ -f "$CMD" ]] && ok "command exists" || bad "command missing"
[[ -x "$SMOKE" ]] && ok "smoke script executable" || bad "smoke script missing/not executable"

head -n 1 "$SKILL" | grep -q '^---$' && ok "SKILL frontmatter opens" || bad "SKILL frontmatter"
grep -q '^name: turn-into-skill$' "$SKILL" && ok "skill name matches" || bad "skill name"
grep -q '^name: turn-into-skill$' "$CMD" && ok "command name matches" || bad "command name"

# improvement 2: 4-layer dedup (local + registry + aggregators + staleness)
grep -q 'local-search.sh' "$SKILL" && ok "dedup Layer 0 local present" || bad "dedup Layer 0"
grep -q -- '--owner vercel-labs' "$SKILL" && ok "dedup aggregators present" || bad "dedup aggregators"
grep -qi 'stale' "$SKILL" && ok "staleness check present" || bad "staleness missing"
grep -qi 'overlap rubric' "$SKILL" && ok "overlap rubric present" || bad "overlap rubric missing"
grep -qi 'paraphrase' "$SKILL" && ok "paraphrase queries present" || bad "paraphrases missing"
grep -q 'dry-run' "$SKILL" && ok "dry-run supported" || bad "dry-run missing"
grep -q '\-\-force' "$SKILL" && ok "force flag supported" || bad "force missing"
grep -q '\-\-update' "$SKILL" && ok "update flow present" || bad "update flow missing"
[[ -x "$ROOT/skills/turn-into-skill/scripts/local-search.sh" ]] && ok "local-search executable" || bad "local-search missing"
[[ -f "$ROOT/.github/workflows/skill-ci.yml" ]] && ok "CI workflow present" || bad "CI workflow missing"
[[ -x "$ROOT/skills/turn-into-skill/scripts/drift-check.sh" ]] && ok "drift-check executable" || bad "drift-check missing"
bash "$ROOT/skills/turn-into-skill/scripts/drift-check.sh" >/dev/null 2>&1 \
  && ok "drift-check green on this repo" || bad "drift-check red on this repo"
[[ -f "$ROOT/skills/turn-into-skill/scripts/clean-transcript.py" ]] && ok "clean-transcript present" || bad "clean-transcript missing"
# local-search actually finds installed demo skills (Layer 0 proof)
HITS="$(bash "$ROOT/skills/turn-into-skill/scripts/local-search.sh" "mental math" | grep -c 'mental-math')"
[[ "$HITS" -gt 0 ]] && ok "local-search finds installed skill" || bad "local-search finds nothing"

# improvement 3: new ingestors
for t in 'youtube' 'pdf' 'openapi' 'notion'; do
  grep -qi "$t" "$SKILL" && ok "ingestor: $t" || bad "ingestor missing: $t"
done

# improvement 1: self-test loop + trigger test
grep -q 'smoke-skill.sh' "$SKILL" && ok "self-test phase present" || bad "self-test missing"
grep -qi 'live trial' "$SKILL" && ok "live trial present" || bad "live trial missing"
grep -qi 'trigger test' "$SKILL" && ok "trigger test present" || bad "trigger test missing"
grep -q 'no-triggers' "$SKILL" && ok "no-triggers flag present" || bad "no-triggers missing"

# improvement 4: publish path
grep -q 'skills add' README.md && ok "publish install line in README" || bad "README install line"
grep -q 'skills.sh' README.md && ok "skills.sh listing step in README" || bad "README skills.sh"

# dogfood: smoke script passes on demo skill built earlier
if bash "$SMOKE" "$ROOT/examples/stripe-webhooks"; then
  ok "smoke passes on demo stripe-webhooks"
else
  bad "smoke fails on demo stripe-webhooks"
fi

# smoke script passes on itself
if bash "$SMOKE" "$ROOT/skills/turn-into-skill"; then
  ok "smoke passes on turn-into-skill"
else
  bad "smoke fails on turn-into-skill"
fi

# scaffold still works
SMOKEDIR="/tmp/opencode/skill-smoke"
rm -rf "$SMOKEDIR"; mkdir -p "$SMOKEDIR"; cd "$SMOKEDIR"
npx -y skills init smoke-test-skill --yes >/dev/null 2>&1 && ok "scaffold works" || bad "scaffold failed"

echo "---"
echo "pass=$PASS fail=$FAIL"
[[ "$FAIL" -eq 0 ]] && echo DONE || echo DONE_WITH_CONCERNS
exit "$FAIL"
