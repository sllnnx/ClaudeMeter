# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.0] - 2026-09-21

First release of the [sllnnx](https://github.com/sllnnx/ClaudeMeter) fork, picking up
four pull requests left open upstream and adding further work on top.

### Added

- Model-scoped limits read from the API's `limits` array, so Fable, Opus, Sonnet and
  any model released later each get a usage card with no app update ([#32](https://github.com/eddmann/ClaudeMeter/pull/32))
- Every reported model is shown by default; Settings hides rather than reveals
- Pace-based utilization tracking, with a pace-first display mode ([#33](https://github.com/eddmann/ClaudeMeter/pull/33))
- Exact reset times in usage cards, with a toggle ([#26](https://github.com/eddmann/ClaudeMeter/pull/26))
- Multi Bar menu bar icon: one horizontal bar per limit, capped at five
- Vertical Bar menu bar icon: upright bars labelled `5H`, `W` and the model's initial
- Compact popover: every limit fits in one window, with per-card expansion for the
  expected-by-now figure, burn ratio and projection

### Changed

- The off-pace flame/snowflake badge now shows in Consumption mode, not only Pace mode
- Popover follows Apple's design guidance: spring animation from the current value,
  size-specific tracking, material for the structural layer, and independent handling
  of reduce-motion, reduce-transparency and increase-contrast
- Builds with no Apple Developer account: the project signs ad-hoc rather than pinning
  a development team

### Fixed

- Snapshot tests no longer fail on newer macOS, and no longer read the Keychain ([#31](https://github.com/eddmann/ClaudeMeter/pull/31))
- Settings icon picker rendered the bar styles as empty boxes
- Vertical Bar columns are evenly spaced, with labels centred on their bars

### Note

Releases are ad-hoc signed and **not** notarized by Apple. After moving the app to
Applications, clear the quarantine flag:

```bash
xattr -dr com.apple.quarantine /Applications/ClaudeMeter.app
```

## [1.4.0] - 2026-05-19

### Added

- Import Claude sessions from browsers signed in to claude.ai
- Accept pasted Cookie headers containing `sessionKey` during setup

## [1.3.2] - 2026-05-18

### Added

- Add monochrome menu bar icon mode

## [1.3.1] - 2026-05-18

### Fixed

- Handle null usage reset timestamps after Claude usage windows reset
- Use native small refresh spinner sizing in the popover
- Show precise reset durations for longer usage windows

## [1.3.0] - 2026-02-02

### Added

- Demo mode launcher and updated screenshots

## [1.2.1] - 2026-01-20

### Changed

- Release workflow now extracts version and release notes automatically from CHANGELOG.md

## [1.2.0] - 2026-01-16

### Added

- Pacing risk indicator to usage cards

### Changed

- Rename README directory to docs

### Fixed

- Skip snapshot tests due to rendering differences
- Disable code signing for test workflow

### CI

- Add test workflow to run Xcode tests on push

## [1.1.2] - 2026-01-14

### Changed

- Replace MenuBarExtra with NSStatusItem/NSPopover for improved menu bar behavior
- Modernize app lifecycle and testing architecture

### Added

- Notification tap-to-open functionality

## [1.1.1] - 2026-01-04

### Fixed

- Only show loading spinner when no data exists in menu bar

## [1.1.0] - 2026-01-02

### Added

- Configurable menu bar icon styles
- Homebrew tap distribution
- GitHub Pages landing page

## [1.0.7] - 2025-12-24

### Added

- Export usage data to ~/.claudemeter/usage.json for external tools
- os.log logging for API error debugging

### Fixed

- Force refresh usage data on app boot

## [1.0.6] - 2025-11-26

### Added

- Code signing and notarization to release workflow

## [1.0.5] - 2025-11-25

### Changed

- Replace Opus tracking with Sonnet

### Added

- Tooltip showing exact reset time

### Fixed

- NSUserNotificationsUsageDescription configuration

## [1.0.4] - 2025-11-19

### Fixed

- Change NotificationService from actor to @MainActor class for improved reliability

## [1.0.3] - 2025-11-19

### Fixed

- Improve settings persistence
- Improve notification permission handling

## [1.0.2] - 2025-11-19

### Fixed

- Replace ProgressView with static SF Symbol
- Adjust staleness threshold
- Force UserDefaults sync

## [1.0.1] - 2025-11-18

### Changed

- Clarify Claude.ai plan usage vs developer API in documentation

## [1.0.0] - 2025-11-18

### Added

- Initial ClaudeMeter macOS menu bar app
- Real-time usage monitoring for 5-hour session, 7-day weekly, and Sonnet-specific usage limits
- Menu bar integration with clean, color-coded usage indicator
- Smart notifications with configurable alerts at warning and critical thresholds (defaults: 75% and 90%)
- Auto-refresh with automatic usage updates every 1-10 minutes (customizable)

[1.5.0]: https://github.com/sllnnx/ClaudeMeter/releases/tag/v1.5.0
[1.4.0]: https://github.com/eddmann/ClaudeMeter/compare/v1.3.2...v1.4.0
[1.3.2]: https://github.com/eddmann/ClaudeMeter/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/eddmann/ClaudeMeter/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/eddmann/ClaudeMeter/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/eddmann/ClaudeMeter/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/eddmann/ClaudeMeter/compare/v1.1.2...v1.2.0
[1.1.2]: https://github.com/eddmann/ClaudeMeter/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/eddmann/ClaudeMeter/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/eddmann/ClaudeMeter/compare/v1.0.7...v1.1.0
[1.0.7]: https://github.com/eddmann/ClaudeMeter/compare/v1.0.6...v1.0.7
[1.0.6]: https://github.com/eddmann/ClaudeMeter/compare/v1.0.5...v1.0.6
[1.0.5]: https://github.com/eddmann/ClaudeMeter/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/eddmann/ClaudeMeter/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/eddmann/ClaudeMeter/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/eddmann/ClaudeMeter/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/eddmann/ClaudeMeter/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/eddmann/ClaudeMeter/releases/tag/v1.0.0
