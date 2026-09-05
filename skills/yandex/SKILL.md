---
name: "yandex"
description: "Drive Yandex Tracker and Yandex Wiki from the command line: search and read issues, create/update/close them, comment, manage checklists, links and attachments, log time, run boards and sprints, manage projects/portfolios/goals, administer queues and their automation, edit wiki pages and dynamic tables, and export result sets to JSON/CSV/Markdown. Use when a task involves Yandex Tracker issues, queues, boards, sprints, projects, automation or Yandex Wiki content."
license: "Apache-2.0"
---

# yandex

A stateful CLI over the Yandex Tracker v3 and Yandex Wiki v1 REST APIs. The API
clients ship inside the tool; there is no separate backend to install.

## Install and configure

```bash
brew install AntonLisovoy/tap/yandex-cli
# or
curl -LsSf https://raw.githubusercontent.com/AntonLisovoy/yandex-cli/main/install.sh | sh
```

Required environment (a local `.env` is read automatically):

- `TRACKER_TOKEN` (OAuth) **or** `TRACKER_IAM_TOKEN` (Yandex Cloud IAM)
- exactly one of `TRACKER_ORG_ID` (on-premise) / `TRACKER_CLOUD_ORG_ID` (Cloud)

Optional: `TRACKER_READ_ONLY`, `WIKI_READ_ONLY`, `TRACKER_LIMIT_QUEUES`,
`TRACKER_API_BASE_URL`, `WIKI_API_BASE_URL`, `TRACKER_TIMEOUT`,
`YANDEX_CLI_SESSION` (session file path).

Verify before doing anything else:

```bash
yandex --json config check
```

## Command groups

Every API command lives under one of two domains — `yandex tracker ...` and
`yandex wiki ...`. Configuration, session, export and the REPL are shared and
stay at the top level.

| Group | Commands |
|-------|----------|
| `config` | `check`, `show`, `backend`, `list-profiles`, `set-profile`, `use-profile`, `delete-profile` |
| `session` | `status`, `use-queue`, `use-issue`, `history`, `undo`, `clear` |
| `tracker queue` | `list`, `get`, `tags`, `versions`, `fields`, `create`, `delete`, `restore`, `tag-remove`, `version-create`, `local-field`, `local-field-create`, `local-field-update`, `components`, `component-create`, `component-update`, `access`, `access-set`, `macros`, `macro-get`, `macro-create`, `macro-update`, `macro-delete` |
| `tracker field` | `global`, `statuses`, `types`, `priorities`, `resolutions` |
| `tracker issue` | `find`, `count`, `get`, `comments`, `links`, `worklogs`, `attachments`, `checklist`, `transitions`, `changelog`, `remote-links`, `url`, `create`, `update`, `transition`, `close`, `move`, `comment-add`, `comment-update`, `comment-delete`, `checklist-add`, `checklist-update`, `checklist-delete-item`, `checklist-clear`, `link`, `unlink`, `remote-link-add`, `remote-link-delete`, `attachment-upload`, `attachment-download`, `attachment-delete`, `worklog-add`, `worklog-update`, `worklog-delete` |
| `tracker attachment` | `upload-temp` |
| `tracker board` | `list`, `get`, `create`, `update`, `delete`, `columns`, `column-get`, `column-add`, `column-update`, `column-delete`, `sprints` |
| `tracker sprint` | `get`, `create`, `update`, `start`, `archive`, `delete` |
| `tracker entity` | `search`, `get`, `create`, `update`, `delete`, `comments`, `comment-add`, `comment-update`, `comment-delete`, `checklist-add`, `checklist-update`, `checklist-delete-item`, `checklist-clear`, `links`, `link`, `unlink`, `events` — the first argument is `project`, `portfolio` or `goal` |
| `tracker project` | `list`, `get`, `queues`, `create`, `update`, `delete` (the older `v3/projects` resource) |
| `tracker automation` | `trigger-get`, `trigger-create`, `trigger-update`, `trigger-logs`, `autoaction-get`, `autoaction-create`, `autoaction-logs` |
| `tracker user` | `list`, `search`, `get`, `me` |
| `wiki page` | `get`, `create`, `update`, `append`, `delete`, `recover`, `clone`, `descendants`, `resources`, `grids` |
| `wiki grid` | `get`, `create`, `update`, `delete`, `add-rows`, `remove-rows`, `add-columns`, `remove-columns`, `update-cells`, `move-rows`, `move-columns`, `clone` |
| `wiki access` | `grant`, `update`, `revoke`, `revoke-all` |
| `wiki attachment` | `list`, `upload`, `attach`, `download`, `download-url`, `delete` |
| `wiki upload` | `file`, `create`, `part`, `finish`, `get`, `abort`, `abort-all` |
| `wiki comment` | `list`, `add`, `thread`, `delete` |
| `wiki operation` | `status` (`--kind clone\|clone_inline_grid`) |
| `wiki` (top level) | `search`, `whoami` |
| `export` | `issues` (`--format json\|csv\|md`) |
| `repl` | interactive mode (also the default with no subcommand) |

## Agent usage

1. **Always pass `--json`** — the command then prints exactly one JSON document
   on stdout. Failures print `{"error": {"type": ..., "message": ...}}` and exit
   with code 1, so parse stdout in both cases.
2. **Search with the Tracker query language** (`-q`). Sort server-side with
   `--order '-updatedAt'`; page with `--page`/`--per-page`, or `--all` plus
   `--limit N` to bound the result.
3. **Discover before writing.** `tracker queue fields <QUEUE> --required-only`
   lists what `tracker issue create` must provide; `tracker issue transitions
   <KEY>` lists the ids accepted by `tracker issue transition --to`;
   `tracker field resolutions` lists ids for `tracker issue close`.
4. **Use the session** to avoid repeating keys: `session use-issue TREK-42`, then
   `tracker issue get`, `tracker issue comments`, `tracker issue update -s '...'`
   operate on it. `-` also means "the current one".
5. **Undo** reverts the last reversible write: `session undo` (with
   `--dry-run` to preview). Reversible, all under `tracker`: `issue update`,
   `issue worklog-add`, `issue comment-add`, `issue checklist-add`, `issue link`,
   `issue remote-link-add`, `issue attachment-upload`, `board create`,
   `board column-add`, `sprint create`, `entity create`, `entity comment-add`,
   `entity link`, `project create`, `queue create`, `queue macro-create`.
   Everything else (transitions, moves, deletes) is recorded in
   `session history` but cannot be undone.
6. **Extra fields** use repeated `--field key=value`; values parse as JSON when
   possible: `--field storyPoints=3`, `--field tags='["a","b"]'`.
7. **Long text and JSON payloads** can come from files with `@`:
   `--content @page.md`, `--rows @rows.json`.
8. **Safety switches**: `--read-only` refuses every Tracker write,
   `--wiki-read-only` every Wiki write, `--limit-queues TREK,OPS` restricts which
   queues may be touched at all.

### Keeping the result out of your context

Global flags go **before** the subcommand: `yandex --out kb.md wiki page get ...`.

- **Reading anything long** - send it to a file instead of your context:
  `yandex --out kb.md wiki page get --slug team/kb --content` prints only
  `{"output":…,"bytes":…,"lines":…,"slug":…}`. The body is written as raw text,
  so `grep -n "…" kb.md` and `sed -n '120,180p' kb.md` work on it directly.
- **Narrowing a structured result** - `--select key,status.display` keeps just
  those paths. Write paths the way the fields appear in the output
  (`updatedAt`, not `updated_at`). A path that matches nothing yields `null`,
  so check the path before concluding a field is empty.
- **Bounding a listing** - `--limit`, `--page`/`--per-page`, and
  `tracker issue count` before `tracker issue find` when you only need the size.
- **Server-side projection** - `tracker issue find --field key --field summary`
  narrows the request itself, which beats narrowing the response.
- **jq** for anything more complex, but always with `set -o pipefail`: a pipe
  otherwise swallows the exit code and turns the error envelope into `null`.

## Examples

```bash
# What is open and stale in a queue, newest first
yandex --json tracker issue find \
  -q 'Queue: TREK AND Resolution: unresolved()' --order '-updatedAt' --limit 20

# Read one issue; add --expand comments only when you actually need them
yandex --json tracker issue get TREK-42

# Create an issue with a required custom field
yandex --json tracker queue fields TREK --required-only
yandex --json tracker issue create TREK \
  -s 'Fix the export pipeline' -d 'Steps to reproduce...' --field storyPoints=3

# Edit, then change your mind
yandex tracker issue update TREK-42 -s 'Better title'
yandex session undo

# Log time and close
yandex tracker issue worklog-add TREK-42 --duration PT1H30M --comment 'review'
yandex --json tracker issue transitions TREK-42
yandex tracker issue close TREK-42 --resolution fixed --comment 'done'

# Discuss and organise an issue
yandex --json tracker issue comment-add TREK-42 -t 'Ready for review' --summon a.smith
yandex --json tracker issue checklist-add TREK-42 -t 'Tests' -t 'Docs'
yandex --json tracker issue link TREK-42 --to TREK-43 -r 'depends on'
yandex --json tracker issue changelog TREK-42 --field status
yandex --json tracker issue move TREK-42 --to OPS --initial-status

# Attach a file, then reference an already uploaded one in a comment
yandex --json tracker issue attachment-upload TREK-42 -f ./report.pdf
yandex --json tracker attachment upload-temp -f ./chart.png
yandex --json tracker issue comment-add TREK-42 -t 'See the chart' \
  --attachment-id <id from the previous call>

# Sprint planning
yandex --json tracker board list
yandex --json tracker sprint create -n 'Sprint 12' --board 1 \
  --start 2026-09-01 --end 2026-09-14
yandex --json tracker sprint start 45

# Projects, portfolios and goals
yandex --json tracker entity search project --filter entityStatus=in_progress
yandex --json tracker entity create goal -s 'Ship v1' --lead j.doe --end 2026-12-01
yandex --json tracker entity link goal 655f --to ent-2

# Queue administration and automation
yandex --json tracker queue macro-create TREK -n 'Nudge' -b 'Any news?'
yandex --json tracker queue access-set TREK \
  --permissions '{"write": {"users": {"add": ["a.smith"]}}}'
yandex --json tracker automation trigger-create TREK -n 'Assign on start' \
  --actions '[{"type": "Assignee", "assignee": "j.doe"}]' \
  --conditions '[{"type": "StatusChanged"}]'

# Weekly report as a file
yandex --json export issues \
  -q 'Queue: TREK AND Updated: week()' -o report.csv --format csv --overwrite

# Wiki: page plus a dynamic table
yandex --json wiki page create --slug team/kb --title 'Knowledge base'
yandex --json wiki grid create --title Owners --page-id 42
yandex wiki grid add-columns g-901 \
  --columns '[{"slug":"area","title":"Area","type":"string"}]'
yandex wiki grid add-rows g-901 --rows '[{"area":"CLI"}]'

# Wiki: find a page, send its content to a file, then work on it
yandex --json wiki search -q onboarding --type page --limit 5
yandex --out kb.md wiki page get --slug team/kb --content
yandex --json wiki page descendants --slug team/kb --include-self
yandex --json wiki access grant 42 --role editor --uid 1120000000000001
yandex --json wiki attachment upload 42 ./report.pdf
yandex --json wiki comment add 42 --body 'Ready for review?'
```

Wiki specifics worth knowing before you call anything:

- A page read returns only `id`, `slug`, `title` and `page_type` unless
  `--fields` asks for more (`content`, `attributes`, `breadcrumbs`, `redirect`,
  `access_policy`, `access_lists`, `owner`).
- `wiki page delete` hands back a `recovery_token`; `wiki page recover <token>`
  undoes it, including the subtree a `--recursive` delete removed.
- `wiki page clone` and `wiki grid clone` are asynchronous — poll the returned
  operation id with `wiki operation status <id>`, adding
  `--kind clone_inline_grid` for a table.
- Grid writes carry a `revision`; omit `--revision` and the CLI reads the
  current one first.
- There is no "list access grants" command because the API has no such
  endpoint — read them with `wiki page get --fields access_lists`.

## Failure modes to expect

| `error.type` | Meaning | Fix |
|--------------|---------|-----|
| `ConfigError` | missing/ambiguous credentials or org id | set `TRACKER_TOKEN` and one org variable |
| `BackendError` | HTTP failure from the API (401, 404, 409, 422, 429) | message names the cause; 409 means re-read for the current `version`/`revision` |
| `AccessDenied` | queue outside `--limit-queues` | widen the allow-list |
| `ReadOnlyError` | write attempted in read-only mode | drop `--read-only` / `--wiki-read-only` |
| `MissingArgument` | no issue/queue given and none in the session | pass the key or `session use-issue` |
| `ExportError` | output file exists | add `--overwrite` |

## Version

1.2.0
