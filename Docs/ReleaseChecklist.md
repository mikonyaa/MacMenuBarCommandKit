# Release Checklist

## Build

- [ ] `swift test`
- [ ] Xcode demo build on macOS
- [ ] `./script/build_and_run.sh --verify`
- [ ] No new compiler warnings from source code

## Product

- [ ] Menu bar dashboard opens
- [ ] Main window opens from menu bar
- [ ] Settings opens
- [ ] Up/Down, Return, Escape, `⌘K`, `⌘N`, and `⌘,` work
- [ ] Keyboard focus returns to the previous control after closing the palette
- [ ] Captured clipboard text remains in the demo runtime until Clear Inbox
- [ ] Launch at Login status is reviewed in a signed app
- [ ] Launch at Login toggle matches current `SMAppService` status after reopening Settings

## Assets

- [ ] Main window screenshot
- [ ] Menu dashboard screenshot
- [ ] Command palette screenshot
- [ ] Settings screenshot
- [ ] README GIF matches the current demo

## GitHub

- [ ] README and README.ru match the current code
- [ ] CHANGELOG is updated
- [ ] `0.2.0` release draft and migration guide are reviewed
- [ ] Release tag is created only after manual approval
- [ ] Apple Design Templates catalog is updated
