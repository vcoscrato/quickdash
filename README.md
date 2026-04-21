# QuickDash

This is my personal Wayland dashboard, built with [QuickShell](https://quickshell.outfoxxed.me/). It lives as a toggleable overlay — out of the way when I don't need it, instantly available when I do. No persistent bars, no always-on widgets eating screen space.

<p align="center">
  <img src=".github/print1.png" width="45%" />
  <img src=".github/print2.png" width="45%" />
</p>

If you're looking for ideas or a starting point for your own setup, feel free to borrow whatever's useful here. If you feel like discussing ideas, open up an issue.

> **Disclaimer:** Major parts of this repository were written by AI (as you can see by the poor code quality and the emote overflow below).

## What it does

- 🕐 **Clock** — time, date, weather, and an integrated focus timer
- 🗂 **Capture Pad** — merged scratchpad + clipboard history with quick recopy
- 🎵 **Now Playing** — media controls with album art via MPRIS
- 🔊 **Audio** — volume, mute, output switching
- ☀ **Brightness** — screen brightness + Night Light toggle (hides itself if there's no backlight)
- 📶 **Network** — WiFi/Ethernet status, scan, connect/disconnect, forget networks
- 🔵 **Bluetooth** — paired devices, power toggle, connect/disconnect
- 🔔 **Notifications** — built-in notification daemon with history and DND
- ⌨ **Keyboard** — layout switcher (Hyprland only)
- 📅 **Calendar** — month grid
- 🔋 **Battery** — percentage, state, time remaining (hides on desktop)
- 🚀 **Quick Launcher** — configurable app and command launcher
- ▫ **System Tray** — StatusNotifierItem icons

## Requirements

- **QuickShell** ≥ v0.2.1
- **PipeWire**, **NetworkManager**, **BlueZ** — the usual system services

Optional but worth having:
- **Hyprland** — needed for the keyboard layout switcher; also what I use as my compositor
- **brightnessctl** — needed to change brightness from the brightness widget
- **hyprsunset** — needed for the Night Light toggle in the brightness widget
- **cliphist** — needed for clipboard history inside Capture Pad
- **gtk-launch** — needed if you want launcher entries that use desktop ids

## Installation

Clone the repository anywhere on your machine:

```bash
git clone https://github.com/vcoscrato/quickdash.git ~/Documents/quickdash
cd ~/Documents/quickdash
./install.sh
```

The launcher points directly at the source tree you installed from, so if you move the repo later,
run `./install.sh` again from the new location.

The installer sets up three things:

| Path | What it is |
|------|------------|
| `~/.local/share/quickdash` | Runtime data directory for notes and to-dos |
| `~/.config/quickdash/config.jsonc` | Config file seeded from the bundled example |
| `~/.local/bin/quickdash` | Launcher script pointing at your source tree |

QuickDash also stores runtime data under `~/.local/share/quickdash/`, currently:
- `scratchpad.txt` for Capture Pad notes
- `todos.json` for the To-Do widget

Make sure `~/.local/bin` is in your `$PATH`, then:

```bash
quickdash
```

To uninstall (config files are kept):

```bash
./install.sh --uninstall
```

### My Hyprland setup

I run QuickDash inside a Hyprland special workspace alongside a terminal, so I can summon both with a single keybind:

```ini
# Super + ` toggles the dashboard workspace
bind = SUPER, GRAVE, togglespecialworkspace, dash

# Auto-launch QuickDash + a terminal the first time the workspace opens
workspace = special:dash, on-created-empty: quickdash & kitty
```

Reload Hyprland and `Super + `` will toggle the whole thing.

## Configuration

Your config lives at `~/.config/quickdash/config.jsonc`. It uses **JSONC** — standard JSON
that allows `//` line comments, `/* */` block comments, and trailing commas. Edit it with
any text editor.

The installer seeds this file from the bundled `config.example.jsonc`, which documents every
option with inline comments. See that file for the full reference.

Inside QuickDash, the **Config** panel (⚙) has two buttons:
- **Open** — opens the config file in `$VISUAL`, `$EDITOR`, or `xdg-open`
- **Reload** — triggers a full QuickShell reload so config and QML changes are both reapplied

QuickDash hides unsupported widgets automatically. If the machine has no battery, no Bluetooth
controller, no usable backlight, or no second monitor, those widgets are excluded from the
layout and sidebar rather than showing dead UI.

### Audio quick switch

`audioQuickSwitch` does two things: the ⇄ button cycles through those devices in order, and the
sink list only shows devices whose name contains one of those strings. Leave it empty to show
all sinks.

`audioInputQuickSwitch` does the same thing for microphone / input devices.

To find your sink names:

```bash
pactl list sinks | grep "Description:"
```

To find your source names:

```bash
pactl list sources | grep "Description:"
```

### Weather

`weatherLocation` controls the weather text shown inline in the **Clock** widget.

- Set it to a city or location string such as `"London"` or `"Sao Paulo"`.
- Leave it empty to let `wttr.in` infer a location automatically.
- Click the weather text in the Clock to refresh it manually.

### Quick launcher

Launcher entries live under `quickCommands`.

- Use `command` with an array for direct process execution.
- Use `shell` when you explicitly want a shell snippet.
- Use `desktop` for a desktop id launched with `gtk-launch`.
- Optional per-entry fields: `closeOnLaunch`, `workingDirectory`, `environment`, `clearEnvironment`.

Example:

```jsonc
{
    "quickCommands": [
        {
            "label": "Terminal",
            "icon": "",
            "command": ["kitty"]
        },
        {
            "label": "Projects",
            "icon": "🧰",
            "command": ["code", "."],
            "workingDirectory": "/home/victor/projects"
        },
        {
            "label": "Browser",
            "icon": "🌐",
            "desktop": "firefox"
        },
        {
            "label": "Reload Waybar",
            "icon": "↻",
            "shell": "pkill -USR2 waybar",
            "closeOnLaunch": false
        }
    ]
}
```

### Layout Zones

QuickDash uses a 3-zone anchored layout plus a sidebar. The zones are configured via arrays in your config file.

- `topAnchor`: Widgets shown at the top of the dashboard. Usually just `clock`.
- `bottomAnchor`: Widgets shown at the bottom of the dashboard. Usually `systemTray` and `calendar`.
- `middleDefault`: Widgets shown in the center space when no sidebar panel is open. Commonly `notificationCenter`.
- `sidebar`: List of objects specifying the widgets that open as panels when clicked, along with their icon.

Zones also support row groups. Use a nested array to render widgets side by side in a single row:

```jsonc
{
    "bottomAnchor": [["systemTray", "calendar"]],
    "middleDefault": [["batteryStatus", "systemMonitor"], "notificationCenter"]
}
```

`MiniPlayer` is not a configurable widget. It appears automatically above the middle zone when media is active.

Available widget names:

| Name | Widget |
|------|--------|
| `capturePad` | Notes + clipboard history |
| `clock` | Clock, date, weather, and focus timer |
| `nowPlaying` | Full media player panel |
| `quickCommands` | Quick launcher |
| `audioControl` | Volume (output) |
| `audioInputControl` | Volume (input/mic) |
| `brightnessControl` | Brightness |
| `displayControl` | Display mirror mode toggle |
| `networkPanel` | Network |
| `bluetoothPanel` | Bluetooth |
| `notificationCenter` | Notifications |
| `keyboardLayout` | Keyboard layout |
| `calendar` | Calendar |
| `batteryStatus` | Battery |
| `todoList` | Persistent to-do list |
| `randomQuote` | Rotating quote card |
| `configPanel` | Config path viewer, open and reload buttons |
| `systemMonitor` | CPU, memory, and thermal stats |
| `powerMenu` | Power actions |
| `systemTray` | System tray |

## Color schemes

- `catppuccin-mocha` — dark, lavender accents
- `catppuccin-macchiato` — dark
- `catppuccin-frappe` — dark
- `catppuccin-latte` — light
- `nord` — blue-gray
- `dracula` — dark purple
- `gruvbox` — warm retro
- `tokyo-night` — dark blue/purple
- `rose-pine` — dark pine/rose
- `solarized-dark` — teal/blue
- `everforest` — warm green (default)

## Project structure

```
quickdash/
├── shell.qml              # Entry point; loads config, owns the window
├── config.example.jsonc   # Documented config template seeded on first install
├── install.sh             # XDG-compliant installer (run once from source dir)
├── .github/               # Screenshots and assets
├── core/                  # Dashboard window and notification toast overlay
│   ├── Dashboard.qml
│   ├── NotificationToastWindow.qml
│   └── qmldir
├── theme/                 # Styling and color palettes
│   ├── Theme.qml
│   ├── Palettes.qml
│   └── qmldir
├── services/              # Logic and system integrations
│   ├── AudioService.qml
│   ├── ClipboardService.qml
│   ├── NetworkService.qml
│   ├── BluetoothService.qml
│   ├── DisplayService.qml
│   ├── FeatureSupport.qml
│   ├── SystemMonitorService.qml
│   ├── SystemState.qml
│   ├── WeatherService.qml
│   ├── ProcUtils.qml
│   └── qmldir
├── components/            # Reusable UI primitives
│   ├── Card.qml
│   ├── DeviceRow.qml
│   ├── TogglePill.qml
│   ├── StyledSlider.qml
│   ├── SidebarIcon.qml
│   ├── PanelHeader.qml
│   └── qmldir
└── widgets/               # Dashboard panels and widgets
    ├── AudioControl.qml
    ├── AudioInputControl.qml
    ├── BatteryStatus.qml
    ├── BluetoothPanel.qml
    ├── BrightnessControl.qml
    ├── Calendar.qml
    ├── CapturePad.qml
    ├── Clock.qml
    ├── ConfigPanel.qml
    ├── DisplayControl.qml
    ├── KeyboardLayout.qml
    ├── MiniPlayer.qml
    ├── NetworkPanel.qml
    ├── NotificationCenter.qml
    ├── NowPlaying.qml
    ├── PowerMenu.qml
    ├── QuickCommands.qml
    ├── RandomQuote.qml
    ├── SystemMonitor.qml
    ├── SystemTray.qml
    ├── TodoList.qml
    └── qmldir
```

QuickShell supports live reloading. Use the **Reload** button or `quickshell --reload` after
editing `config.jsonc`, and use the same reload path when you are iterating on the QML itself
from your source tree.

## Troubleshooting

**A widget name does nothing** — QuickDash now only accepts the widget names listed above. Old
aliases and removed widgets are not normalized anymore.

**Notifications not showing** — QuickDash runs its own notification daemon, so only one can be active at a time. Kill any other daemons first:

```bash
killall dunst mako swaync fnott 2>/dev/null
```

Then test with `notify-send "Test" "Hello"`.

**Now Playing not working** — the widget needs an MPRIS-compatible player. Check with:

```bash
playerctl -l
playerctl metadata
```

If nothing shows up, restart your browser or player.
