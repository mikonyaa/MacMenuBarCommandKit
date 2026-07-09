# MacMenuBarCommandKit

Production-ready SwiftUI шаблон для macOS menu bar утилит с command palette, Settings и локальным demo dashboard.

[![Swift 6](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-111111?logo=apple)](https://developer.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-2EA44F.svg)](LICENSE)

Часть коллекции [Apple Design Templates](https://github.com/mikonyaa/Apple-Design-Templates).

![MacMenuBarCommandKit preview](Assets/GIFs/mac-menu-bar-command-kit.gif)

Шаблон подходит для desktop tools, timers, clipboard workflows, notes apps, system monitors и productivity utilities. Внутри есть `MenuBarExtra`, обычное Dock-visible окно, command palette, shortcuts, native Settings, Launch at Login через `SMAppService`, локальные demo data и понятная Swift Package архитектура.

## Что внутри

- Reusable Swift Package `MacMenuBarCommandKit`.
- Запускаемый macOS demo app: `Examples/CommandKitDemo/CommandKitDemo.xcodeproj`.
- Menu bar dashboard с quick commands, статусом, поиском и локальными метриками.
- `CommandPalette`, `CommandRegistry`, `CommandStore`, `DashboardStore`, `SettingsStore`.
- Native Settings scene с General, Appearance, Commands и About.
- `LaunchAtLoginService` для `SMAppService` со статусами enabled, disabled, requires approval, unsupported и error.
- Loaded, loading, empty и error состояния.
- Unit tests, GitHub Actions, issue templates, changelog и release checklist.

## Demo-команды

В demo есть 8 команд. Это не случайные кнопки, а компактный набор типовых действий для menu bar утилит:

| Команда | Что показывает | Видимый результат |
| --- | --- | --- |
| New Note | Быстрый локальный capture | Добавляет item в inbox и activity |
| Start Timer | Focus/timer workflow | Включает focus state и увеличивает protected time |
| Capture Clipboard | Работу с pasteboard | Сохраняет скопированный текст в local state |
| Copy Status Report | Вывод в системный clipboard | Копирует текстовый отчет в macOS pasteboard |
| Clear Inbox | Batch cleanup action | Обнуляет inbox metric |
| Toggle Focus Mode | Stateful toggle | Меняет focus status и badges |
| Open Dashboard | Window navigation | Открывает main workspace |
| Open Settings | Native preferences | Открывает SwiftUI Settings scene |

## Запуск

```bash
open Examples/CommandKitDemo/CommandKitDemo.xcodeproj
```

Выбери `CommandKitDemo` и запусти на My Mac.

Или через локальный script:

```bash
./script/build_and_run.sh
./script/build_and_run.sh --verify
```

## Как добавить команду

Добавь `CommandItem`, затем зарегистрируй handler в app entry point:

```swift
registry.register(.copyStatusReport) { command in
    print("Run \(command.title)")
}
```

Подробнее: [Commands](Docs/Commands.md).

## Документация

- [Getting started](Docs/GettingStarted.md)
- [Architecture](Docs/Architecture.md)
- [Commands](Docs/Commands.md)
- [Customization](Docs/Customization.md)
- [Accessibility](Docs/Accessibility.md)
- [Release checklist](Docs/ReleaseChecklist.md)

## Проверка

```bash
swift test
xcodebuild -project Examples/CommandKitDemo/CommandKitDemo.xcodeproj -scheme CommandKitDemo -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

## Лицензия

MIT.
