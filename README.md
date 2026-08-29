# yandex

A stateful command line interface to **Yandex Tracker** and **Yandex Wiki**.

## Install

### Homebrew (macOS)

```bash
brew install AntonLisovoy/tap/yandex-cli
```

### Shell installer (macOS, Linux)

```bash
curl -LsSf https://raw.githubusercontent.com/AntonLisovoy/yandex-cli/main/install.sh | sh
```

The installer verifies the SHA256 of the download, unpacks into
`~/.local/share/yandex-cli/<version>` and links `~/.local/bin/yandex`.

Builds are published for `macos-arm64` and `linux-x86_64`.

## Configure

Authentication - one of:

- `TRACKER_TOKEN` - OAuth token
- `TRACKER_IAM_TOKEN` - Yandex Cloud IAM token

Organization - exactly one of:

- `TRACKER_CLOUD_ORG_ID` - Yandex Cloud
- `TRACKER_ORG_ID` - on-premise

Get an OAuth token: <https://yandex.ru/support/tracker/ru/concepts/access>

```bash
export TRACKER_TOKEN=y0_AgAAA...
export TRACKER_ORG_ID=123456
yandex config check
yandex tracker queue list
```

## Use

```
yandex tracker <group> <command>   # queue, issue, attachment, board, sprint,
                                   # user, field, entity, project, automation,
                                   # template
yandex wiki <group> <command>      # page, grid, access, attachment, upload,
                                   # comment, operation (plus search, whoami)
yandex config|session|export ...
yandex repl                        # interactive mode
```

`yandex --help` lists everything.

## Use it from an AI agent

The CLI ships an agent skill documenting every command, and installs it for you -
the file lives inside the binary, so there is nothing to hunt for.

```bash
yandex skill install
```

That asks which agents you use and whether to install for the whole user account
or only the current directory. To skip the questions:

```bash
yandex skill install -a claude-code -g -y      # this user, Claude Code
yandex skill install -a cursor -a codex -y     # this directory, two agents
yandex skill install --dir ./somewhere/yandex  # an explicit directory
```

Supported agents: `claude-code`, `cursor`, `codex`, `copilot`, `gemini`, and
`universal` for anything that reads `.agents/skills/`. A project install goes to
`.agents/skills/yandex/` for every agent except Claude Code, which reads
`.claude/skills/yandex/`.

For an agent not on that list, print the skill and put it wherever that tool
keeps its instructions:

```bash
yandex skill show > AGENTS.md
yandex skill show               # print it, paste into your agent's own format
yandex skill path               # or just tell me where the file is
```

Re-run the install after upgrading. The skill is copied rather than linked, so
it describes the version you had when you installed it.

## Issues

Bug reports and feature requests: <https://github.com/AntonLisovoy/yandex-cli/issues>

## License

Apache-2.0
