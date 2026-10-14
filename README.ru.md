# MacMenuBarCommandKit

Reusable SwiftUI command shell и небольшое session-only demo для macOS. [English](README.md).

[![Swift 6](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-111111?logo=apple)](https://developer.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-2EA44F.svg)](LICENSE)

Часть [Apple Design Templates](https://github.com/mikonyaa/Apple-Design-Templates). Это candidate `0.3.0-rc.1`: [фактическая проверка и pending gates](Docs/Validation-0.3.0-rc.1.md) перечислены отдельно. Оценка 10/10 и production-ready не заявляются. Stable `0.2.0` остаётся доступным.

[GIF из partial native captures](Assets/GIFs/rc-native-content-captures.gif) · [coverage/provenance](Docs/Evidence/capture-provenance.json)

Product/module `MacMenuBarCommandKit`: Swift tools 6.0, macOS 14 minimum, без обязательных сети, аккаунтов и runtime dependencies. IDs, synchronous throwing handlers, данные и платформенные actions принадлежат приложению. Package предоставляет dynamic registry, menu/dashboard/palette, Settings и recovery для Launch at Login.

`CommandStore` теперь передаёт catalog changes своим observers. Reorder сохраняет selected ID, удаление и narrowing исправляют selection. Исполнение старого CommandItem берёт текущие metadata; удалённый ID даёт failure. `latestResult` сохраняет severity, существующий published `lastActionSummary` совместим. Legacy summary информативен и не получает success icon. История называется попытками/событиями, samples подписаны отдельно.

## Demo

| Команда | Поведение |
| --- | --- |
| New Note · ⌘N | Editor; непустой Save добавляет entry, Cancel ничего не добавляет |
| Start Timer · ⌘⇧T | Deadline +25 минут; повторный Start во время работы отклоняется |
| Cancel Timer · ⌘⌥T | Отмена без добавления completed duration |
| Capture Clipboard · ⌘⇧V | Читает текст только по явной команде; empty/large input даёт failure |
| Copy Status Report · ⌘⇧C | Копирует session report; отрицательный write Bool становится failure |
| Clear Inbox · ⌘⇧X | Удаляет entries; Undo Clear действует до следующего изменения inbox |
| Toggle Dashboard Focus · ⌘⌥F | Меняет badge, не системный Focus/Do Not Disturb |
| Open Dashboard · ⌘D | Открывает или возвращает окно |
| Open Settings · ⌘, | Открывает отдельные native Settings |

Inbox содержит typed note/clipboard entries со stable IDs. Выбранный текст можно прочитать целиком, скопировать и удалить. Он живёт **только до app quit или Clear**, не архивируется и не сохраняется после restart. Лимиты: 50 entries включая samples и 16 384 UTF-8 bytes на entry. Sample toggle удаляет только помеченные fixtures; реальные entries, timer и история в текущей сессии остаются. Theme/menu presentation и sample preference читаются до создания initial state и сохраняются через UserDefaults.

Timer показывает idle/running/remaining/finished/cancelled, сверяет deadline при foreground/wake и считает completed time при finish. Package не содержит demo timer или clipboard storage.

## Запуск и подключение

Нужны Mac и Apple SDK. Фактически проверенные версии compiler/OS указаны в [validation](Docs/Validation-0.3.0-rc.1.md); minimum deployment target не доказывает runtime check на macOS 14.

```bash
open Examples/CommandKitDemo/CommandKitDemo.xcodeproj
./script/build_and_run.sh
./script/build_and_run.sh --verify
```

Выбери CommandKitDemo / My Mac. Script сначала собирает в собственный DerivedData, затем получает новый PID через LaunchServices и проверяет bundle/executable paths. `run` ждёт Quit/Ctrl-C; cleanup касается только созданного instance. Verify проверяет окно и настоящий write/readback в private pasteboard. Он не завершает чужие apps по общему имени.

```swift
.package(url: "https://github.com/mikonyaa/MacMenuBarCommandKit.git", exact: "0.3.0-rc.1")
.product(name: "MacMenuBarCommandKit", package: "MacMenuBarCommandKit")
```

Создавай свои string-backed CommandID, metadata и handlers на MainActor; package начинается с пустого каталога. [Commands](Docs/Commands.md) и [migration](Docs/Migration-0.3.0.md) описывают public contract. Baseline consumer использует exact `0.2.0`, RC consumer — absolute `.package(path:)`; оба обходятся без `@testable`.

## Проверка и captures

```bash
swift test
swiftlint lint --strict
xcodebuild -project Examples/CommandKitDemo/CommandKitDemo.xcodeproj -scheme CommandKitDemo -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
bash -n script/build_and_run.sh
zsh -n Scripts/record_showcase.sh
git diff --check
```

В scheme добавлены model/UI test targets. [Native acceptance](Docs/NativeAcceptance.md) содержит точные commands, GUI journey, signed-login procedure и форму результатов. Hosted native key events/captures и fake controller не заменяют full XCUI, VoiceOver или signed Launch at Login. Headless focus skip остаётся pending. Developer pilot и Instruments performance study не заявляются.

PNG — partial native captures текущих RC content views. WindowServer capture заблокирован: preflight false, exit 1; системные privacy settings не менялись. Fallback не захватывает часть layer-backed/sidebar/native controls; полноценный visual gate остаётся pending. Stale PNG/GIF с Notifications удалены. Menu image снят с настоящего MenuBarDashboard в собственном native capture host; реальный click по system menu bar проверяется отдельно. [Provenance](Docs/Evidence/capture-provenance.json) указывает SHA/OS/mechanism. GIF собирается из PNG и не является screen recording.

- [Getting started](Docs/GettingStarted.md), [Architecture](Docs/Architecture.md), [Commands](Docs/Commands.md)
- [Migration 0.1.0 → 0.2.0](Docs/Migration-0.2.0.md), [Migration 0.2.0 → RC](Docs/Migration-0.3.0.md)
- [Customization](Docs/Customization.md), [Accessibility](Docs/Accessibility.md)
- [Release notes](Docs/ReleaseNotes-0.3.0-rc.1.md), [Checklist](Docs/ReleaseChecklist.md)
- [Предложение для каталога/профиля](Docs/CatalogProposal-0.3.0.md)

MIT.
