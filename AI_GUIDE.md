# ZenUI AI Guide

ZenUI is designed so humans and code-generating AI systems can discover, compose, and mutate interfaces without depending on private implementation details.

## Load

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/PaveF/ZenUI/refs/heads/main/ZenUI.luau"
))()
```

The main entry point automatically loads the stable ZenUI visual core and the Apex extension layer.

## Discovery contract

```lua
local manifest = Library:AIManifest()
local json = Library:AIManifestJSON()
local matches = Library:Describe("progress")
```

The manifest is deterministic plain Lua data. A generator can inspect it before writing UI code instead of guessing from private instances.

## Control selection

| Intent | Use |
|---|---|
| Boolean | `CreateToggle` |
| Small exclusive enum | `CreateSegmented` |
| Large enum / set | `CreateDropdown` |
| Bounded integer | `CreateStepper` |
| Continuous number | `CreateSlider` |
| Free text | `CreateTextBox` |
| Color | `CreateColorPicker` |
| Action | `CreateButton` |
| Related actions | `CreateActionGroup` |
| Progress / telemetry | `CreateProgress` |
| Connection / health | `CreateStatusBar` |
| Explanation | `CreateInfoCard` / `CreateParagraph` |
| KPI / telemetry cards | `CreateStatGrid` |
| Searchable global actions | `CreateCommandCenter` |
| Secondary actions | `CreateContextMenu` |

## Generation conventions

1. Use stable, descriptive `Name` fields.
2. Use `Flag` for persistent configuration-backed state.
3. Prefer semantic constructors over manually-created GUI instances.
4. Pass the new value as the first callback argument for value controls.
5. Prefer public `Get()` / `Set()` handles over internal instance access.
6. Use `CreateSegmented` for a small mutually-exclusive enum.
7. Use `CreateStepper` when exact numeric increments matter.
8. Use `CreateProgress` and `CreateStatusBar` for live state instead of repeated notifications.
9. Use `CreateCommandCenter` for large action collections.
10. Use `CreateActionGroup` for related actions that belong together.

## Example

```lua
local Main = Window:CreateTab({
    Name = "Main",
    Icon = "home",
})

Main:CreateInfoCard({
    Title = "Control center",
    Content = "Choose a mode, tune the value, then start the task.",
})

local Mode = Main:CreateSegmented({
    Name = "Mode",
    Options = { "Safe", "Balanced", "Fast" },
    CurrentOption = "Balanced",
})

local Amount = Main:CreateStepper({
    Name = "Amount",
    Min = 0,
    Max = 100,
    Step = 5,
    Default = 25,
    Flag = "Amount",
})

local Progress = Main:CreateProgress({
    Name = "Progress",
    Max = 100,
    Value = 0,
})

Progress:Set(60)
```

## Handles

Use the handle returned by a constructor:

```lua
local Enabled = Main:CreateToggle({
    Name = "Enabled",
    CurrentValue = false,
    Flag = "Enabled",
})

Enabled:Set(true)
print(Enabled:Get())
```

## Extension philosophy

The Apex layer composes on top of the stable ZenUI core. Advanced controls are separate from the core renderer so the visual system can evolve without forcing generated code to depend on internal object names.