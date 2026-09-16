# ZenUI AI Guide

ZenUI is intentionally designed to be easy for both humans and code-generating AI systems to compose.

## Load

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/PaveF/ZenUI/refs/heads/main/ZenUI.luau"))()
```

## AI discovery contract

The runtime exposes:

```lua
local manifest = Library:AIManifest()
local json = Library:AIManifest(true)
local matches = Library:DescribeAI("number")
```

`Library.AI` contains a deterministic, plain-data capability map. It describes the control kind, constructor name, mutability, and conventions that generated UI code should follow.

## Core controls

- `CreateToggle` — boolean state
- `CreateSlider` — bounded number
- `CreateDropdown` — enum or multi-select
- `CreateKeybind` — input binding
- `CreateTextBox` — string input
- `CreateButton` — action
- `CreateColorPicker` — color state
- `CreateLabel` / `CreateParagraph` / `CreateSection` / `CreateLine` — presentation
- `CreateColumns` — 2–4 column layouts

## Apex controls

- `CreateSegmented({ Options, CurrentOption, Callback })` — compact mutually-exclusive mode switcher.
- `CreateStepper({ Min, Max, Step, Default, Callback })` — bounded numeric state with step semantics.
- `CreateProgress({ Max, Value, Callback })` — live progress / telemetry display.
- `CreateInfoCard({ Title, Content })` — information card.
- `CreateActionGroup({ Actions = { {Name, Callback}, ... } })` — grouped actions.
- `CreateQuickToggle(name, callback, default)` — concise toggle constructor for generated code.

Every advanced control returns a small handle where practical, with `Get()` and/or `Set()` methods so AI-generated code can mutate state without reaching into implementation details.

## Recommended generation pattern

```lua
local Main = Window:CreateTab({Name = "Main", Icon = "◆"})

Main:CreateInfoCard({
    Title = "Ready",
    Content = "Choose a mode, tune the value, then run the action.",
})

local Enabled = Main:CreateToggle({
    Name = "Enabled",
    CurrentValue = true,
    Flag = "Enabled",
})

local Mode = Main:CreateSegmented({
    Name = "Mode",
    Options = {"Safe", "Balanced", "Fast"},
    CurrentOption = "Balanced",
})

local Progress = Main:CreateProgress({
    Name = "Progress",
    Max = 100,
    Value = 0,
})
```

## Design rules for AI-authored UIs

1. Give controls descriptive, stable `Name` values. ZenUI's search can use those names.
2. Use `Flag` for persistent state and configuration-backed values.
3. Prefer the smallest control that matches the data type.
4. Use `CreateSegmented` for a small exclusive enum and `CreateDropdown` for larger option sets.
5. Keep callbacks side-effect focused and accept the new value as the first parameter for value controls.
6. Use `CreateInfoCard` before complex control groups so users understand what a setting does.
7. Use `CreateActionGroup` for related actions instead of creating a long list of unrelated buttons.
8. Treat the returned control handle as the public API; avoid depending on internal Instances.

## Stable extension philosophy

ZenUI Apex is a composition layer over the original ZenUI core. Existing core controls remain available, while advanced controls and the AI contract are intentionally implemented outside the core rendering engine. This keeps the public API approachable and makes generated UI code resilient to internal visual changes.
