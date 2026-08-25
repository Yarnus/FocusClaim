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

FocusClaim owns the selected modifier and left-click combination on supported
unit frames. An existing click-cast action on that combination is overwritten.

## Usage

Enter `/fc` or `/focusclaim` to open the settings panel. The panel contains only:

- Raid marker `1-8`
- Modifier key `Shift / Alt / Ctrl`
- Callout channel `Disabled / Party / Instance / Raid`

New characters default to `Shift + Left Click`, Skull, and Party chat. Settings
are stored per character in `FocusClaimSettings`.

## Design

FocusClaim writes one short macro directly to a secure action button and each
supported unit frame. It does not create or manage a character macro.

Refresh requests are coalesced, supported frames are deduplicated, and secure
attributes are rewritten only when the binding plan changes. The settings
controls are created only when the panel is first opened.

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
