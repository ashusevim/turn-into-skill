# turn-into-skill

`/turn-into-skill <anything>` — checks if a skill already exists, installs it if so. Builds + self-tests one if not.

## Install (30s)

**OpenCode (slash command):**
```bash
cp commands/turn-into-skill.md ~/.config/opencode/commands/turn-into-skill.md
```

**Any agent (Claude Code, Cursor, OpenCode…):**
```bash
npx -y skills add ./skills/turn-into-skill -g -a <agent> -y
# e.g. -a opencode | -a claude-code | -a cursor
# NOTE: bare -g fans out to all agents incl. PromptScript and fails. Always scope -a.
```

Verify:
```bash
head -n 4 skills/turn-into-skill/SKILL.md
./test.sh
```

## Use

```
/turn-into-skill https://docs.stripe.com/webhooks
/turn-into-skill https://youtu.be/<id>
/turn-into-skill ./api/openapi.yaml
/turn-into-skill ./notes/anything.md --dry-run
/turn-into-skill <paste raw text> --force
```

Behavior: classify → 3-layer dedup (registry + aggregators + staleness) → ingest → distill → scaffold → smoke-test + live trial → handover.

## Layout

```
skills/turn-into-skill/SKILL.md            # portable skill
skills/turn-into-skill/scripts/smoke-skill.sh  # deterministic gate (Phase 5)
commands/turn-into-skill.md                # OpenCode slash command wrapper
stripe-webhooks/                           # demo output, built with v1
```

## Test

```bash
./test.sh
```

Checks frontmatter, name==dir, dedup/ingest/self-test phases present, smoke script passes on the demo skill, scaffold still works.

## Publish

```bash
# 1. push (needs a GitHub repo — create once)
git init 2>/dev/null; git add -A; git commit -m "turn-into-skill"
gh repo create turn-into-skill --public --source=. --push
# without gh: create repo on github.com, then
# git remote add origin git@github.com:<owner>/turn-into-skill.git && git push -u origin main

# 2. install from GitHub anywhere
npx -y skills add <owner>/turn-into-skill -g -a <agent> -y

# 3. list on skills.sh (auto-indexed from GitHub once public)
# verify at https://skills.sh/<owner>/turn-into-skill/turn-into-skill
```
