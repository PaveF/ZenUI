# ZenUI

**ZenUI** is a modern, animated Roblox UI library written in Luau.

It is designed to give Roblox projects and scripts a polished control-panel experience with:

- modern dark themes
- animated windows and controls
- draggable windows
- minimize / restore / close controls
- a floating reopen button after closing
- searchable tabs and controls
- live theme switching
- notifications
- configuration saving/loading
- toggles, sliders, dropdowns, keybinds, text boxes, buttons, labels, paragraphs, sections, separators, and color pickers
- support for loading the library from a raw GitHub URL

The library is intentionally kept as a **single `.luau` file** so it is easy to host, update, and load remotely.

---

## Table of contents

- [Quick start](#quick-start)
- [Loading from GitHub](#loading-from-github)
- [Complete example](#complete-example)
- [Library settings](#library-settings)
- [Creating a window](#creating-a-window)
- [Tabs](#tabs)
- [Controls](#controls)
  - [Toggle](#toggle)
  - [Slider](#slider)
  - [Dropdown](#dropdown)
  - [Keybind](#keybind)
  - [TextBox](#textbox)
  - [Button](#button)
  - [Label](#label)
  - [Paragraph](#paragraph)
  - [Section](#section)
  - [Line](#line)
  - [Color Picker](#color-picker)
- [Window controls](#window-controls)
- [Themes](#themes)
- [Notifications](#notifications)
- [Configuration system](#configuration-system)
- [Search](#search)
- [Dragging](#dragging)
- [Lifecycle and cleanup](#lifecycle-and-cleanup)
- [Architecture](#architecture)
- [AI / contributor guide](#ai--contributor-guide)
- [Remote loading troubleshooting](#remote-loading-troubleshooting)

---

## Quick start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/PaveF/ZenUI/refs/heads/main/ZenUI.luau"))()

local Lib = Library.new({
    Name = "My Hub",
    Theme = "Midnight",
})

local Window = Lib:CreateWindow({
    Name = "My Hub",
    ConfigurationSaving = true,
    ConfigFolder = "MyHub_Configs",
    Keybind = Enum.KeyCode.Insert,
})

local Main = Window:CreateTab({
    Name = "Main",
    Icon = "◆",
})

Main:CreateSection({
    Text = "Main Controls",
})

Main:CreateToggle({
    Name = "Example Toggle",
    CurrentValue = false,
    Callback = function(value)
        print("Toggle:", value)
    end,
})

Main:CreateButton({
    Name = "Say Hello",
    Callback = function()
        print("Hello from ZenUI")
    end,
})
```



---

## Loading from GitHub

The repository should expose the `.luau` file through GitHub's raw-content endpoint.

Example format:

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/PaveF/ZenUI/refs/heads/main/ZenUI.luau"
))()
```

You can also pin to a tag or commit if you want a stable version rather than always loading the latest `main` version.

### Recommended repository layout

```text
PaveF/ZenUI
├── ZenUI.luau
└── README.md
```

Keeping the library as a single file makes remote loading simple and avoids dependency-order issues.

---

# Complete example

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/PaveF/ZenUI/refs/heads/main/ZenUI.luau"
))()

local Lib = Library.new({
    Name = "Nebula",
    Theme = "Aurora",
    Debug = false,
})

local Window = Lib:CreateWindow({
    Name = "Nebula Control",
    ConfigurationSaving = true,
    ConfigFolder = "Nebula_Configs",
    Keybind = Enum.KeyCode.Insert,
})

local Main = Window:CreateTab({
    Name = "Main",
    Icon = "◆",
    Badge = "NEW",
})

Main:CreateParagraph({
    Title = "Welcome",
    Content = "This is a sample ZenUI control panel."
})

local Enabled = Main:CreateToggle({
    Name = "Enabled",
    CurrentValue = true,
    Flag = "Enabled",
    Callback = function(value)
        print("Enabled:", value)
    end,
})

local Power = Main:CreateSlider({
    Name = "Power",
    Min = 0,
    Max = 100,
    Default = 50,
    Increment = 5,
    Suffix = "%",
    Flag = "Power",
    Callback = function(value)
        print("Power:", value)
    end,
})

local Mode = Main:CreateDropdown({
    Name = "Mode",
    CurrentOption = "Balanced",
    Options = {
        "Performance",
        "Balanced",
        "Quality",
    },
    Flag = "Mode",
    Callback = function(value)
        print("Mode:", value)
    end,
})

Main:CreateKeybind({
    Name = "Action Key",
    CurrentKeybind = "F",
    Flag = "ActionKey",
    Callback = function()
        print("Action triggered")
    end,
})

Main:CreateTextBox({
    Name = "Username",
    PlaceholderText = "Enter a name...",
    Callback = function(text)
        print("Text:", text)
    end,
})

Main:CreateButton({
    Name = "Notify",
    Callback = function()
        Lib:Notify({
            Title = "ZenUI",
            Content = "Hello from the notification system.",
            Duration = 3,
        })
    end,
})

local Settings = Window:CreateTab({
    Name = "Settings",
    Icon = "⚙",
})

Settings:CreateSection({
    Text = "Appearance",
})

Settings:CreateButton({
    Name = "Cycle Theme",
    Callback = function()
        Window:CycleTheme()
    end,
})
```

---

# Library settings

`Library.new(settings)` creates or resets the current ZenUI instance.

### Supported settings

```lua
Library.new({
    Name = "My Hub",
    Theme = "Midnight",
    Debug = false,
})
```

| Setting | Type | Default | Description |
|---|---|---:|---|
| `Name` | string | `"Rayfield UI"` | Name shown during the initial loading screen |
| `Theme` | string | `"Emerald"` | Initial theme |
| `Debug` | boolean | `false` | Enables internal debug logging |

---

# Creating a window

```lua
local Window = Lib:CreateWindow({
    Name = "My Window",
    ConfigurationSaving = true,
    ConfigFolder = "My_Configs",
    Keybind = Enum.KeyCode.Insert,
})
```

### Window options

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Window"` | Window title |
| `ConfigurationSaving` | boolean | `false` | Enables config persistence |
| `ConfigFolder` | string | `"UI_Configs"` | Folder used for config files |
| `Keybind` | `Enum.KeyCode` | `Insert` | Main UI visibility hotkey |

The window is draggable from its header.

---

# Tabs

```lua
local Tab = Window:CreateTab({
    Name = "Combat",
    Icon = "⚔",
    Badge = "NEW",
})
```

### Tab options

| Option | Type | Description |
|---|---|---|
| `Name` | string | Tab name |
| `Icon` | string | Text/Unicode icon displayed in the sidebar |
| `Badge` | string | Optional small badge shown on the tab |

The first tab created becomes the active tab automatically.

Tabs use animated selection and hover transitions.

---

# Controls

## Toggle

```lua
local Toggle = Tab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Keybind = "F",
    Callback = function(value)
        print(value)
    end,
})
```

Methods:

```lua
Toggle:Get()
Toggle:Set(true)
Toggle:Set(false)
```

---

## Slider

```lua
local Slider = Tab:CreateSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 100,
    Default = 16,
    Increment = 1,
    Suffix = "",
    Flag = "WalkSpeed",
    Callback = function(value)
        print(value)
    end,
})
```

Methods:

```lua
Slider:Get()
Slider:Set(50)
```

---

## Dropdown

```lua
local Dropdown = Tab:CreateDropdown({
    Name = "Mode",
    CurrentOption = "Balanced",
    Options = {
        "Performance",
        "Balanced",
        "Quality",
    },
    MultiSelection = false,
    Flag = "Mode",
    Callback = function(value)
        print(value)
    end,
})
```

Methods:

```lua
Dropdown:Get()
Dropdown:Set("Performance")
Dropdown:Refresh({
    "Low",
    "Medium",
    "High",
})
```

For multi-select:

```lua
local Dropdown = Tab:CreateDropdown({
    Name = "Features",
    Options = {
        "ESP",
        "Aimbot",
        "Speed",
    },
    CurrentOption = {},
    MultiSelection = true,
    Callback = function(values)
        print(table.concat(values, ", "))
    end,
})
```

---

## Keybind

```lua
local Keybind = Tab:CreateKeybind({
    Name = "Open Menu",
    CurrentKeybind = "Insert",
    Flag = "OpenMenu",
    Callback = function()
        print("Keybind fired")
    end,
})
```

Methods:

```lua
Keybind:Get()
Keybind:Set("F")
```

Click the keybind control to enter listening mode, then press the desired keyboard or mouse input.

---

## TextBox

```lua
local Box = Tab:CreateTextBox({
    Name = "Player Name",
    PlaceholderText = "Type something...",
    ClearTextOnFocus = true,
    Callback = function(text)
        print(text)
    end,
})
```

Methods:

```lua
Box:Get()
Box:Set("Hello")
Box:Clear()
```

---

## Button

```lua
local Button = Tab:CreateButton({
    Name = "Execute",
    Callback = function()
        print("Clicked")
    end,
})
```

Method:

```lua
Button:Set("New Button Text")
```

---

## Label

```lua
local Label = Tab:CreateLabel({
    Text = "Current status: Ready",
})
```

Method:

```lua
Label:Set("Current status: Running")
```

---

## Paragraph

```lua
local Paragraph = Tab:CreateParagraph({
    Title = "Information",
    Content = "This is a longer piece of text that can wrap automatically.",
})
```

Method:

```lua
Paragraph:Set({
    Title = "Updated title",
    Content = "Updated content",
})
```

---

## Section

```lua
Tab:CreateSection({
    Text = "Movement",
})
```

Sections are visual group headers used to organize controls.

---

## Line

```lua
Tab:CreateLine()
```

Creates a visual separator.

---

## Color Picker

```lua
local Picker = Tab:CreateColorPicker({
    Name = "Accent Color",
    Color = Color3.fromRGB(120, 255, 180),
    Flag = "AccentColor",
    Callback = function(color)
        print(color)
    end,
})
```

Methods:

```lua
Picker:Get()
Picker:Set(Color3.fromRGB(255, 80, 120))
```

The picker provides a saturation/value area and a hue bar.

---

# Window controls

ZenUI includes animated window management.

### Minimize

```lua
Window:Minimize()
```

### Restore

```lua
Window:Restore()
```

### Toggle minimize

```lua
Window:ToggleMinimize()
```

### Close

```lua
Window:Close()
```

Closing the window is intentionally non-destructive: the main window is hidden and a floating **Z** reopen button is shown.

### Set visibility

```lua
Window:SetVisible(true)
Window:SetVisible(false)
```

### Cycle theme

```lua
Window:CycleTheme()
```

### Permanently destroy the UI

```lua
Window:Destroy()
```

`Destroy()` removes the UI, disconnects registered connections, clears tracked instances, and resets library state.

---

# Themes

ZenUI ships with these themes:

```text
Emerald
Midnight
Blue
Rose
Ocean
Amber
Aurora
Violet
Mono
```

`Blue` is kept as a compatibility alias of the `Midnight` palette.

### Set a theme

```lua
Lib:SetTheme("Aurora")
```

### Get the current theme

```lua
print(Lib:GetTheme())
```

### List every available theme

```lua
print(table.concat(Lib:GetThemes(), ", "))
```

Theme changes are designed to update the live UI.

---

# Notifications

```lua
Lib:Notify({
    Title = "Success",
    Content = "Everything finished successfully.",
    Duration = 3,
})
```

`Duration` is measured in seconds.

There is also an alias:

```lua
Lib:CreateNotify({
    Title = "Hello",
    Content = "This uses the alias method.",
})
```

Notifications use animated entrance/exit transitions.

---

# Configuration system

Configuration support is opt-in.

Enable it when creating the window:

```lua
local Window = Lib:CreateWindow({
    Name = "My Hub",
    ConfigurationSaving = true,
    ConfigFolder = "MyHub_Configs",
})
```

Then flags can be assigned to controls:

```lua
Tab:CreateToggle({
    Name = "Enabled",
    CurrentValue = true,
    Flag = "Enabled",
})

Tab:CreateSlider({
    Name = "Power",
    Min = 0,
    Max = 100,
    Default = 50,
    Flag = "Power",
})
```

### Save

```lua
Lib:SaveConfig("default")
```

### Load

```lua
Lib:LoadConfig("default")
```

### Delete

```lua
Lib:DeleteConfig("default")
```

### List

```lua
local configs = Lib:ListConfigs()

for _, name in ipairs(configs) do
    print(name)
end
```

Supported serializable values include regular Lua values and `Color3` values.

---

# Search

The header contains a built-in search field.

Features:

- search tab names
- search supported controls by their display name
- animated filtering
- `Ctrl + K` focuses the search box

Control creators automatically register their display name for search.

For custom elements, the internal search attribute is:

```lua
GuiObject:SetAttribute("ZenSearchText", "Your Search Text")
```

This is primarily useful for contributors extending the library.

---

# Dragging

The window can be moved by dragging the header.

The implementation intentionally ignores:

- close button
- minimize button
- theme button
- search box

This prevents header controls from accidentally starting a drag.

---

# Close vs destroy

These two operations are different:

### Close

```lua
Window:Close()
```

Hides the window and keeps the UI instance alive. A floating **Z** button can reopen it.

### Destroy

```lua
Window:Destroy()
```

Completely removes the library instance.

This distinction is important when building scripts that need a persistent UI toggle.

---

# Architecture

The library is a single Luau module with several main layers.

```text
ZenUI
├── Environment helpers
│   ├── gethui / hidden GUI fallback
│   └── filesystem API detection
│
├── Theme system
│   ├── theme palettes
│   ├── live palette replacement
│   └── theme-bound UI attributes
│
├── UI construction
│   ├── Create()
│   ├── Corner()
│   ├── Stroke()
│   └── visual helper functions
│
├── Animation
│   ├── Tween()
│   ├── SpringTween()
│   ├── hover motion
│   └── window/page transitions
│
├── Library lifecycle
│   ├── new()
│   ├── Destroy()
│   └── re-entry guard
│
├── Configuration
│   ├── SaveConfig()
│   ├── LoadConfig()
│   ├── DeleteConfig()
│   └── ListConfigs()
│
├── Window
│   ├── header
│   ├── search
│   ├── minimize / close
│   ├── reopen launcher
│   ├── dragging
│   └── sidebar
│
├── Tabs
│
└── Controls
    ├── Toggle
    ├── Slider
    ├── Dropdown
    ├── Keybind
    ├── TextBox
    ├── Button
    ├── Label
    ├── Paragraph
    ├── Section
    ├── Line
    └── Color Picker
```

---

# AI / contributor guide

This section exists specifically so AI coding assistants and human contributors can understand the project before modifying it.

## Core rule

**Preserve the public API unless a change is explicitly intended to be breaking.**

Existing scripts may depend on method names, option names, callbacks, flags, and returned control objects.

When adding features:

1. Prefer additive changes.
2. Keep old option names working.
3. Avoid changing callback signatures.
4. Avoid renaming public methods unless a compatibility alias is provided.
5. Register all new `RBXScriptConnection`s through `AddConnection()`.
6. Register created Instances through `AddInstance()` when they should be cleaned up by `Destroy()`.
7. Use the existing `Create()` helper instead of constructing UI instances in a completely different way.
8. Use `Tween()` or `SpringTween()` for animations rather than introducing unrelated animation systems.
9. Use `Library.Theme` colors instead of hard-coded UI colors when the element should react to theme switching.
10. Keep the file self-contained. Do not add external module dependencies unless the project explicitly changes direction.

## Theme-aware UI

If a new element should recolor during:

```lua
Lib:SetTheme("Aurora")
```

its palette-bound properties should be created through the standard `Create()` helper using the current theme values.

The helper automatically tags matching `Color3` properties with attributes such as:

```text
ZenThemeRole_Text
ZenThemeRole_Element
ZenThemeRole_Accent
ZenThemeRole_Border
ZenThemeRole_Glow
```

Do not hard-code a visual role that should be theme-aware.

## Connections

Use:

```lua
AddConnection(SomeEvent:Connect(function()
    ...
end))
```

instead of creating unmanaged connections.

This matters because:

```lua
Library:Destroy()
```

disconnects tracked connections.

## Instances

Use:

```lua
AddInstance(instance)
```

for top-level or independently managed Instances that need to be destroyed with the library.

Do not manually destroy the same instance from multiple cleanup paths unless necessary.

## Animation rules

Prefer short, purposeful animations.

Typical examples:

```lua
Tween(object, {
    BackgroundColor3 = Library.Theme.ElementHover
}, 0.16)
```

For springy UI:

```lua
SpringTween(scale, {
    Scale = 1.02
}, 0.18)
```

Avoid animations that continuously recreate Instances or create uncontrolled loops.

Long-running animation loops should stop naturally when their parent Instance is removed.

## Search support

Controls intended to be searchable should set:

```lua
Container:SetAttribute("ZenSearchText", DisplayName)
```

The header search system looks for that attribute when filtering the active page.

## Public API stability

Current library-level methods:

```text
Library.new
Library:SetTheme
Library:GetThemes
Library:GetTheme
Library:Destroy
Library:SaveConfig
Library:LoadConfig
Library:DeleteConfig
Library:ListConfigs
Library:Notify
Library:CreateNotify
```

Current window methods:

```text
Window:CreateTab
Window:Minimize
Window:Restore
Window:ToggleMinimize
Window:Close
Window:SetVisible
Window:CycleTheme
Window:Destroy
```

Current control methods vary by control type, so preserve the existing returned-object interface when extending them.

---

# Remote loading troubleshooting

If the UI frame appears but tabs/buttons are missing, the script is usually stopping with a runtime error before control creation finishes.

### First thing to check

Enable debug mode:

```lua
local Lib = Library.new({
    Name = "Debug UI",
    Theme = "Midnight",
    Debug = true,
})
```

Then inspect the executor's output/error console.

### GitHub URL

Make sure you are loading the **raw file contents**, not the normal GitHub HTML page.

Correct style:

```text
https://raw.githubusercontent.com/PaveF/ZenUI/refs/heads/main/ZenUI.luau
```

Not:

```text
https://github.com/USERNAME/REPOSITORY/blob/main/zenui.luau
```

### If updating the library

After pushing a new version, use the latest raw URL or pin to a commit/tag intentionally.

If a previously working version suddenly stops building, compare the console error against the library initialization and window-construction code first.

---

# Design philosophy

ZenUI aims for a balance between:

**Visual polish**
- layered dark surfaces
- accent lighting
- rounded cards
- subtle borders
- animated hover states
- spring transitions

**Usability**
- draggable window
- clear navigation
- keyboard shortcut for visibility
- keyboard shortcut for search
- visible current page
- reopen launcher after closing

**Maintainability**
- single-file distribution
- centralized theme palette
- shared UI constructor
- centralized connection cleanup
- stable public API

The goal is not to make every element flashy. Motion and visual effects should support hierarchy and interaction.

---

# License

Choose the license for your repository here.

Example:

```text
MIT License
Copyright (c) 2026 YOUR NAME
```

Replace this section with the actual license terms you want to use.

---

## Credits

**ZenUI** — a single-file modern Luau UI library focused on animated, themeable Roblox interfaces.

Built to be easy to load, customize, extend, and understand.
