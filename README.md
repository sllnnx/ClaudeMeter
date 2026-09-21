# ClaudeMeter

![ClaudeMeter](docs/heading.png)

Keep track of your Claude.ai plan usage at a glance.

> **This is a fork of [eddmann/ClaudeMeter](https://github.com/eddmann/ClaudeMeter)** by Edd Mann.
> Upstream has had no commits since 19 May 2026, so this fork picks up four pull
> requests that were left open there and adds further work on top. All credit for
> the original app goes to Edd Mann; see [What's different from upstream](#whats-different-from-upstream).

## Features

- **Real-time usage monitoring** - Track your 5-hour session, 7-day weekly, and model-specific usage limits
- **Any model, no update needed** - Model-specific limits (Fable, Opus, Sonnet, ...) are read from whatever the API reports, so a newly launched model gets a usage card without an app update; switch off any you don't want in Settings
- **Menu bar integration** - Clean, colour-coded usage indicator that lives in your macOS menu bar
- **Multiple icon styles** - Choose from 7 icon styles: Battery, Circular, Minimal, Segments, Dual Bar, Gauge, or Multi Bar
- **Multi Bar icon** - One bar per limit in the menu bar: session, weekly, and each model-specific cap, so a Fable or Opus limit is visible without opening the popover
- **Pacing indicator** - Flame warns when you're burning faster than sustainable pace, snowflake when weekly quota is heading for waste. Shown in both display modes
- **Two display modes** - Consumption answers "how much have I used?", Pace answers "am I on track?"
- **Exact reset times** - Each card can show the precise reset timestamp alongside the relative one
- **Smart notifications** - Configurable alerts at warning and critical thresholds (defaults: 75% and 90%)
- **Auto-refresh** - Automatic usage updates every 1 minute, 5 minutes, or 10 minutes

## Screenshots

### Menu Bar

The menu bar icon changes colour based on your usage levels:

<p align="center">
  <img src="docs/menubar-safe.png" width="260" alt="Menu bar - Safe usage">
  <img src="docs/menubar-warning.png" width="260" alt="Menu bar - Warning threshold">
  <img src="docs/menubar-critical.png" width="260" alt="Menu bar - Critical threshold">
</p>

When a model has its own weekly cap, an additional card shows that model's usage:

<p align="center">
  <img src="docs/menubar-sonnet.png" width="300" alt="Menu bar - Sonnet usage">
</p>

### Notifications

ClaudeMeter sends native macOS notifications when you reach warning or critical thresholds:

<p align="center">
  <img src="docs/notifications.png" width="450" alt="Usage notifications">
</p>

### Settings

Configure your Claude session, refresh interval, icon style, and notification thresholds:

<p align="center">
  <img src="docs/settings-general.png" width="380" alt="Settings - General">
  <img src="docs/settings-notifications.png" width="380" alt="Settings - Notifications">
</p>

### Setup Wizard

<p align="center">
  <img src="docs/setup-wizard.png" width="600" alt="First-time setup wizard">
</p>

## Installation

### Download

1. Download the latest release from [GitHub Releases](https://github.com/sllnnx/ClaudeMeter/releases)
2. Unzip and move `ClaudeMeter.app` to Applications
3. Remove the quarantine flag, then open it:

```bash
xattr -dr com.apple.quarantine /Applications/ClaudeMeter.app
open /Applications/ClaudeMeter.app
```

This build is ad-hoc signed rather than signed with an Apple Developer ID, so it
is not notarized and Gatekeeper blocks it until the quarantine flag is cleared.
Right-click the app and choose Open if you prefer not to use the terminal.

## Usage

### First Launch

1. ClaudeMeter appears in your menu bar as a gauge icon
2. The setup wizard will guide you through initial configuration
3. Import from a browser signed in to [claude.ai](https://claude.ai), or paste your session manually
4. The app validates your session and begins monitoring usage

### Claude Session Setup

ClaudeMeter can import your existing Claude session from local browser cookies. Sign in to [claude.ai](https://claude.ai) in a supported browser, then choose **Import from Browser** in the setup wizard or Settings.

Chrome, Arc, Brave, Edge, and other Chromium browsers may ask for browser Safe Storage Keychain access so ClaudeMeter can decrypt cookies. Safari cookies are protected by macOS and may require Full Disk Access.

If browser import is unavailable, paste your session manually. ClaudeMeter accepts either a raw `sk-ant-...` session key or a Cookie header containing `sessionKey=...`.

#### Manual Session Setup

Your Claude session key is stored in your browser cookies.

**Chrome/Edge:**

1. Open [claude.ai](https://claude.ai)
2. Press `F12` to open DevTools
3. Go to Application > Cookies > `https://claude.ai`
4. Find the `sessionKey` cookie (starts with `sk-ant-`)
5. Copy the value

**Safari:**

1. Open [claude.ai](https://claude.ai)
2. Go to Develop > Show Web Inspector (enable Develop menu in Safari preferences if needed)
3. Go to Storage > Cookies > `https://claude.ai`
4. Find the `sessionKey` cookie (starts with `sk-ant-`)
5. Copy the value

**Firefox:**

1. Open [claude.ai](https://claude.ai)
2. Press `F12` to open Developer Tools
3. Go to Storage > Cookies > `https://claude.ai`
4. Find the `sessionKey` cookie (starts with `sk-ant-`)
5. Copy the value

### Daily Use

- Monitor your usage at a glance with the colour-coded menu bar icon
- Click the icon to access detailed statistics and adjust settings
- Receive automatic notifications when reaching warning or critical thresholds

### Integration with External Tools

ClaudeMeter exports usage data to `~/.claudemeter/usage.json` for use with external tools like Claude Code statusline scripts, shell prompts, or custom dashboards.

**JSON format:**

```json
{
  "last_updated": "2025-12-24T07:30:00Z",
  "session_usage": {
    "reset_at": "2025-12-24T12:00:00Z",
    "utilization": 29
  },
  "weekly_usage": {
    "reset_at": "2025-12-30T00:00:00Z",
    "utilization": 45
  },
  "scoped_usage": [
    {
      "name": "Fable",
      "is_active": true,
      "limit": {
        "reset_at": "2025-12-30T00:00:00Z",
        "utilization": 23
      }
    }
  ],
  "sonnet_usage": {
    "reset_at": "2025-12-30T00:00:00Z",
    "utilization": 15
  }
}
```

`scoped_usage` lists every model-specific limit the API reports, named as the API names it.
`sonnet_usage` is kept as a deprecated alias so existing statusline scripts keep working; it is
present only when a Sonnet limit exists. Prefer `scoped_usage` for new scripts.

**Example: Claude Code statusline**

Create `~/.claude/statusline.sh`:

```bash
#!/bin/bash
usage=$(jq -r '.session_usage.utilization' ~/.claudemeter/usage.json 2>/dev/null)

if [ -z "$usage" ] || [ "$usage" = "null" ]; then
  echo "Usage: ~"
elif [ "$usage" -lt 50 ]; then
  echo -e "\033[32mUsage: ${usage}%\033[0m"
elif [ "$usage" -lt 80 ]; then
  echo -e "\033[33mUsage: ${usage}%\033[0m"
else
  echo -e "\033[31mUsage: ${usage}%\033[0m"
fi
```

Then configure Claude Code's `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

## Requirements

- macOS 14.0 (Sonoma) or later
- Active Claude.ai account with a browser session or session key
- For browser import, a supported browser signed in to [claude.ai](https://claude.ai)

## Building from Source

```bash
# Clone the repository
git clone https://github.com/sllnnx/ClaudeMeter.git
cd ClaudeMeter

# Open in Xcode
open ClaudeMeter.xcodeproj

# Build and run (⌘R)
```

Requires Xcode 16.0 or later. No Apple Developer account is needed: the project signs
ad-hoc (`CODE_SIGN_IDENTITY = "-"`, no team), which is enough for the binary to run on
Apple Silicon. Set your own team in Signing & Capabilities if you want a stable signature
and fewer Keychain prompts across rebuilds.

## What's different from upstream

Forked from [eddmann/ClaudeMeter](https://github.com/eddmann/ClaudeMeter) at
[`da44a40`](https://github.com/eddmann/ClaudeMeter/commit/da44a40) (19 May 2026).

### Upstream pull requests merged

These were open and unmerged upstream. Credit to their authors.

| PR | Title | Author |
|----|-------|--------|
| [#26](https://github.com/eddmann/ClaudeMeter/pull/26) | Show exact reset time in usage cards | [@osulyanov](https://github.com/osulyanov) |
| [#31](https://github.com/eddmann/ClaudeMeter/pull/31) | Stop snapshot tests failing on newer macOS, and hitting the Keychain | [@mpecan](https://github.com/mpecan) |
| [#32](https://github.com/eddmann/ClaudeMeter/pull/32) | Track model-scoped limits from the API's `limits` array | [@mpecan](https://github.com/mpecan) |
| [#33](https://github.com/eddmann/ClaudeMeter/pull/33) | Pace-based utilization tracking in menu bar and popover | [@rshivane](https://github.com/rshivane) |

PRs #26, #32 and #33 each touched the same settings and popover files and do not
merge cleanly together. The conflicts are resolved here: #26's Sonnet toggle and
#33's single hardcoded "Weekly Sonnet" card are both superseded by #32's
model-scoped limits, so every scoped model now gets pace ratios, the
expected-by-now tick, projections and exact reset times.

### Added in this fork

- **Every model-scoped limit is tracked by default.** PR #32 reads model caps from
  the API's `limits` array but leaves them opt-in, so Fable stays invisible until
  switched on. Inverted to opt-out: anything the API reports gets a usage card on
  arrival, including models released after this build, and Settings hides rather
  than reveals.
- **Multi Bar menu bar icon.** Scoped limits previously never reached the menu bar
  at all. The new style stacks session, weekly and a bar per scoped model, shrinking
  to fit the 22pt menu bar and capping at 5 bars, with the busiest models keeping
  their slots. The six existing styles are unchanged.
- **Off-pace badge in Consumption mode.** The flame/snowflake badge was computed only
  in Pace mode. It now shows in both; only the primary number differs between them.
- **Design pass on the popover**, following
  [Apple's design principles](https://www.ui-skills.com/skills/emilkowalski/apple-design):
  springs that animate from the current value, size-specific tracking, material for
  the structural layer, and independent handling of reduce-motion, reduce-transparency
  and increase-contrast.
- **Builds without an Apple Developer account.** Upstream pins its own development
  team, which no one else can sign with. This fork signs ad-hoc, so it builds and runs
  from a clean clone.
- **Releases are unsigned** (ad-hoc, not notarized) — see [Installation](#installation).

### Fixes to the merged PRs

- PR #33's `PaceSignalTests` used the pre-#32 `UsageData` signature, so the test
  target did not compile once both were merged.
- PR #33 raised the Minimal icon font from 13pt to 15pt without re-recording its
  snapshot reference, failing that test on its own branch too.

## Disclaimer

**This is an unofficial tool** and is not affiliated with, endorsed by, or supported by Anthropic PBC.

This application accesses Claude's web API using browser-based authentication methods. **This may violate Anthropic's Terms of Service.** By using ClaudeMeter, you acknowledge that:

- Anthropic may block, restrict, or terminate access at any time
- Your Claude account could be affected by using unofficial API clients
- This app is signed and notarized by Apple
- **Use at your own risk** - the developer assumes no liability for any consequences

**Data storage:**

- Session keys are stored securely in macOS Keychain (encrypted, device-local only)
- Browser import reads local browser cookies to extract your Claude session, then stores only the session key in Keychain
- Usage data is cached locally (unencrypted, contains usage percentages only)
- No data is sent to third-party servers or collected by the developer

This software is provided "as is" under the MIT License, without warranty of any kind. **By downloading and using ClaudeMeter, you accept these terms.**

## License

MIT License - see [LICENSE](LICENSE) file for details.

Copyright (c) 2025 Edd Mann for the original work, (c) 2026 sllnnx for this fork.
