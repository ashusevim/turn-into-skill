---
name: turn-into-skill
version: 4
source: https://github.com/vercel-labs/skills
description: Turn anything into a reusable agent skill. Use when user says turn into skill, make this a skill, convert docs/repo/URL/text/video/PDF/OpenAPI/notes into a skill, or invokes /turn-into-skill. Checks existing skills first, scaffolds SKILL.md only on miss, self-tests before shipping.
---

# Turn Into Skill

Take any input — URL, repo, docs, video, PDF, OpenAPI spec, file, directory, pasted text — and turn it into a portable agent skill. Dedup first. Build only on miss. Self-test before shipping.

Usage: `/turn-into-skill <url | file-path | dir-path | pasted-text> [--force] [--dry-run] [--update <skill-dir>] [--no-triggers]`

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

Never build what already exists. Check four layers, cheapest first.

0. Layer 0 — local: are they already holding it?
   ```bash
   bash <turn-into-skill-dir>/skills/turn-into-skill/scripts/local-search.sh <keyword1> <keyword2>
   ```
   Searches installed skills (global + project). A local hit for the exact task = reuse, no build.
1. Derive 3–5 keyword queries (domain + task) plus 1–2 paraphrases (`mental math` → also `vedic maths`, `fast arithmetic`). Keyword search misses reworded equivalents; paraphrases catch them.
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

Overlap rubric — score each candidate, don't eyeball it. The input's task verbs (from Phase 0 classification + source title) vs the candidate's `description` + When-to-use branches:
- 3+ shared task verbs on the same object (e.g. input `verify stripe signatures`, candidate `verifying Stripe-Signature headers`) = exact.
- Same domain, different object (both `stripe`, one `checkout` one `webhooks`) = adjacent.
- Shared domain word only, or shared generic verbs (`build`, `manage`) with no shared object = miss.
Paraphrases count: `mental math` ≡ `vedic maths` ≡ `fast arithmetic` (same object: head-calculation tricks). `math olympiad` ≢ `mental math` (proofs vs calculation) = adjacent at best.

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
version: 1
source: <url | path | brief origin note>
description: <does-what + 3-5 trigger phrases starting with verbs>
---
```

New builds start at `version: 1`. Every `--update` bumps it and appends one line under a `## Changelog` section (keep last 5).

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
3. Trigger test (default on; `--no-triggers` skips for personal builds):
   a. Write 20 prompts from the skill's When-to-use branches: 10 positives (should fire, paraphrased — synonyms count) + 10 negatives (same domain, different object; must stay silent).
   b. Run each against a fresh agent with the skill installed (subagent per prompt, or batched where isolation holds). Record fire/silent per prompt.
   c. Score: 10/10 + 10/10 = pass. Else rewrite the `description` toward the misses (add missed phrasing, exclude false triggers), re-run. Max 3 rounds.
   d. Ship the scorecard: per-round pass rate + final description in the handover.
4. After 2 failed iterations: report DONE_WITH_CONCERNS naming the gap instead of silently shipping.

Completion: smoke script exits 0, one live trial passes, trigger scorecard green (or skipped with `--no-triggers`).

## Phase 6 — Verify + hand over

- [ ] Dedup verdict recorded (reused-local / reused-registry / miss / rebuilt-stale)
- [ ] smoke-skill.sh exits 0
- [ ] live trial passes
- [ ] trigger scorecard green (or `--no-triggers` noted)
- [ ] no secrets, tokens, personal data
- [ ] report DONE with: path, install command (`npx skills add <path-or-url> -g -a <agent> -y`), one-line trigger, what was deduped

Ship the skill + install line, not a plan.

## Updating — `--update <skill-dir> [<new-source>]`

Sources change; skills rot. Refresh instead of rebuilding.

1. Read the skill's `source:` + `version:` frontmatter. Re-ingest the source (or `<new-source>` if given) per Phase 2.
2. Diff coverage: what does the source teach that the skill lacks? What does the skill claim the source no longer supports? Change only those parts — never rewrite passing steps.
3. Bump `version:` +1, append one `## Changelog` line (`v<N>: <what changed, one line>`).
4. Run Phase 5 in full (smoke + live trial on the changed steps). Hand over with old→new version noted.
