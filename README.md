**English** | [Русский](README.ru.md)

# yandex

## What it does

`yandex` is a command line interface to **Yandex Tracker** and **Yandex
Wiki**. It remembers which issue you are working on, so you name it once
instead of pasting the same key into every command:

```bash
yandex session use-issue TREK-1                          # once
yandex tracker issue get                                 # reads TREK-1
yandex tracker issue comment-add -t "Ready for review."  # comments on TREK-1
```

## Install

Two ways, and you only need one.

### Homebrew (macOS)

```bash
brew install AntonLisovoy/tap/yandex-cli
```

### Shell installer (macOS and Linux)

```bash
curl -LsSf https://raw.githubusercontent.com/AntonLisovoy/yandex-cli/main/install.sh | sh
```

It checks the download against the published SHA256, unpacks it into
`~/.local/share/yandex-cli/<version>` and links `~/.local/bin/yandex`. Builds
are published for `macos-arm64` and `linux-x86_64`.

## First run

```bash
yandex config set-profile work --token y0_... --org-id 123456
yandex config check
yandex tracker queue list
```

[Getting started](docs/en/getting-started.md) explains every one of those
steps, including how to get a token and which organization id is yours.

## Documentation

- **[Getting started](docs/en/getting-started.md)** - install and first run.
- **[Configuration](docs/en/configuration.md)** - profiles, environment
  variables, read-only modes.
- **[Commands](docs/en/commands.md)** - what it can do, and how the session,
  history and undo work.
- **[AI agents](docs/en/ai-agents.md)** - handing the CLI to a coding agent.
- **[Troubleshooting](docs/en/troubleshooting.md)** - every error, and the fix.
- **[Command reference](docs/reference.md)** - the `--help` of every command.

## Use it from an AI agent

The CLI carries its own manual for agents - a skill file describing every
command - inside the binary, so there is nothing to download.

```bash
yandex skill install
```

It asks which agents you use and where to put it, then writes the file where
they read it. [The guide](docs/en/ai-agents.md) covers those questions, the
flags that skip them, and agents that are not on the list.

## Issues

<https://github.com/AntonLisovoy/yandex-cli/issues>

## License

Apache-2.0
