--[=[
	Nova Hub — ZenUI v3 example hub
	--------------------------------
	Loads ZenUI Apex v3.0 from this repository and exercises nearly every
	core + Apex control: toggles, sliders, dropdowns, keybinds, text boxes,
	buttons, color pickers, columns, segmented, stepper, progress, stat grid,
	status bar, context menu and command center.

	Run in any executor:
		loadstring(game:HttpGet("https://raw.githubusercontent.com/vxa-020/ZenUI/main/Demo.luau"))()
]=]

-- ============================================================ library
local Library = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/vxa-020/ZenUI/main/ZenUI.luau"
))()

local Lib = Library.new({
	Name = "Nova Hub",
	Theme = "Emerald",
	UIScale = 1.0,
})

local Window = Lib:CreateWindow({
	Name = "Nova Hub",
	ConfigurationSaving = true,
	ConfigFolder = "NovaHub",
	Keybind = Enum.KeyCode.Insert,
	DestroyOnClose = true, -- X fully tears down the UI and the demo
})

-- Cleanup everything the demo owns when the UI is destroyed (X button).
-- This is what makes the X button kill "the UI and other things".
-- DemoAlive and StatLoop are assigned later; nothing reads them until
-- Library.OnDestroy fires, by which point they exist.
local DemoAlive = true
local StatLoop: thread? = nil

-- ============================================================ globals
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local function CurrentCharacter()
	return LocalPlayer.Character
end

local function CurrentHumanoid()
	local char = CurrentCharacter()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function CurrentCamera()
	return Workspace.CurrentCamera
end

-- ============================================================ Main tab
local Main = Window:CreateTab({ Name = "Main", Icon = "home" })
Main:CreateInfoCard({
	Title = "Welcome to Nova Hub",
	Content = "Built on ZenUI Apex v3 — drag the window, cycle the 11 real themes, search tabs with Ctrl+K. Every setting below saves and loads through the built-in config system.",
})

-- Live telemetry cards
local StatGrid = Lib:CreateStatGrid(Main, {
	{ Name = "Players", Value = "—" },
	{ Name = "Ping", Value = "—" },
	{ Name = "FPS", Value = "—" },
	{ Name = "Uptime", Value = "0s" },
})

local StartTime = tick()
local RunService = game:GetService("RunService")

-- Frame counter: one cheap per-frame drain, separate from the 1 Hz stat loop.
local FrameCount = 0
local FpsConnection = RunService.RenderStepped:Connect(function()
	FrameCount = FrameCount + 1
end)

-- Single consolidated cleanup hook: X (DestroyOnClose) reaches this through
-- Library:Destroy(), which cancels the stat loop and the render counter.
Library.OnDestroy = function()
	DemoAlive = false
	if FpsConnection then pcall(function() FpsConnection:Disconnect() end) end
	if StatLoop then
		task.cancel(StatLoop)
		StatLoop = nil
	end
end

StatLoop = task.spawn(function()
	while DemoAlive do
		local ping = "—"
		pcall(function()
			ping = tostring(math.floor(0.9 * Players:GetNetworkPing() * 1000 + 0.5)) .. "ms"
		end)
		-- Rebuilding the grid once per second is fine; per frame it would not be.
		if StatGrid and StatGrid.SetValues then
			pcall(function()
				StatGrid:SetValues({
					{ Name = "Players", Value = tostring(#Players:GetPlayers()) },
					{ Name = "Ping", Value = ping },
					{ Name = "FPS", Value = tostring(FrameCount) },
					{ Name = "Uptime", Value = tostring(math.floor(tick() - StartTime)) .. "s" },
				})
			end)
		end
		FrameCount = 0
		task.wait(1)
	end
end)

-- Real theme selector (the v3 win: these palettes actually differ now)
Main:CreateSection({ Text = "Appearance" })
Main:CreateDropdown({
	Name = "Theme",
	CurrentOption = "Emerald",
	Options = { "Dark", "Light", "Emerald", "Midnight", "Blue", "Rose", "Ocean", "Amber", "Aurora", "Violet", "Mono" },
	Flag = "Theme",
	Callback = function(value)
		Lib:SetTheme(value)
	end,
})
Main:CreateColorPicker({
	Name = "Accent",
	Color = Lib.Theme.Accent,
	Flag = "Accent",
	Callback = function(color)
		Lib:SetAccentColor(color)
	end,
})
Main:CreateSlider({
	Name = "UI Scale",
	Min = 85,
	Max = 130,
	Default = math.floor(Lib.UIScale * 100 + 0.5),
	Increment = 1,
	Suffix = "%",
	Flag = "Scale",
	Callback = function(value)
		Window:SetScale(value / 100)
	end,
})

-- ============================================================ Combat tab
local Combat = Window:CreateTab({ Name = "Combat", Icon = "sword" })

local AuraToggle = Combat:CreateToggle({
	Name = "Aura",
	CurrentValue = false,
	Flag = "Aura",
	Callback = function(value)
		Lib:Notify({
			Title = "Aura",
			Content = value and "Aura enabled" or "Aura disabled",
			Duration = 2,
		})
	end,
})

Combat:CreateSlider({
	Name = "Aura Range",
	Min = 5,
	Max = 80,
	Default = 25,
	Increment = 1,
	Suffix = "st",
	Flag = "AuraRange",
	Callback = function(value)
		print("[NovaHub] aura range:", value)
	end,
})

Combat:CreateSegmented({
	Name = "Target Priority",
	Options = { "Nearest", "Lowest HP", "Random" },
	CurrentOption = "Nearest",
	Callback = function(value)
		print("[NovaHub] priority:", value)
	end,
})

Combat:CreateStepper({
	Name = "Max Targets",
	Min = 1,
	Max = 10,
	Step = 1,
	Default = 3,
	Flag = "MaxTargets",
	Callback = function(value)
		print("[NovaHub] max targets:", value)
	end,
})

local AuraKey = Combat:CreateKeybind({
	Name = "Aura Toggle Key",
	CurrentKeybind = "F",
	Flag = "AuraKey",
	Callback = function()
		AuraToggle:Set(not AuraToggle:Get())
	end,
})

Combat:CreateActionGroup({
	Actions = {
		{ Name = "Aura On", Callback = function() AuraToggle:Set(true) end },
		{ Name = "Aura Off", Callback = function() AuraToggle:Set(false) end },
		{ Name = "Notify Ping", Callback = function()
			Lib:Notify({ Title = "Ping", Content = "Still here.", Duration = 2 })
		end },
	},
})

Combat:CreateParagraph({
	Title = "Combat notes",
	Content = "This tab demonstrates toggles, sliders, segmented controls, steppers, keybinds and action groups. Replace the callbacks with your own logic.",
})

-- ============================================================ Movement tab
local Movement = Window:CreateTab({ Name = "Movement", Icon = "user" })

-- Pre-declared so the Speed Hack callback can capture them as upvalues
-- (a local referenced before its declaration would be a nil global).
local SpeedSlider: any = nil

local SpeedHackToggle = Movement:CreateToggle({
	Name = "Speed Hack",
	CurrentValue = false,
	Flag = "SpeedHack",
	Callback = function(value)
		local hum = CurrentHumanoid()
		if value then
			if hum and SpeedSlider then hum.WalkSpeed = SpeedSlider:Get() end
		else
			if hum then hum.WalkSpeed = 16 end
		end
	end,
})

SpeedSlider = Movement:CreateSlider({
	Name = "WalkSpeed",
	Min = 16,
	Max = 300,
	Default = 32,
	Increment = 1,
	Suffix = " ws",
	Flag = "WalkSpeed",
	Callback = function(value)
		if SpeedHackToggle:Get() then
			local hum = CurrentHumanoid()
			if hum then hum.WalkSpeed = value end
		end
	end,
})

local JumpSlider = Movement:CreateSlider({
	Name = "JumpPower",
	Min = 50,
	Max = 500,
	Default = 50,
	Increment = 1,
	Suffix = " jp",
	Flag = "JumpPower",
	Callback = function(value)
		local hum = CurrentHumanoid()
		if hum then hum.JumpPower = value end
	end,
})

Movement:CreateTextBox({
	Name = "WalkSpeed command",
	PlaceholderText = "e.g. 120",
	Callback = function(text)
		local n = tonumber(text)
		if n and SpeedSlider then
			SpeedSlider:Set(math.clamp(n, 16, 300))
			Lib:Notify({ Title = "Speed", Content = "WalkSpeed set to " .. n, Duration = 2 })
		end
	end,
})

Movement:CreateButton({
	Name = "Reset Character",
	Callback = function()
		if LocalPlayer and LocalPlayer.Character then
			LocalPlayer.Character:BreakJoints()
		end
	end,
})

-- ============================================================ Visuals tab
local Visuals = Window:CreateTab({ Name = "Visuals", Icon = "monitor" })

Visuals:CreateToggle({
	Name = "Fullbright",
	CurrentValue = false,
	Flag = "Fullbright",
	Callback = function(value)
		local lighting = game:GetService("Lighting")
		lighting.Ambient = value and Color3.new(1, 1, 1) or Color3.new(0.5, 0.5, 0.5)
	end,
})

Visuals:CreateSlider({
	Name = "Field of View",
	Min = 40,
	Max = 120,
	Default = 70,
	Increment = 1,
	Suffix = " fov",
	Flag = "FOV",
	Callback = function(value)
		local cam = CurrentCamera()
		if cam then cam.FieldOfView = value end
	end,
})

-- Pre-declared so the "Simulate load" button can reference it as an upvalue.
local LoadingProgress: any = nil

LoadingProgress = Visuals:CreateProgress({
	Name = "Loading assets",
	Max = 100,
	Value = 0,
})

Visuals:CreateButton({
	Name = "Simulate load",
	Callback = function()
		for i = 0, 100, 10 do
			LoadingProgress:Set(i)
			task.wait(0.05)
		end
	end,
})

-- ============================================================ Info tab
local Info = Window:CreateTab({ Name = "Info", Icon = "settings" })

Info:CreateParagraph({
	Title = "About ZenUI",
	Content = "ZenUI is a polished, animated Roblox/Luau UI library. v3 vendored the core into the repository, grew every control, added real theme palettes, gloss and fixed config/scale bugs.",
})

-- ============================================================ Apex surfaces
-- Command center: Ctrl+K style launcher on the main window
Lib:CreateCommandCenter({
	PlaceholderText = "Search actions...",
	Commands = {
		{ Name = "Toggle Aura", Callback = function() AuraToggle:Set(not AuraToggle:Get()) end },
		{ Name = "Cycle Theme", Callback = function() Window:CycleTheme() end },
		{ Name = "Minimize Window", Callback = function() Window:Minimize() end },
		{ Name = "Restore Window", Callback = function() Window:Restore() end },
		{ Name = "Notify Something", Callback = function()
			Lib:Notify({ Title = "Command Center", Content = "Action ran.", Duration = 2 })
		end },
	},
})

local StatusBar = Lib:CreateStatusBar({
	Text = "Ready",
})

StatusBar:Set("ZenUI v3 loaded", "success")