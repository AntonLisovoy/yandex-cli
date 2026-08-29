[English](../en/commands.md) | **Русский**

# Команды

Эта страница — обзорная экскурсия: как устроена командная строка, для чего
нужны группы команд, какая единственная возможность не обнаруживается через
`--help` — сессия — и набор разобранных рецептов для того, чем люди занимаются
на самом деле.

Если вы ещё не установили и не настроили CLI, начните с
[начала работы](getting-started.md).

## Из чего состоит команда

У любой команды одна и та же форма:

```
yandex [global flags] <domain> <group> <command> [arguments]
```

`yandex tracker issue get TREK-1` — это *домен* `tracker`, *группа* `issue`,
*команда* `get`, *аргумент* `TREK-1`. У некоторых вещей — `config`, `session`,
`export`, `skill`, `repl` — домена нет, потому что они не про Tracker и не про
Wiki: `yandex session status`.

> **Глобальные флаги ставятся перед доменом.** Эту ошибку каждый совершает
> один раз. `yandex --json tracker issue find -q "Queue: TREK"` работает.
> `yandex tracker issue find --json -q "Queue: TREK"` — нет, и отвечает так:
>
> ```
> Usage: yandex tracker issue find [OPTIONS]
> Try 'yandex tracker issue find --help' for help.
>
> Error: No such option '--json'.
> ```
>
> Глобальный флаг — `--json`, `--profile`, `--token`, `--read-only`,
> `--timeout` и остальные из списка в `yandex --help` — настраивает всю
> программу, поэтому он и относится к имени самой программы, а не к команде в
> конце строки.

`--help` работает на любом уровне, а `-h` — его короткая форма. Спрашивайте у
того уровня, в котором сомневаетесь:

```bash
yandex --help
yandex tracker --help
yandex tracker issue --help
yandex tracker issue find --help
```

Каждый из них перечисляет то, что доступно *ниже* этой точки, так что четыре
вопроса ведут от «что вообще есть» к «что принимает эта команда».

## Группы команд

Доменов два — Tracker и Wiki, — плюс небольшая горстка команд, которые
принадлежат самому CLI, а не какому-либо из API.

### Tracker

Всё, что находится под `yandex tracker <group> ...`:

| Группа | Для чего она |
|---|---|
| `queue` | Очереди: их метаданные, поля, компоненты, права и макросы. |
| `issue` | Задачи: поиск, чтение, создание, правка, переходы, закрытие, комментарии, чек-листы, связи, вложения и записи о затраченном времени. |
| `attachment` | Загрузка файла самого по себе, до того как на него кто-то сошлётся. |
| `board` | Agile-доски, их колонки и спринты на них. |
| `sprint` | Спринты: чтение, создание, запуск, архивирование. |
| `user` | Люди в организации. |
| `field` | Метаданные всей организации: поля, статусы, типы, приоритеты, резолюции. |
| `entity` | Проекты, портфели и цели через более новый API сущностей. |
| `project` | Проекты из более старого ресурса `v3/projects`. |
| `automation` | Триггеры и автодействия очереди. |
| `template` | Шаблоны задач и комментариев, настроенные в Tracker. |

### Wiki

Всё, что находится под `yandex wiki <group> ...`:

| Группа | Для чего она |
|---|---|
| `page` | Страницы Wiki: чтение, создание, обновление, дописывание, удаление, восстановление, клонирование. |
| `grid` | Динамические таблицы: их строки, колонки и ячейки. |
| `access` | Кто может читать и править страницу. |
| `attachment` | Файлы, приложенные к странице. |
| `upload` | Сессии многочастной загрузки — для файла, который не отправить за один раз. |
| `comment` | Комментарии к странице и их ветки. |
| `operation` | Состояние долгого копирования, запущенного через `page clone` или `grid clone`. |

Две команды Wiki стоят прямо под `yandex wiki`, потому что они не про одну
страницу:

| Команда | Для чего она |
|---|---|
| `search` | Поиск страниц и файлов по всей вики. |
| `whoami` | Показать, какому пользователю вики принадлежит текущий токен. |

### Общие команды

Перед этими группами домена нет:

| Группа | Для чего она |
|---|---|
| `config` | Учётные данные, профили и проверка того, что Яндекс их принимает. |
| `session` | Текущие очередь и задача, история изменений и отмена. |
| `export` | Запись результата поиска в файл: JSON, CSV или Markdown. |
| `skill` | Skill-файл для агента, который лежит внутри бинарника. |
| `repl` | Интерактивный режим — то же, что вы получаете, запустив `yandex` без аргументов. |
| `completion` | Скрипт автодополнения по Tab для bash, zsh или fish. |

## Сессия: что запоминает CLI

`yandex` — не программа, которая забывает всё в тот момент, когда завершается.
Между одной командой и следующей она хранит:

- **Текущую очередь** — чтобы команде, которой нужна очередь, можно было её не
  называть.
- **Текущую задачу** — чтобы `yandex tracker issue get` без ключа всё ещё
  что-то значил.
- **Последний набор результатов** — ключи последнего выполненного списка.
- **Историю изменений** — каждую команду, которая что-то изменила, со временем
  и сутью.
- **Стек отмены** — то подмножество этих изменений, которое можно откатить.

Всё это лежит в одном файле, `~/.yandex-cli/session.json`. Удалять его
безобидно: вы теряете текущую задачу, историю и стек отмены — и больше ничего.
(`YANDEX_CLI_SESSION` указывает на другой файл, а `YANDEX_CLI_HOME` переносит
весь каталог; см. [настройку](configuration.md#полный-список).)

### Как задать текущую очередь и задачу

Назовите задачу, над которой работаете, один раз:

```bash
yandex session use-issue TREK-42
```

```
  current_issue: TREK-42
  current_queue: TREK
  ✓ Current issue: TREK-42
```

Обратите внимание на вторую строку: вместе с задачей задаётся и очередь, взятая
из префикса ключа. `TREK-42` лежит в `TREK`, так что говорить об этом CLI не
нужно.

Чтобы задать очередь, не выбирая задачу в ней:

```bash
yandex session use-queue TREK
```

```
  current_queue: TREK
  ✓ Current queue: TREK
```

С этого момента аргумент с ключом задачи почти везде необязателен.
`yandex tracker issue get`, `yandex tracker issue comments`,
`yandex tracker issue comment-add -t "..."` — все они действуют на `TREK-42`.
Знак `-` вместо ключа означает то же самое, но явно; это удобно, когда вы
хотите, чтобы читатель вашего скрипта видел: тут полагаются на текущую задачу:

```bash
yandex tracker issue get -
```

Посмотреть, что запомнено:

```bash
yandex session status
```

```
  Session
  ───────
  path: /Users/you/.yandex-cli/session.json
  current_queue: TREK
  current_issue: TREK-42
  last_result: -
  history_entries: 0
  undo_available: 0
  next_undo: -
```

Запустите `use-queue` или `use-issue` без аргумента, чтобы очистить:

```bash
yandex session use-queue
```

```
  current_queue: -
  ✓ Current queue: <none>
```

Когда очищена и задача, команда, которой задача нужна и которой её не дали,
скажет об этом, а не станет гадать. Вот что печатает
`yandex tracker issue get` при пустой сессии:

```
  ✗ No issue given and no current issue in the session. Pass an issue key or run: session use-issue QUEUE-1
```

### История

Каждая команда, которая что-то записывает, попадает в журнал:

```bash
yandex session history --limit 20
```

```
  History
  ───────
  WHEN                      │ OP           │ SUMMARY        │ UNDOABLE
  ────────────────────────────────────────────────────────────────────
  2026-08-29T08:01:15+00:00 │ issue.update │ updated TREK-1 │ yes
  1 row(s)
```

В записи хранятся время по UTC, операция, переданные ей аргументы, краткое
описание в одну строку и признак того, можно ли её отменить. **Записываются
все изменения, в том числе те, которые отмена откатить не умеет,** — в этом
и смысл. Когда нужно понять, что скрипт сделал с Tracker полчаса назад, история
отвечает даже там, где отмена бессильна. Хранятся последние 200 записей.

### Отмена (undo)

`undo` откатывает самое недавнее обратимое изменение. Сначала посмотрите:
`--dry-run` показывает, что было бы откачено, и ничего не меняет.

```bash
yandex session undo --dry-run
```

```
  Would undo
  ──────────
  ts: 2026-08-29T08:01:15+00:00
  op: issue.update
  issue: TREK-1
  restore: {"summary": "Design the CLI command tree"}
  version: 1
```

`restore` — это то, что будет возвращено на место. Если этого вы и хотели —
делайте:

```bash
yandex session undo
```

```
  undone: issue.update
  issue: TREK-1
  issue_state: {"createdAt": "2026-08-01T10:00:00Z", "updatedAt": "2026-08-16T09:00:00Z", "createdBy": {"id": "j.doe", "display": "John Doe", "cloudUid": null, "passportUid": null}, "version": 3, "key": "TREK-1",...
  ✓ Undone: issue.update
```

Строка `issue_state` — это задача в том виде, в каком она осталась после
отката. Любое структурированное значение длиннее 200 символов в табличном виде
обрезается многоточием `...`; с `--json` оно печатается целиком.

Каждый вызов `undo` откатывает один шаг, а в стеке хранятся последние 50. При
пустом стеке:

```
  ✗ Nothing to undo.
```

Обратимы следующие операции, все внутри `tracker`:

`issue update`, `issue worklog-add`, `issue comment-add`,
`issue checklist-add`, `issue link`, `issue remote-link-add`,
`issue attachment-upload`, `board create`, `board column-add`,
`sprint create`, `entity create`, `entity comment-add`, `entity link`,
`project create`, `queue create`, `queue macro-create`.

**Переходы по статусам, переносы и удаления записываются в историю, но отменить
их нельзя.** Закрытие задачи, перенос её в другую очередь или удаление чего бы
то ни было — это решение, которое CLI не станет отыгрывать за вас. Если нужно
его отменить, сделайте это осознанно обратной командой.

## Рецепты

Всё остальное на этой странице — небольшой набор последовательностей, которых
хватает на большинство рабочих дней. Каждая самодостаточна: её можно
скопировать, подставить свои ключи очереди и задачи, и она работает.

### Найти задачи, назначенные на меня

```bash
yandex tracker issue find -q "Assignee: me() AND Resolution: empty()"
```

```
  Issues matching 'Assignee: me() AND Resolution: empty()'
  ────────────────────────────────────────────────────────
  KEY    │ SUMMARY                     │ STATUS │ TYPE   │ PRIORITY │ ASSIGNEE │ UPDATED
  ──────────────────────────────────────────────────────────────────────────────────────
  OPS-1  │ Rotate the tokens           │ Открыт │ Задача │ Normal   │ John Doe │ -
  TREK-1 │ Design the CLI command tree │ Открыт │ Задача │ Normal   │ John Doe │ -
  TREK-2 │ Implement the session store │ Открыт │ Задача │ Normal   │ John Doe │ -
  TREK-3 │ Write the export pipeline   │ Открыт │ Задача │ Normal   │ John Doe │ -
  4 row(s)
```

Текст после `-q` написан на **языке запросов Tracker** — том же самом, который
понимает строка поиска в веб-интерфейсе, так что всё, что вы умеете искать там,
вы можете искать и здесь. `me()` — это вы, `empty()` совпадает с незаполненным
полем, а `Queue: TREK AND Updated: week()` — второй шаблон, которым вы будете
пользоваться постоянно. Яндекс описывает весь язык, с каждым именем поля и
каждой функцией, на странице
<https://yandex.ru/support/tracker/ru/user/query-filter>.

Объём возвращаемого регулируют три опции:

- `--order` сортирует на стороне сервера: `--order '-updatedAt'` — сначала
  самые свежие, и порядок разворачивает именно ведущий `-`.
- `--all` обходит все страницы результатов, а не только первую.
- `--limit N` останавливается после N задач — именно это удерживает `--all` от
  выкачивания тысячи штук.

```bash
yandex tracker issue find -q "Queue: TREK" --order '-updatedAt' --all --limit 2
```

```
  Issues matching 'Queue: TREK'
  ─────────────────────────────
  KEY    │ SUMMARY                     │ STATUS │ TYPE   │ PRIORITY │ ASSIGNEE │ UPDATED
  ──────────────────────────────────────────────────────────────────────────────────────
  TREK-1 │ Design the CLI command tree │ Открыт │ Задача │ Normal   │ John Doe │ -
  TREK-2 │ Implement the session store │ Открыт │ Задача │ Normal   │ John Doe │ -
  2 row(s)
```

### Создать задачу

Очереди требуют разного. Спросите заранее, чтобы создание не сорвалось:

```bash
yandex tracker queue fields TREK --required-only
```

```
  Fields of TREK
  ──────────────
  ID      │ NAME    │ TYPE   │ REQUIRED │ KEY
  ───────────────────────────────────────────────
  summary │ Summary │ string │ yes      │ summary
  1 row(s)
```

Эта очередь настаивает только на заголовке, так что создание выходит коротким:

```bash
yandex tracker issue create TREK -s "Rotate the deploy key" -d "The key expires on Friday."
```

```
  Issue created
  ─────────────
  key: TREK-102
  summary: Rotate the deploy key
  status: Открыт
  url: https://tracker.yandex.ru/TREK-102
  ✓ Created TREK-102
```

`-s` — это заголовок, а `-d` — описание в формате Markdown. Тип, исполнителя и
приоритет добавляйте по мере надобности. `--type` принимает числовой
идентификатор, а не название, так что сначала выполните
`yandex tracker field types` и возьмите идентификатор из колонки `ID` — оттуда
и взялась `2` ниже:

```bash
yandex tracker issue create TREK -s "Rotate the deploy key" --type 2 --assignee j.doe --priority critical
```

Всё, что требует очередь и для чего нет отдельной опции, передаётся через
`--field key=value`, повторяемый столько раз, сколько нужно. Значение
читается как JSON, когда это возможно, и как обычный текст в остальных случаях,
так что числа и списки работают:

```bash
yandex tracker issue create TREK -s "Rotate the deploy key" --field storyPoints=3 --field tags='["ops","security"]'
```

Если обязательное поле не заполнено, Яндекс скажет об этом и назовёт его — см.
[решение проблем](troubleshooting.md#ошибки-от-api-яндекса).

### Прокомментировать задачу

```bash
yandex tracker issue comment-add TREK-1 -t "Ready for review."
```

```
  Comment on TREK-1
  ─────────────────
  createdAt: 2026-08-16T09:00:00Z
  updatedAt: 2026-08-16T09:00:00Z
  createdBy: {"id": "j.doe", "display": "John Doe", "cloudUid": null, "passportUid": null}
  id: 601
  longId: c601
  text: Ready for review.
  ✓ Added comment 601 to TREK-1
```

`--summon` подключает человека к обсуждению — то же самое, что набрать его имя
в комментарии в веб-интерфейсе, и он получит уведомление:

```bash
yandex tracker issue comment-add TREK-1 -t "Ready for review." --summon a.smith
```

Комментарий любой длины мучительно набирать в кавычках, а оболочка исковеркает
его при первом же апострофе. Напишите его в файле и передайте файл через `@`:

```bash
yandex tracker issue comment-add TREK-1 -t @comment.md
```

`@` — собственное соглашение CLI, а не оболочки: `-t @comment.md` означает
«взять текст из `comment.md`». То же самое работает для
`yandex wiki page create --content @notes.md` и для любой опции, принимающей
JSON.

### Перевести задачу по процессу и закрыть её

Задача не может перейти из любого статуса в любой другой: в каждой очереди есть
процесс, который говорит, что и откуда разрешено. Спросите у задачи, что она
может прямо сейчас:

```bash
yandex tracker issue transitions TREK-1
```

```
  Transitions of TREK-1
  ─────────────────────
  ID             │ DISPLAY  │ TO       │ TO KEY
  ─────────────────────────────────────────────────
  start_progress │ В работу │ В работе │ inProgress
  close          │ Закрыть  │ Закрыт   │ closed
  2 row(s)
```

Колонка `ID` — это то, что принимает `yandex tracker issue transition --to`.

Для закрытия нужна ещё *резолюция* — причина, по которой задача закрыта. Они
общие для всей организации, а не свои у каждой задачи:

```bash
yandex tracker field resolutions
```

```
  Resolutions
  ───────────
  ID │ KEY     │ NAME
  ──────────────────────────────────
  1  │ fixed   │ Решен
  2  │ wontFix │ Не будет исправлено
  2 row(s)
```

Теперь закройте задачу, указав причину и заметку для того, кто прочтёт это
позже:

```bash
yandex tracker issue close TREK-1 --resolution fixed --comment "Deployed in 1.0.0."
```

```
  Transitions now available for TREK-1
  ────────────────────────────────────
  ID             │ DISPLAY  │ TO
  ────────────────────────────────────
  start_progress │ В работу │ В работе
  close          │ Закрыть  │ Закрыт
  2 row(s)
  ✓ Closed TREK-1 with resolution 'fixed'
```

Сначала выясните, потом действуйте. Угаданный идентификатор перехода или ключ
резолюции — обычный способ получить от API `422`, и ни того, ни другого `--help`
подсказать не может: они принадлежат вашей организации, а не CLI.

Закрытие задачи **нельзя отменить** через `yandex session undo`. Чтобы открыть
её заново, осознанно переведите её обратно.

### Списать время

```bash
yandex tracker issue worklog-add TREK-1 --duration PT1H30M --comment "Code review."
```

```
  Worklog added to TREK-1
  ───────────────────────
  createdAt: 2026-08-16T09:00:00Z
  updatedAt: 2026-08-16T09:00:00Z
  createdBy: {"id": "j.doe", "display": "John Doe", "cloudUid": null, "passportUid": null}
  id: 502
  start: 2026-08-16T09:00:00Z
  duration: PT1H30M
  issue: {"id": null, "key": "TREK-1", "display": null}
  comment: Code review.
  ✓ Logged PT1H30M on TREK-1 (undoable)
```

`PT1H30M` — это **длительность по ISO 8601**, в таком виде её и хранит Tracker.
Читается слева направо: `P` начинает период, `T` начинает часть со временем, а
за каждым числом идёт его единица.

| Что нужно | Как написать |
|---|---|
| 30 минут | `PT30M` |
| 1 час | `PT1H` |
| 1 час 30 минут | `PT1H30M` |
| 2 дня | `P2D` |
| 3 дня и 4 часа | `P3DT4H` |

`T` обязателен, когда есть часть со временем: `P1H` недопустимо, а `PT1H` —
да. Обратите внимание на `(undoable)` в конце вывода: `yandex session undo`
удалит эту запись о времени.

### Приложить файл

Чтобы повесить файл на саму задачу:

```bash
yandex tracker issue attachment-upload TREK-1 -f report.pdf
```

```
  Attachment on TREK-1
  ────────────────────
  createdAt: 2026-08-16T09:00:00Z
  createdBy: {"id": "j.doe", "display": "John Doe", "cloudUid": null, "passportUid": null}
  id: att-2
  name: report.pdf
  content: https://api.tracker.yandex.net/v3/attachments/att-2
  size: 13
  mimeType: application/octet-stream
  metadata: -
  ✓ Attached report.pdf to TREK-1
```

Приложить файл **к комментарию** — это два шага, потому что файл должен
существовать до того, как комментарий сможет на него сослаться. Сначала
загрузите его отдельно:

```bash
yandex tracker attachment upload-temp -f report.pdf
```

```
  Temporary attachment
  ────────────────────
  createdAt: 2026-08-16T09:00:00Z
  createdBy: {"id": "j.doe", "display": "John Doe", "cloudUid": null, "passportUid": null}
  id: tmp-3
  name: report.pdf
  content: -
  size: 13
  mimeType: application/octet-stream
  metadata: -
  ✓ Uploaded report.pdf as tmp-3 (reference it with --attachment-id)
```

Затем укажите этот `id`, когда пишете комментарий:

```bash
yandex tracker issue comment-add TREK-1 -t "Numbers are in the attached report." --attachment-id tmp-3
```

Tracker называет первую загрузку *временной*, и CLI говорит об этом, печатая
идентификатор. Считайте эти два шага одним действием и выполняйте второй сразу
же, а не сохраняйте идентификатор на потом.

### Выгрузить результат поиска в CSV

```bash
yandex export issues -q "Queue: TREK AND Updated: week()" -o report.csv --format csv
```

```
  Export
  ──────
  output: /Users/you/report.csv
  format: csv
  rows: 3
  columns: ["key", "summary", "status.display", "type.display", "priority.display", "assignee.display", "created_at", "updated_at"]
  file_size: 335
  ✓ Wrote 3 issue(s) to /Users/you/report.csv (335 bytes)
```

Файл открывается в Excel, Numbers или Google Sheets как есть:

```
key,summary,status.display,type.display,priority.display,assignee.display,created_at,updated_at
TREK-1,Design the CLI command tree,Открыт,Задача,Normal,John Doe,,
TREK-2,Implement the session store,Открыт,Задача,Normal,John Doe,,
TREK-3,Write the export pipeline,Открыт,Задача,Normal,John Doe,,
```

Эти восемь колонок — набор по умолчанию. Чтобы выбрать свои, повторите
`--column` по разу на колонку. Колонка — это путь внутрь задачи: `key` —
обычное поле, а `status.display` заглядывает в объект `status` за его
человекочитаемым названием; поэтому значения по умолчанию и записаны так:

```bash
yandex export issues -q "Queue: TREK" -o report.csv --format csv --column key --column summary --column assignee.display
```

Повторный запуск того же экспорта не перезаписывает файл, а отказывается:

```
  ✗ report.csv already exists. Pass --overwrite to replace it.
```

Добавьте `--overwrite`, если заменить файл — это и есть то, чего вы хотели, а
для отчёта, который вы пересобираете каждый понедельник, обычно так и есть.

Кроме `csv` есть `--format json`, который пишет задачи целиком, со всеми
полями, чтобы их прочитала другая программа, и `--format md`, который пишет
таблицу Markdown — её можно вставить в страницу вики или в комментарий.

### Создать страницу в Wiki

```bash
yandex wiki page create --slug team/notes --title "Notes" --content @notes.md
```

```
  Wiki page created
  ─────────────────
  id: 11
  slug: team/notes
  title: Notes
  page_type: page
  attributes: {"created_at": "2026-08-16T09:00:00Z"}
  content: # Notes

Meeting notes for the week.

  ✓ Created wiki page team/notes
```

`--slug` — это адрес страницы внутри вики: `team/notes` — то, что появляется в
конце её URL, — а `--content @notes.md` читает тело из файла, что куда проще,
чем заключать целую страницу в кавычки в одну строку.

Чтение страницы возвращает меньше, чем можно ожидать:

```bash
yandex wiki page get --slug team/notes
```

```
  Wiki page
  ─────────
  id: 11
  slug: team/notes
  title: Notes
  page_type: page
```

Это не обрезка. **Чтение страницы возвращает только `id`, `slug`, `title` и
`page_type`**, пока вы не попросите большего, потому что страница вики бывает
очень большой, а большинству вызывающих нужно лишь её опознать. `--content`
добавляет тело:

```bash
yandex wiki page get --slug team/notes --content
```

`--fields` запрашивает всё остальное, через запятую: `content`, `attributes`,
`breadcrumbs`, `redirect`, `access_policy`, `access_lists`, `owner`:

```bash
yandex wiki page get --slug team/notes --fields content,attributes,access_lists
```

### Прочитать динамическую таблицу

Динамическая таблица — *grid* — живёт на странице, но является отдельным
объектом со своим идентификатором. Найдите его, спросив у страницы:

```bash
yandex wiki page grids 1
```

```
  Grids of page 1
  ───────────────
  ID  │ TITLE   │ CREATED
  ────────────────────────────────────
  g-1 │ Roadmap │ 2026-07-01T10:00:00Z
  1 row(s)
  next_cursor: None
```

`next_cursor` равен `None`, когда это был весь список; страница со множеством
таблиц возвращает курсор, который нужно передать в `--cursor`, чтобы получить
остальные.

Затем читайте таблицу по этому идентификатору:

```bash
yandex wiki grid get g-1
```

```
  Grid
  ────
  id: g-1
  title: Roadmap
  revision: 1
  rows: 1

  Columns
  ───────
  SLUG  │ TITLE │ TYPE   │ REQUIRED
  ─────────────────────────────────
  task  │ Task  │ string │ -
  owner │ Owner │ string │ -
  2 row(s)
```

Каждая запись в таблицу — `add-rows`, `update-cells`, `remove-columns` и
остальные — несёт с собой `revision`, то самое число, которое видно выше. Так
Wiki замечает, что кто-то отредактировал таблицу между вашим чтением и вашей
записью. Следить за ним самому не нужно: опустите `--revision`, и CLI прочитает
текущее значение прямо перед записью.

Добавляемая строка — это **объект** JSON, а не список: каждый ключ — это `slug`
колонки из таблицы выше, а те, что вы пропустили, останутся пустыми.

```bash
yandex wiki grid add-rows g-1 --rows '[{"task": "Ship v1", "owner": "j.doe"}]'
```

## JSON для скриптов

Поставьте `--json` перед доменом, и команда напечатает машиночитаемый JSON
вместо таблицы:

```bash
yandex --json tracker field resolutions
```

```
[
  {
    "id": 1,
    "key": "fixed",
    "version": 1,
    "name": "Решен",
    "order": 1
  },
  {
    "id": 2,
    "key": "wontFix",
    "version": 1,
    "name": "Не будет исправлено",
    "order": 2
  }
]
```

Разбирать это безопасно благодаря трём гарантиям:

- **Ровно один документ JSON в stdout** — том потоке, который читает другая
  программа, запустившая `yandex`, в отличие от stderr, куда уходят сообщения
  для человека. Больше в него ничего не печатается: строки о ходе работы,
  подтверждения с `✓` и оформленные таблицы подавляются, так что срезать шапку
  никогда не придётся.
- **Ошибки тоже приходят в JSON**, в форме
  `{"error": {"type": ..., "message": ...}}` и **с кодом возврата 1**. Значит,
  разбирать stdout можно одинаково независимо от того, получилась команда или
  нет:

  ```
  {
    "error": {
      "type": "BackendError",
      "message": "Issue 'NOPE-1' not found, or the token has no access to it."
    }
  }
  ```

- **`error.type` называет тип ошибки**, так что скрипт может ветвиться по нему,
  не разбирая английский текст. Вам встретятся `ConfigError`, `BackendError`,
  `AccessDenied`, `ReadOnlyError`, `MissingArgument` и `ExportError`; каждый
  разобран в [решении проблем](troubleshooting.md).

Обычный инструмент, чтобы выбрать нужное из результата, — `jq`:

```bash
yandex --json tracker issue find -q "Queue: TREK" | jq -r '.[] | "\(.key)\t\(.summary)"'
```

```
TREK-1	Design the CLI command tree
TREK-2	Implement the session store
TREK-3	Write the export pipeline
```

## Полный справочник

Всё изложенное выше — выборка. Полный список — каждая группа, каждая команда,
каждая опция вместе с точным текстом, который печатает `--help`, — лежит в
[`../reference.md`](../reference.md).

Та страница генерируется из самой программы, поэтому она не может разойтись с
установленной у вас версией. По той же причине она **только на английском**:
текст справки печатает CLI, а CLI по-русски не говорит. Руководства вокруг неё
переведены, справочник — нет.
