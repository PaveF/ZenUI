# ZenUI

A [Rayfield](https://github.com/shlexware/Rayfield)-style UI library built for the **Real** executor.

Classic dark theme, left sidebar tabs, green accent, toggle/slider/dropdown/keybind/colorpicker elements, toast notifications, and `Flag`-based config saving — so existing Rayfield menus port over with minimal renames.

## Features

- 🪟 Draggable, keybind-toggleable window (default `Insert`) with an intro loading screen
- 🗂️ Left sidebar tabs with animated active state
- 🎛️ Elements: `Toggle`, `Slider`, `Dropdown` (single + multi), `Keybind`, `Button`, `TextBox`, `Label`, `Paragraph`, `Section`, `Line`, `ColorPicker`
- 🔔 Toast notifications
- 🎨 Two built-in themes (`Default` green / `Blue`)
- 💾 Config save/load keyed by `Flag` (color-picker colors survive JSON round-trips)
- 🔁 Safe to re-run — old instances and connections are torn down first
- 🛡️ Defensive: missing executor functions degrade instead of crashing, all tweens/IO are `pcall`-wrapped

## Requirements

- The [Real](https://github.com) executor (injected client recommended)
- A Roblox game
- Nothing else — no external assets, no `require()` of game modules

## Usage

Copy `zenui.luau` into Real's **Scripts** folder and run it, or paste the file contents into the executor, then run:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/zenui/main/zenui.luau"))()

local lib = Library.new({ Name = "My Hub", Theme = "Blue", Debug = false })

local Window = lib:CreateWindow({
    Name = "My Hub",
    ConfigurationSaving = true,
    Keybind = Enum.KeyCode.Insert, -- open/close the UI
})

local Tab = Window:CreateTab({ Name = "Main" })

Tab:CreateToggle({
    Name = "Speed",
    CurrentValue = false,
    Flag = "Speed",              -- saved/loaded when ConfigurationSaving is on
    Keybind = "F",               -- optional: toggle it from a key
    Callback = function(value)
        print("Speed:", value)
    end,
})

Tab:CreateSlider({
    Name = "Walkspeed",
    Min = 16,
    Max = 50,
    Default = 20,
    Increment = 1,
    Suffix = " ws",
    Flag = "Walkspeed",
    Callback = function(value)
        print("Walkspeed:", value)
    end,
})

Tab:CreateDropdown({
    Name = "Mode",
    Options = { "A", "B", "C" },
    MultiSelection = true,
    CurrentOption = { "A" },
    Flag = "Mode",
    Callback = function(value)
        print("Mode:", value)
    end,
})

Tab:CreateKeybind({
    Name = "Fly",
    CurrentKeybind = "LeftControl",
    Flag = "FlyKey",
    Callback = function()
        print("Fly key pressed")
    end,
})

Tab:CreateTextBox({
    Name = "Message",
    PlaceholderText = "type here",
    Callback = function(text)
        print("Message:", text)
    end,
})

Tab:CreateButton({
    Name = "Execute",
    Callback = function()
        print("Button clicked")
    end,
})

Tab:CreateLabel({ Text = "A static label" })
Tab:CreateSection({ Text = "Section" })
Tab:CreateLine()
Tab:CreateParagraph({ Title = "Info", Content = "This is a paragraph." })

Tab:CreateColorPicker({
    Name = "Accent",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "Accent",
    Callback = function(color)
        print("Color:", color)
    end,
})

-- Save / load / delete configs at any time:
lib:SaveConfig("main")
lib:LoadConfig("main")
lib:DeleteConfig("main")
local configs = lib:ListConfigs()

-- Toast notification:
lib:Notify({ Title = "Hello", Content = "Library loaded", Duration = 3 })

-- Full teardown (also runs automatically if you re-run the file):
lib:Destroy()
```

## API

### `Library.new(options)`

| Field     | Type            | Default | Description                     |
| --------- | --------------- | ------- | ------------------------------- |
| `Name`    | `string?`       | `nil`   | Shown on the loading screen.    |
| `Theme`   | `"Default"` `"Blue"` | `Default` | Accent color.               |
| `Debug`   | `boolean?`      | `false` | Prints `[Lib]` diagnostics.     |

Returns the `Library` object.

### `Library:CreateWindow(options)` → `Window`

| Field               | Type           | Default            | Description                          |
| ------------------- | -------------- | ------------------ | ------------------------------------ |
| `Name`              | `string?`      | `"Window"`         | Title shown in the header.           |
| `Keybind`           | `Enum.KeyCode?`| `Insert`           | Show/hide the window.                |
| `ConfigurationSaving` | `boolean?`   | `false`            | Enables config save/load by `Flag`.  |
| `ConfigFolder`      | `string?`      | `"UI_Configs"`     | Folder config `.json` files live in. |

### `Window:CreateTab(options)` → `Tab`

| Field  | Type     | Default  | Description       |
| ------ | -------- | -------- | ----------------- |
| `Name` | `string?`| `"Tab"`  | Tab button label. |

### Element constructors

All element options accept `Name`, `Callback`, and (except label/paragraph/section/line) `Flag` for config saving. See the usage example above.

| Constructor       | Returns  | Extra options                                                           | Methods         |
| ----------------- | -------- | ----------------------------------------------------------------------- | --------------- |
| `CreateToggle`    | handle   | `CurrentValue` (bool), `Keybind` (string)                               | `:Set(v)` `:Get()` |
| `CreateSlider`    | handle   | `Min`, `Max`, `Default`, `Increment`, `Suffix`                          | `:Set(v)` `:Get()` |
| `CreateDropdown`  | handle   | `Options` (array), `MultiSelection` (bool), `CurrentOption`              | `:Set(v)` `:Get()` `:Refresh(opts, keepSel)` |
| `CreateKeybind`   | handle   | `CurrentKeybind` (name string, e.g. `"LeftControl"`, or mouse button)   | `:Set(v)` `:Get()` |
| `CreateButton`    | handle   |                                                                         | `:Set(text)`    |
| `CreateTextBox`   | handle   | `PlaceholderText`, `ClearTextOnFocus`                                   | `:Set(text)` `:Get()` `:Clear()` |
| `CreateLabel`     | handle   | `Text`                                                                  | `:Set(text)`    |
| `CreateParagraph` | handle   | `Title`, `Content`                                                      | `:Set({Title,Content})` |
| `CreateSection`   | —        | `Text`                                                                  | —               |
| `CreateLine`      | —        |                                                                         | —               |
| `CreateColorPicker` | handle | `Color`                                                                 | `:Set(color)` `:Get()` |

### Library-level methods

| Method                    | Description                                   |
| ------------------------- | --------------------------------------------- |
| `Library:Notify({Title,Content,Duration})` | Show a toast notification. |
| `Library:CreateNotify(...)` | Alias of `Notify`.                          |
| `Library:SaveConfig(name)` | Writes all `Flag` values to a `.json`.        |
| `Library:LoadConfig(name)` | Reads a config and applies values to elements. |
| `Library:DeleteConfig(name)` | Deletes a saved config file.                |
| `Library:ListConfigs()`    | Returns the saved config names.               |
| `Window:Destroy()` / `Library:Destroy()` | Full teardown (connections + instances). |

## Notes & quirks

- Re-running the script file is safe: the previous UI instance is destroyed before the new one is built.
- Config saving only writes elements that have a `Flag` set. Color values are stored as `{ "__c", r, g, b }` so they survive JSON.
- `firesignal` is a no-op on Real, so everything is driven by real input connections — buttons and toggles work the normal way.
- The UI is parented to `gethui()`, so it stays above the game and is not wiped on respawn (`ResetOnSpawn = false`).

## Troubleshooting

| Symptom | Fix |
| ------- | --- |
| The window never appears | Make sure the executor is injected and you're inside a game; check the console for non-`[Lib]` errors. |
| Config doesn't save | `ConfigurationSaving` must be `true`, elements need `Flag = "..."`, and the executor must expose `writefile`/`readfile`. |
| Callbacks not running on load | Callbacks fire on user interaction; `LoadConfig` applies values silently (no callback re-fire). |
| Double UI after updating the file | Re-running the script destroys the old instance automatically. If you changed the `ScreenGui` name, kill the old one with `getgenv().Library:Destroy()` in console. |

## License

Add a license file (e.g. MIT) before publishing. This README intentionally doesn't claim one for you.
