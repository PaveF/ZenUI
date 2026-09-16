# ZenUI

ZenUI is a polished, animated Roblox/Luau UI library with a stable classic control set and an Apex layer for higher-level interfaces.

## Highlights

### Core

- Animated premium windows with depth, ambient motion and sheen
- Draggable, minimizable, reopenable and resizable windows
- Searchable tabs and controls
- Theme switching, custom accents and UI scaling
- Notifications and configuration saving/loading
- Toggle, slider, dropdown/multi-select, keybind, text box, button, label, paragraph, section, separator and color picker
- 2–4 column layouts
- Built-in Settings tab on every window

### Apex

- `CreateCommandCenter` — searchable command/action launcher
- `CreateStatusBar` — compact live state indicator
- `CreateContextMenu` — secondary actions without permanent layout space
- `CreateStatGrid` — compact telemetry/KPI cards
- `CreateSegmented` — compact mutually-exclusive modes
- `CreateStepper` — bounded numeric input with explicit +/− controls
- `CreateProgress` — animated progress/telemetry display
- `CreateInfoCard` — compact explanatory context
- `CreateActionGroup` — generate related actions from data
- `CreateQuickToggle` — concise helper for generated code
- `AIManifest` / `AIManifestJSON` / `Describe` — machine-readable capability discovery

## Quick start

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/PaveF/ZenUI/refs/heads/main/ZenUI.luau"
))()

local Lib = Library.new({
    Name = "My Hub",
    Theme = "Emerald",
})

local Window = Lib:CreateWindow({
    Name = "My Hub",
    ConfigurationSaving = true,
    ConfigFolder = "MyHub_Configs",
    Keybind = Enum.KeyCode.Insert,
})

local Main = Window:CreateTab({
    Name = "Main",
    Icon = "home",
})

Main:CreateInfoCard({
    Title = "Welcome",
    Content = "Build polished, composable interfaces with ZenUI.",
})

Main:CreateToggle({
    Name = "Enabled",
    CurrentValue = true,
    Flag = "Enabled",
    Callback = function(value)
        print("Enabled:", value)
    end,
})
```

## Apex examples

### Segmented modes

```lua
local Mode = Main:CreateSegmented({
    Name = "Mode",
    Options = { "Performance", "Balanced", "Quality" },
    CurrentOption = "Balanced",
    Callback = function(value)
        print(value)
    end,
})
```

### Stepper

```lua
local Amount = Main:CreateStepper({
    Name = "Amount",
    Min = 0,
    Max = 100,
    Step = 5,
    Default = 25,
    Flag = "Amount",
    Callback = function(value)
        print(value)
    end,
})
```

### Progress + status

```lua
local Progress = Main:CreateProgress({
    Name = "Task Progress",
    Max = 100,
    Value = 0,
})

local Status = Lib:CreateStatusBar({
    Text = "Ready",
})

Progress:Set(60)
Status:Set("Task running", "info")
```

### Command center

```lua
Lib:CreateCommandCenter({
    PlaceholderText = "Search actions...",
    Commands = {
        { Name = "Refresh data", Callback = refresh },
        { Name = "Reset settings", Callback = reset },
        { Name = "Open configuration", Callback = openConfig },
    },
})
```

### Action group

```lua
Main:CreateActionGroup({
    Actions = {
        { Name = "Refresh", Callback = refresh },
        { Name = "Reset", Callback = reset },
        { Name = "Export", Callback = export },
    },
})
```

### Telemetry cards

```lua
Lib:CreateStatGrid(Main, {
    { Name = "Users", Value = 128 },
    { Name = "Latency", Value = "42ms" },
    { Name = "Tasks", Value = 19 },
})
```

## AI-first design

ZenUI exposes a deterministic capability contract so AI systems and code generators can discover the library without guessing from private UI instances.

```lua
local manifest = Library:AIManifest()
local json = Library:AIManifestJSON()
local matches = Library:Describe("progress")
```

### Recommended control selection

| Intent | API |
|---|---|
| Boolean | `CreateToggle` / `CreateQuickToggle` |
| Small exclusive enum | `CreateSegmented` |
| Large enum or set | `CreateDropdown` |
| Bounded integer | `CreateStepper` |
| Continuous numeric range | `CreateSlider` |
| Text input | `CreateTextBox` |
| Color | `CreateColorPicker` |
| Action | `CreateButton` |
| Related actions | `CreateActionGroup` |
| Live progress | `CreateProgress` |
| Connection / health | `CreateStatusBar` |
| Context / explanation | `CreateInfoCard` / `CreateParagraph` |
| Telemetry | `CreateStatGrid` |
| Global searchable actions | `CreateCommandCenter` |
| Secondary actions | `CreateContextMenu` |

### Generation conventions

1. Give interactive controls stable, descriptive `Name` values.
2. Use `Flag` for persistent configuration-backed state.
3. Prefer semantic constructors over hand-built Frame hierarchies.
4. Keep callbacks focused and pass the new value as the first callback argument where appropriate.
5. Use the returned `Get()` / `Set()` handle instead of touching implementation instances.
6. Use command surfaces for large action collections.
7. Use status/progress controls for live state instead of flooding the UI with notifications.

## Authenticity and unofficial builds

ZenUI is distributed through the canonical repository:

`https://github.com/PaveF/ZenUI`

The official entry point exposes build provenance APIs:

```lua
local info = Library:GetBuildInfo()
local status, details = Library:GetAuthenticityStatus()
local officialRepository = Library:GetOfficialRepository()
```

The authenticity result uses these statuses:

- `official` — local provenance matches the canonical published manifest.
- `modified-or-unofficial` — provenance disagrees with the canonical manifest.
- `unofficial` — the distribution is not identifying the canonical ZenUI repository.
- `unverified` / `unknown` — the manifest could not be confirmed.

The API is intentionally a **provenance signal**, not a claim of unforgeable client-side security. A determined person who controls the distributed source can modify or impersonate local metadata. Users should verify suspicious distributions against the canonical repository and `OFFICIAL_BUILD.json`.

See [`AUTHENTICITY.md`](AUTHENTICITY.md) for the full verification policy and [`LICENSE`](LICENSE) for the source/branding terms.

## Core control reference

### Toggle

```lua
local Toggle = Main:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(value)
        print(value)
    end,
})

Toggle:Get()
Toggle:Set(true)
```

### Slider

```lua
local Slider = Main:CreateSlider({
    Name = "Power",
    Min = 0,
    Max = 100,
    Default = 50,
    Increment = 5,
    Suffix = "%",
    Flag = "Power",
})
```

### Dropdown

```lua
local Dropdown = Main:CreateDropdown({
    Name = "Mode",
    CurrentOption = "Balanced",
    Options = { "Performance", "Balanced", "Quality" },
    Flag = "Mode",
})
```

For multi-selection, use `MultiSelection = true` and provide a table as `CurrentOption`.

### Keybind

```lua
Main:CreateKeybind({
    Name = "Action Key",
    CurrentKeybind = "F",
    Flag = "ActionKey",
    Callback = function()
        print("Action")
    end,
})
```

### TextBox

```lua
local Input = Main:CreateTextBox({
    Name = "Username",
    PlaceholderText = "Enter a name...",
    Callback = function(text)
        print(text)
    end,
})
```

### Button

```lua
Main:CreateButton({
    Name = "Execute",
    Callback = execute,
})
```

### Paragraph / section / separator

```lua
Main:CreateSection({ Text = "Settings" })
Main:CreateParagraph({ Title = "Info", Content = "Helpful context." })
Main:CreateLine()
```

### Color picker

```lua
Main:CreateColorPicker({
    Name = "Accent",
    Color = Color3.fromRGB(120, 255, 180),
    Flag = "Accent",
})
```

## Window controls

```lua
Window:Minimize()
Window:Restore()
Window:ToggleMinimize()
Window:Close()
Window:SetVisible(true)
Window:SetScale(0.90)
Window:SetSize(1100, 650)
Window:CycleTheme()
Window:Destroy()
```

Closing uses the floating reopen control; `Destroy()` is the destructive lifecycle operation.

## Multi-column layout

```lua
local Columns = Main:CreateColumns({ Count = 2, Gap = 12 })

Main:SetColumn(Columns[1])
Main:CreateToggle({ Name = "Left", CurrentValue = true })

Main:SetColumn(Columns[2])
Main:CreateSlider({ Name = "Right", Min = 0, Max = 100, Default = 50 })

Main:ClearColumnSelection()
```

`Count` supports 2–4 columns.

## Themes and appearance

ZenUI supports the theme names used by its core palette, including `Emerald`, `Midnight`, `Blue`, `Rose`, `Ocean`, `Amber`, `Aurora`, `Violet`, and `Mono`.

```lua
Lib:SetTheme("Aurora")
Lib:SetAccentColor(Color3.fromRGB(100, 255, 190))
Lib:ResetAccentColor()
```

The built-in Settings tab also provides scale, accent and window-size controls.

## Configuration

Use `Flag` on controls that should persist through the configuration system:

```lua
Main:CreateToggle({
    Name = "Enabled",
    CurrentValue = true,
    Flag = "Enabled",
})
```

## Repository layout

```text
PaveF/ZenUI
├── ZenUI.luau
├── ZenUI.Extensions.luau
├── README.md
├── AI_GUIDE.md
├── LICENSE
├── NOTICE.md
├── AUTHENTICITY.md
└── OFFICIAL_BUILD.json
```

`ZenUI.luau` is the recommended entry point. It loads the stable visual core and Apex extension layer automatically.

For reproducible builds, pin the loader URL to a commit SHA instead of `main`.

## Architecture

ZenUI Apex is intentionally split into layers:

1. **Stable core** — original ZenUI rendering, controls, themes, search, configuration and window lifecycle.
2. **Premium visual layer** — animated depth, ambient lighting, sheen and interaction polish.
3. **Apex extension layer** — higher-level semantic controls and AI-facing discovery.
4. **Provenance layer** — official build identity and authenticity metadata.
5. **Documentation layer** — human API docs plus `AI_GUIDE.md` for deterministic generation conventions.

This keeps the public API semantic and lets the visual implementation evolve without forcing AI-generated code to depend on internal instance names.
