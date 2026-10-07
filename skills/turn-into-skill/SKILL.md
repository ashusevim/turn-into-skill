---
name: turn-into-skill
description: Turn anything into a reusable agent skill. Use when user says turn into skill, make this a skill, convert docs/repo/URL/text/video/PDF/OpenAPI/notes into a skill, or invokes /turn-into-skill. Checks existing skills first, scaffolds SKILL.md only on miss, self-tests before shipping.
---

# Turn Into Skill

Take any input — URL, repo, docs, video, PDF, OpenAPI spec, file, directory, pasted text — and turn it into a portable agent skill. Dedup first. Build only on miss. Self-test before shipping.

Usage: `/turn-into-skill <url | file-path | dir-path | pasted-text> [--force] [--dry-run]`

## Phase 0 — Classify input

Identify the input type. Do not fetch yet.

| Input looks like | Type | Ingest in Phase 2 |
|---|---|---|
| `http(s)://…` docs, blog, README page | url-docs | webfetch + same-origin links 1 level, max 5 pages |
| `github.com/owner/repo` or git URL | repo | shallow clone to `/tmp/opencode/`, README + layout + top files |
| `youtube.com/`, `youtu.be/`, video page | video | transcript first, chapters second, opinions last |
| `.pdf` URL or local path | pdf | `pdftotext` / read,TOC + relevant sections only, cap ~8k words |
| `openapi.{json,yaml}`, `/openapi.json`, Swagger URL | openapi | endpoints table → auth → 3 core flows; skip schemas verbatim |
| `notion.so/…`, Notion export | notion | webfetch page or read export md, follow sub-pages 1 level |
| `npm:pkg`, bare package name | package | context7 `resolve-library-id` + `query-docs`, one concept per query |
| existing file path | file | read directly |
| existing directory path | dir | glob layout, rank by name, read max 10 files |
| anything else, pasted block | text | use as-is; if under 200 words ask one round for source URL or example |

Derive a working skill name now: kebab-case, verb-noun, max 3 words (e.g. `stripe-webhooks`, `pdf-extract`). Rename later if ingest proves it wrong.

Completion: input type named, working name chosen.

## Phase 1 — Dedup (mandatory, skipped only by `--force`)

Never build what already exists. Check three layers, cheapest first.

1. Derive 3–5 keyword queries (domain + task, e.g. `stripe webhooks`, not `stripe`).
2. Layer A — registry: run for each query:
   ```bash
   npx -y skills find "<query>" 2>&1 | head -n 30
   ```
3. Layer B — aggregators: scope one search each to the big collections:
   ```bash
   npx -y skills find "<query>" --owner vercel-labs 2>&1 | head -n 10
   npx -y skills find "<query>" --owner anthropics 2>&1 | head -n 10
   ```
   plus webfetch `https://skills.sh/` topic/leaderboard for the domain.
4. Layer C — staleness: for the top 1–2 hits, open the skills.sh page. Note installs, repo stars, and last-update signal. A hit is **fresh** if actively maintained and covering the task; **stale** if installs are low (<500), repo quiet >6 months, or missing the core of the input.

Score: exact-task + fresh = reuse. Exact-task + stale = offer update (rebuild scoped as `--update`, credit original). Adjacent-task = mention. No match = miss.

Completion: 2+ distinct queries run, hits scored fresh/stale/miss.

On exact + fresh, STOP. Reply with name, installs, `npx skills add <owner/repo@skill> -g -a <agent> -y` (scope `-a` — bare `-g` fans out to PromptScript and fails), and link. Offer to install. Do not scaffold.

On miss, adjacent-only, or exact-but-stale (user confirms rebuild): state `No usable skill for "<query>" — building "<working-name>".` Then continue. `--dry-run` stops here after reporting the verdict.

## Phase 2 — Ingest

Fetch the minimum that captures the repeatable workflow. Facts rot; workflows persist.

- url-docs / notion: `webfetch` the page, follow same-origin links 1 level, max 5 pages.
- repo: `git clone --depth 1 <url> /tmp/opencode/<name>`, glob layout, README, examples/, top source files.
- video: transcript + chapters. Skip sponsor reads and tangents.
- pdf: extract text, read TOC, pull only sections matching the task.
- openapi: build endpoint table (method + path + auth), then 3 core flows end to end. Never paste full schemas into the skill — summarize shapes.
- package: context7, one concept per query.
- file/dir/text: read directly. Dirs over 30 files: rank by name, read max 10.

Strip ads, nav, changelogs, version trivia, secrets. Keep steps the author repeats, failure modes, commands that worked.

Completion: source in context, under ~8k words. Larger → summarize to workflow + 3 examples first.

## Phase 3 — Distill

Convert material into steps + reference. One meaning, one place.

1. List repeatable steps in order (5–9 max). Each ends with a checkable bound: "done when X exists / passes".
2. Push branch-only material behind pointers: `references/<topic>.md`, one line each in SKILL.md.
3. Name one leading word if a concept repeats 3+ times. Prefer a pretrained word over coining one.
4. Delete no-ops: sentences the model obeys by default. Delete whole sentences.
5. State the positive. No prohibitions unless a guardrail can't be phrased positively — then pair ban + target.

Completion: steps ordered with bounds, reference split decided, zero duplicated meanings.

## Phase 4 — Scaffold

```bash
npx -y skills init <working-name> --yes
```

Write `<working-name>/SKILL.md`:

```md
---
name: <working-name>
description: <does-what + 3-5 trigger phrases starting with verbs>
---

# <Title>

<2-sentence outcome.>

## When to use

- <branch 1>
- <branch 2>

## Instructions

1. <Step + done-when bound>
2. ...

## References

- `references/<topic>.md` — <when to load it>
```

Rules: `name` = dir name, kebab-case. `description` carries trigger branches. No `disable-model-invocation` unless user wants hand-invoke only. Large reference (>60 lines), scripts, templates go beside SKILL.md in `references/`, `scripts/`, `assets/`. Scripts only for deterministic work — never judgment.

Completion: SKILL.md exists, frontmatter parses, name matches directory.

## Phase 5 — Self-test (mandatory, max 2 fix iterations)

Never ship an untested skill.

1. Run the deterministic gate:
   ```bash
   bash <turn-into-skill-dir>/skills/turn-into-skill/scripts/smoke-skill.sh ./<working-name>
   ```
   Fix all FAILs: frontmatter, name==dir, trigger-rich description, done-when bounds, resolving references, no secrets.
2. Live trial: install to the current project (`npx -y skills add ./<name> -p -y`), load the skill, run it on one sample task drawn from the source material. Pass = correct outcome following its own steps. On failure, fix the skill (not the task), re-run smoke, retry once.
3. After 2 failed iterations: report DONE_WITH_CONCERNS naming the gap instead of silently shipping.

Completion: smoke script exits 0, one live trial passes.

## Phase 6 — Verify + hand over

- [ ] Dedup verdict recorded (reused / miss / rebuilt-stale)
- [ ] smoke-skill.sh exits 0
- [ ] live trial passes
- [ ] no secrets, tokens, personal data
- [ ] report DONE with: path, install command (`npx skills add <path-or-url> -g -a <agent> -y`), one-line trigger, what was deduped

Ship the skill + install line, not a plan.
