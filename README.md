# FocusClaim

English | [简体中文](README.zh-CN.md)

FocusClaim is a lightweight WoW Retail addon for setting a mouseover unit as
focus, applying a raid marker, and announcing that focus to the group.

## Features

- Set any mouseover unit as focus with `Shift / Alt / Ctrl + Left Click`
- Remove the current focus marker and clear focus with the same shortcut over empty space
- Move one selected raid marker to the new focus
- Announce `My focus {rtN} {unit name}` to party, instance, or raid chat
- Disable callouts while retaining focus and marker behavior
- Support Blizzard frames and nameplates, DandersFrames, EllesmereUI,
  Enhance QoL, and UUF unit, party, and raid frames
- Optional, movable focus cast bar with an interrupt-readiness timeline

FocusClaim owns the selected modifier and left-click combination on supported
unit frames. An existing click-cast action on that combination is overwritten.

## Usage

Enter `/fc` or `/focusclaim` to open the settings panel. It contains:

- Raid marker `1-8`
- Modifier key `Shift / Alt / Ctrl`
- Callout channel `Disabled / Party / Instance / Raid`
- An optional focus cast bar, locked by default; unlock it to drag and save its position
- Adjustable cast-bar width (120–600) and height (12–64); its icon follows the bar height
- Editable grey, green, orange, and neutral cast-bar colors

The cast bar is off by default and normally appears only while the focus is
casting or channeling. When enabled and unlocked, an idle preview remains visible
to show where it can be dragged. During casts it shows the spell icon, name, and
remaining time. Its colors indicate uninterruptible casts, a ready interrupt, or an
unavailable interrupt; when the
interrupt becomes ready mid-cast, the timeline marks that boundary. Unknown or
out-of-range states use the neutral or unavailable color rather than promising a
kick. Interrupt detection follows the known class/spec or pet interrupt.

New characters default to `Shift + Left Click`, Skull, and Party chat. Settings
are shared across all characters on the account in `FocusClaimSettings`. Switching
from per-character settings resets all options to their defaults; old character
settings are not migrated.

## Design

FocusClaim writes one short macro directly to a secure action button and each
supported unit frame. It does not create or manage a character macro.

Refresh requests are coalesced, supported frames are deduplicated, and secure
attributes are rewritten only when the binding plan changes. The settings
controls are created only when the panel is first opened. The independent focus
cast bar uses native cast/cooldown duration objects and secure-safe color/alpha
operations for cast timing and interruptibility data.

The default English macro is:

```text
/tm [@focus]0
/clearfocus [@mouseover,noexists]
/stopmacro [@mouseover,noexists]
/focus [@mouseover,exists]
/tm [@mouseover]8
/p My focus {rt8} %f
```

Settings changed during combat take effect after combat ends.

## Development

Run the Lua regression suite with `luajit tests/run.lua`.
