# turn-into-skill

One command that turns anything into an agent skill:

```
/turn-into-skill <url | file-path | dir-path | pasted text>
```

It checks whether the skill already exists (local + skills.sh). If yes, it points you to the install and stops. If no, it builds one and tests it before handing it over.

Handles: docs pages, GitHub repos, YouTube videos, PDFs, OpenAPI specs, Notion pages, npm packages, local files, pasted text.

## Install

OpenCode slash command:

```bash
cp commands/turn-into-skill.md ~/.config/opencode/commands/turn-into-skill.md
```

Any agent (pick yours after `-a` — plain `-g` installs everywhere including PromptScript, which fails):

```bash
npx -y skills add ashusevim/turn-into-skill -g -a opencode -y
```

## How it works

1. Classifies the input (url-docs, repo, video, pdf, openapi, notion, package, file, dir, text).
2. Dedups: installed skills first, then `npx skills find` with paraphrases, scoped searches, and a staleness check. Exact + fresh match = stop and suggest the install.
3. Ingests the source (capped, workflow only — no trivia).
4. Distills to 5–9 steps, each ending in a checkable done condition.
5. Scaffolds `SKILL.md` with `version:` + `source:` frontmatter.
6. Self-tests: `scripts/smoke-skill.sh` must exit 0, then one task from the source material run against the skill. Two fix attempts max.

Flags: `--force` skips dedup. `--dry-run` stops after the verdict. `--update <skill-dir>` re-ingests the source, patches gaps, bumps the version.

## Repo layout

```
skills/turn-into-skill/SKILL.md              the skill itself
skills/turn-into-skill/scripts/smoke-skill.sh     quality gate (frontmatter, triggers, refs, secrets)
skills/turn-into-skill/scripts/local-search.sh    dedup against installed skills
skills/turn-into-skill/scripts/clean-transcript.py  YouTube caption cleanup
commands/turn-into-skill.md                  OpenCode slash-command wrapper
examples/                                    demo outputs (not installed)
test.sh                                      full check suite
```

## Test

```bash
./test.sh
```

28 checks: skill shape, dedup/dry-run/update phases, ingestors, smoke-on-demos, scaffold round-trip.

## Skills built with it

See [agent-skills](../agent-skills): gmail-api, tailwind-utilities, postgres-psql, github-actions — plus stripe-webhooks and mental-math in `examples/`.
