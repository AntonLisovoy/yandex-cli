[English](README.md) | **Русский**

# yandex

## Что это такое

`yandex` — это интерфейс командной строки к **Yandex Tracker** и **Yandex
Wiki**. Он запоминает, над какой задачей вы работаете, поэтому вы называете её
один раз, а не вставляете один и тот же ключ в каждую команду:

```bash
yandex session use-issue TREK-1                          # один раз
yandex tracker issue get                                 # читает TREK-1
yandex tracker issue comment-add -t "Ready for review."  # комментирует TREK-1
```

## Установка

Два способа, и нужен только один.

### Homebrew (macOS)

```bash
brew install AntonLisovoy/tap/yandex-cli
```

### Установщик-скрипт (macOS и Linux)

```bash
curl -LsSf https://raw.githubusercontent.com/AntonLisovoy/yandex-cli/main/install.sh | sh
```

Он сверяет загруженный файл с опубликованной контрольной суммой SHA256,
распаковывает его в `~/.local/share/yandex-cli/<version>` и делает ссылку
`~/.local/bin/yandex`. Сборки публикуются для `macos-arm64` и `linux-x86_64`.

## Первый запуск

```bash
yandex config set-profile work --token y0_... --org-id 123456
yandex config check
yandex tracker queue list
```

[Начало работы](docs/ru/getting-started.md) объясняет каждый из этих шагов, в
том числе как получить токен и какой идентификатор организации ваш.

## Документация

- **[Начало работы](docs/ru/getting-started.md)** — установка и первый запуск.
- **[Настройка](docs/ru/configuration.md)** — профили, переменные окружения,
  режимы только для чтения.
- **[Команды](docs/ru/commands.md)** — что CLI умеет и как устроены сессия,
  история и отмена.
- **[AI-агенты](docs/ru/ai-agents.md)** — как передать CLI агенту для
  программирования.
- **[Решение проблем](docs/ru/troubleshooting.md)** — каждая ошибка и лекарство
  от неё.
- **[Справочник команд](docs/reference.md)** — вывод `--help` каждой команды.

## Использование из AI-агента

CLI носит с собой собственное руководство для агентов — skill-файл с описанием
всех команд — внутри бинарника, так что скачивать ничего не нужно.

```bash
yandex skill install
```

Команда спрашивает, какими агентами вы пользуетесь и куда положить файл, а
затем записывает его туда, где они его читают.
[Руководство](docs/ru/ai-agents.md) разбирает эти вопросы, флаги, которые их
пропускают, и агентов, которых нет в списке.

## Сообщить о проблеме

<https://github.com/AntonLisovoy/yandex-cli/issues>

## Лицензия

Apache-2.0
