#!/usr/bin/env bash
# smoke-skill.sh <skill-dir> — deterministic checks for a generated skill.
# Exit 0 = pass, 1 = fail. Used by turn-into-skill Phase 6.
set -uo pipefail
DIR="${1:?usage: smoke-skill.sh <skill-dir>}"
PASS=0; FAIL=0
ok(){ echo "ok - $1"; PASS=$((PASS+1)); }
bad(){ echo "FAIL - $1"; FAIL=$((FAIL+1)); }

SKILL="$DIR/SKILL.md"
[[ -f "$SKILL" ]] && ok "SKILL.md exists" || { bad "SKILL.md missing"; echo "pass=$PASS fail=$FAIL"; exit 1; }

# frontmatter
head -n 1 "$SKILL" | grep -q '^---$' && ok "frontmatter opens" || bad "frontmatter"
grep -q '^name: [a-z0-9-]*$' "$SKILL" && ok "name kebab-case" || bad "name format"
grep -q '^description: ' "$SKILL" && ok "description present" || bad "description missing"

# name == dir
DNAME="$(grep '^name:' "$SKILL" | head -1 | awk '{print $2}')"
BNAME="$(basename "$DIR")"
[[ "$DNAME" == "$BNAME" ]] && ok "name==dir ($DNAME)" || bad "name!=dir ($DNAME vs $BNAME)"

# description carries triggers (min length + verb check)
DLEN="$(grep '^description:' "$SKILL" | wc -c)"
[[ "$DLEN" -gt 80 ]] && ok "description trigger-rich ($DLEN chars)" || bad "description too short ($DLEN)"
grep -qi '^description:.*\b\(use\|when\|build\|create\|turn\|handle\|manage\|test\|debug\|write\|review\|deploy\|receive\|verify\|set up\)[ ,]' "$SKILL" \
  && ok "description has trigger verbs" || bad "description lacks trigger verbs"

# version + source (update loop needs them)
grep -qE '^version: [0-9]+$' "$SKILL" && ok "version present" || bad "version missing (add 'version: 1')"
grep -qE '^source: .+' "$SKILL" && ok "source present" || bad "source missing (add 'source: <url|path>')"

# steps have completion bounds
grep -qi 'done when' "$SKILL" && ok "steps have done-when bounds" || bad "no done-when bounds"

# references resolve (skip <placeholder> template refs)
BROKEN=0
while read -r ref; do
  case "$ref" in *[\<\>]* ) continue;; esac
  [[ -f "$DIR/$ref" ]] || { echo "broken ref: $ref"; BROKEN=1; }
done < <(grep -oE '`references/[^`]+`' "$SKILL" | tr -d '`')
[[ "$BROKEN" -eq 0 ]] && ok "references resolve" || bad "broken references"

# no secrets (exclude this script: its own patterns self-match on .*)
if grep -rEn --exclude=smoke-skill.sh 'sk_(live|test)_[A-Za-z0-9]+|rk_(live|test)_[A-Za-z0-9]+|whsec_[A-Za-z0-9]{8,}|xox[bpas]-|ghp_[A-Za-z0-9]+|-----BEGIN .*PRIVATE KEY-----' "$DIR"; then
  bad "possible secret leak"
else
  ok "no secrets"
fi

echo "---"
echo "pass=$PASS fail=$FAIL"
[[ "$FAIL" -eq 0 ]]
