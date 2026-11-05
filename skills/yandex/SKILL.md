---
name: "yandex"
description: "Use when a task involves Yandex Tracker issues, queues, boards, sprints, projects or automation; Yandex Wiki pages or dynamic tables; or Yandex Calendar schedules, event details and single personal events through the yandex CLI."
license: "Apache-2.0"
---

# yandex

A stateful CLI over the Yandex Tracker v3 and Yandex Wiki v1 REST APIs,
plus an independent OAuth + CalDAV Calendar backend. The API
clients ship inside the tool; there is no separate backend to install.

## Install and configure

```bash
brew install AntonLisovoy/tap/yandex-cli
# or
curl -LsSf https://raw.githubusercontent.com/AntonLisovoy/yandex-cli/main/install.sh | sh
```

Tracker/Wiki required environment (a local `.env` is read automatically):

- `TRACKER_TOKEN` (OAuth) **or** `TRACKER_IAM_TOKEN` (Yandex Cloud IAM)
- exactly one of `TRACKER_ORG_ID` (on-premise) / `TRACKER_CLOUD_ORG_ID` (Cloud)

Optional: `TRACKER_READ_ONLY`, `WIKI_READ_ONLY`, `TRACKER_LIMIT_QUEUES`,
`TRACKER_API_BASE_URL`, `WIKI_API_BASE_URL`, `TRACKER_TIMEOUT`,
`YANDEX_CLI_SESSION` (session file path).

Verify Tracker/Wiki before using those domains:

```bash
yandex --json config check
```

## Command groups

API commands live under `yandex tracker ...`, `yandex wiki ...` and
`yandex calendar ...`. Configuration, session, export and the REPL are shared and
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

## MCP server

`yandex mcp` speaks the MCP protocol on stdio instead of running one command:
41 curated Tracker and Wiki tools over the same code these commands use. Reach
for it when your harness connects to MCP servers and you want the tools listed
in your context; stay with the commands above when you are already driving a
shell. Configuration flags go before the subcommand, as in
`yandex --profile agent --read-only mcp`, and read-only modes simply do not
register the write tools. Setup for a client, the full tool list and the error
prefixes tools answer with are in
[MCP server](../../docs/storefront/docs/en/ai-agents.md#mcp-server).

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

1.5.0

## Calendar

Calendar needs no Tracker token/organization. Use `CALENDAR_TOKEN` then shared
`YANDEX_OAUTH_TOKEN`, plus full email `CALENDAR_USERNAME`. Never fall back to
Tracker/IAM. Defaults: `https://caldav.yandex.ru/`, timezone UTC; optional
`CALENDAR_TIMEZONE`, `CALENDAR_DEFAULT`, `CALENDAR_READ_ONLY`. Profiles accept
`--oauth-token-stdin` or `--calendar-token-stdin` (mutually exclusive), not token
arguments; config show fully redacts them. Obtain a new token via the existing
OAuth application's registered flow after changing permissions; old tokens do
not gain rights automatically. `calendar:all` is only a candidate scope. Ordinary-account OAuth uses the same
client flow by assumption. Targeted live meeting scheduling passed; this is
not a general guarantee of notification delivery.

Calendar remains a limited preview. It supports discovery, agenda, event reads,
personal-event creation and conditional single-event updates, including attendee
changes on servers with automatic scheduling. A targeted live test passed for meeting edits and attendee changes; the owner
confirmed receipt of invitation, update and cancellation notifications. Yandex deletion stays disabled because a live server
accepted stale-tag DELETE. Consumer-account OAuth parity is assumed; no separate live check is required. Minimum grants remain unverified.

```bash
yandex --json config check --service calendar
yandex --json calendar list
yandex --json calendar capabilities --calendar CALENDAR_ID
# Use exact discovered id, not display name; UID is unique only within calendar.
yandex --json calendar agenda --day 2026-11-02 --timezone Europe/Moscow
yandex --json calendar agenda --week 2026-11-02 --calendar CALENDAR_ID
yandex --json calendar agenda --from 2026-11-02T00:00 --to 2026-11-09T00:00 --limit 200
yandex --json calendar event get UID --calendar CALENDAR_ID
yandex --json calendar event create --calendar CALENDAR_ID --title Focus --start 2026-11-02T10:00 --end 2026-11-02T11:00 --timezone Europe/Moscow --uid UNIQUE_UID
yandex --json calendar event update UID --calendar CALENDAR_ID --description @notes.txt --location '' --if-match '"actual-etag"'
yandex --json calendar event delete UID --calendar CALENDAR_ID --if-match '"actual-etag"'
```

- Event commands require explicit `--calendar` or `CALENDAR_DEFAULT`; never select
  the first calendar. Agenda defaults to today/all discovered calendars when no
  default is set. `[]`/`items: []` are valid empty results.
- Agenda period `[from,to)` is at most 366 days; week means Monday–Monday. Limit
  100 by default, 1–1000; check `truncated`. JSON shape is
  `{items, truncated, from, to, timezone}`; `--select items.title` is supported.
- Get returns `{event, exceptions, capabilities, mutation}` (optional metadata may be null); series remain master plus detached overrides.
  If the master is absent, `event` is null and every known detached instance is
  in `exceptions`; agenda emits only these explicit instances. They remain read-only.
  Agenda expands RRULE/RDATE (including PERIOD)/EXDATE and moved/cancelled
  overrides; EXRULE and THISANDFUTURE are explicitly unsupported by agenda.
- Full collections are fetched (8 MiB XML, 2 MiB/resource, 10,000 DAV responses).
  The shared 10,000 processed-candidate budget includes historical, excluded and
  cancelled occurrences. Narrowing dates alone may not help: select fewer
  calendars or simplify series. Failures do not return partial agendas.
- Use explicit offsets for ambiguous/nonexistent DST times. All-day uses dates
  with exclusive end (`--all-day --start 2026-11-02 --end 2026-11-03` = one day).
  Update time requires both bounds; cannot switch all-day/timed. Omitted fields
  stay; empty description/location clears them. Empty patch/title is invalid.
Updates support single events, including meetings. Series, detached occurrences
and multi-VEVENT resources remain read-only. Create remains personal, with no
attendee or recurrence flags. RSVP/delegation, organizer reassignment, calendar
creation/sharing, offline sync and calendar undo are unsupported. DELETE on
compliant servers remains limited to personal events without ORGANIZER/ATTENDEE;
Yandex resource deletion is disabled. Removing an attendee through PUT is not
resource deletion.

**Compatibility change:** update and compliant-server delete now require caller
`--if-match`. Read with `event get`, review the event and pass its exact strong
quoted `event.etag`. The service compares that version at GET and sends the same
version in PUT; stale ETags or HTTP 412 stop the operation without merging,
overwriting or retrying. The ETag returned after a write may change again later.
Create uses `If-None-Match: *` and a unique UID.

Repeat `--add-attendee ADDRESS` and `--remove-attendee ADDRESS` to combine attendee
deltas with detail changes in one conditional PUT. Add accepts email or mailto;
remove uses the exact stored `attendees[].address`, including non-mailto addresses.
Omission preserves participants. Mail domain/scheme casing is normalized, while
local parts and aliases remain distinct. Duplicate patch entries are deduplicated;
adding and removing the same address is invalid. Existing additions/absent removals
are no-ops; ambiguous stored duplicates fail. An entirely unchanged patch skips
PUT and sequence/timestamp changes. New attendees have NEEDS-ACTION and RSVP=TRUE;
retained CN, ROLE, PARTSTAT, RSVP, scheduling status and other parameters survive.
Unknown ICS properties, alarms and timezone definitions are preserved.

Existing ORGANIZER and its parameters are preserved, including aliases on arbitrary
domains. Login/address equality never grants or denies permission. When adding the
first attendee without an organizer, one discovered owner address is selected
automatically; multiple choices return `organizer-required` with
`details.organizer_addresses`. Select one using `--organizer ADDRESS`; this flag
only initializes a missing organizer. No usable discovered address is unsupported.

An update involving attendees before or after the patch requires discovered RFC
6638 automatic server scheduling. Failed discovery blocks mutation, as does
explicit CLIENT/NONE SCHEDULE-AGENT on organizer or attendees. SERVER/default is
supported; there is no SMTP/manual invitation fallback or silent-update promise.
Server ACLs and scheduling preconditions decide authorization. Server scheduling
may send updates/REQUEST or CANCEL to removed attendees, including the last one.
Removing everyone preserves ORGANIZER and the event. Effective edits increment
SEQUENCE and update DTSTAMP/LAST-MODIFIED.

`calendar capabilities --calendar ID` returns `automatic_scheduling`,
`organizer_addresses` and an `operations` map. `event get` adds event-specific
`capabilities`. Each operation exposes `supported`, `permission`
(`allowed`/`denied`/`unknown`), `reason`, `requires_etag` and
`may_notify_attendees`. These are advisory; unknown role/permission is not a grant,
and every write rechecks current state and server conditions.

Successful update output adds `mutation`: `operation`, `outcome: verified`,
`changed`, `may_notify_attendees` and `delivery: unknown`. `verified` confirms stored
state after readback, not organizer identity, acceptance or invitation delivery.
Read output includes organizer/attendee `address`, `schedule_agent` and
`schedule_status` plus attendee response fields. Server SCHEDULE-STATUS is evidence
to inspect, not a blanket delivery guarantee; removed attendees' delivery remains
unknown. JSON errors add safe `code`, `operation`, `calendar_id`, `uid`, `outcome`
and `next_action` where available, plus safe DAV precondition names/namespaces.

| Outcome | Meaning and next step |
|---|---|
| `not_attempted` | No mutation attempted; fix input, permissions or unsupported operation as directed. |
| `rejected` | Server rejected the write; conflicts require rereading and reconsidering. |
| `unknown` | Transport failed after a mutation attempt; inspect the event, never blindly retry. |
| `accepted_unverified` | Write accepted but readback failed; inspect the event before another write. |
| `verified` | Stored state read back; delivery remains separate and unknown. |

Errors use `next_action`: `fix-input`, `reread-and-reconsider`, `check-permissions`,
`inspect-event` or `unsupported-operation`. Reconcile uncertainty with the reported
calendar ID and stable UID. Supply `--uid` on create for reliable cross-invocation
recovery; errors also include a generated UID when available. An existing UID is
a conflict, never proof that an earlier create succeeded or permission to overwrite.

`--calendar-read-only` is an independent root flag and survives REPL. Discovery
diagnostics do not prove write access. History retains IDs only, not bodies.
Calendar is CLI/REPL only: `yandex mcp` exposes Tracker/Wiki, no Calendar tools.

## Named service tokens

Use `yandex --profile NAME --json auth status` before credential troubleshooting. Explicit profiles never inherit credential environment variables. Tokens are profile-local, with one assignment per service; do not duplicate a secret across services. Use auth add/replace with --token-stdin, auth assign for rebinding, and --check to verify the saved profile. Never ask the user to paste a secret into chat or pass it in argv. On nonzero --check inspect saved: true before retrying. Migrate legacy profiles only through explicit auth migrate; this also repairs mixed formats while preserving assignments. New profiles use auth v1, and legacy setters cannot create them. Restart running MCP after changes. Mail is not supported.
