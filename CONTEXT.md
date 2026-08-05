# FocusClaim

FocusClaim coordinates a player's focus ownership signal: selecting a unit,
marking it, and optionally announcing that ownership to the group.

## Language

**Focus Shortcut**:
The configurable modifier plus left-click gesture used to choose a Focus Unit or clear the current focus.
_Avoid_: Trigger key, focus hotkey

**Focus Unit**:
The mouseover unit selected by the player as their current focus.
_Avoid_: Target, marked unit

**Focus Marker**:
The raid target marker selected by the player and applied whenever a Focus Unit is chosen.
_Avoid_: Mark, icon

**Focus Callout**:
A localized group announcement that identifies the player's Focus Marker.
_Avoid_: Custom message, notification

**Callout Channel**:
The selected group destination for a Focus Callout, or Disabled when no callout should be sent.
_Avoid_: Chat mode, custom command

**Empty-space Clear**:
Using the Focus Shortcut without a mouseover unit to clear the current focus without marking or announcing.
_Avoid_: Clear-on-blank option
