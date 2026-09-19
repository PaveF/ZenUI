--[=[
ZenUI Apex v3 Core — glass/neon edition
Copyright (c) 2026 PaveF. All rights reserved.

A polished Roblox/Luau UI library: constant-driven layout, glass panels
over a gradient backdrop, neon accents. Public API is stable:

  Library.new(settings) -> Lib
  Lib:CreateWindow(options) -> Window
  Window:CreateTab({Name,Icon,Badge}) -> Tab
  Tab:CreateToggle / CreateSlider / CreateDropdown / CreateKeybind /
     CreateTextBox / CreateButton / CreateLabel / CreateParagraph /
     CreateSection / CreateLine / CreateColorPicker / CreateColumns
  Lib:Notify, Lib:SetTheme, Lib:SetAccentColor, Lib:SaveConfig, ...

Window options: Name, Theme, AccentColor, UIScale, ConfigurationSaving,
ConfigFolder, Keybind, DestroyOnClose, Width, Height.
]=]

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local getgenvReal = (getgenv and getgenv) or function() return _G end
local ENV = getgenvReal()

-- ---------------------------------------------------------------- executor fs
local writefile = (type(ENV.writefile) == "function") and ENV.writefile or rawget(_G, "writefile")
local readfile = (type(ENV.readfile) == "function") and ENV.readfile or rawget(_G, "readfile")
local isfile = (type(ENV.isfile) == "function") and ENV.isfile or rawget(_G, "isfile")
local isfolder = (type(ENV.isfolder) == "function") and ENV.isfolder or rawget(_G, "isfolder")
local makefolder = (type(ENV.makefolder) == "function") and ENV.makefolder or rawget(_G, "makefolder")
local listfiles = (type(ENV.listfiles) == "function") and ENV.listfiles or rawget(_G, "listfiles")
local delfile = (type(ENV.delfile) == "function") and ENV.delfile or rawget(_G, "delfile")

local function safe_gethui()
	local ok, res = pcall(function() return getgenvReal().gethui() end)
	if ok and res then return res end
	ok, res = pcall(function() return getgenvReal().get_hidden_gui() end)
	if ok and res then return res end
	ok, res = pcall(function() return gethui() end)
	if ok and res then return res end
	return CoreGui:FindFirstChild("RobloxGui") or CoreGui
end

local function safe_call(func, ...)
	if type(func) ~= "function" then return false, nil end
	local results = { pcall(func, ...) }
	local ok = table.remove(results, 1)
	return ok, unpack(results)
end

-- ------------------------------------------------------------------ layout
-- Every hard placement derives from these constants. If a pixel is wrong,
-- it is wrong HERE, once, not scattered across a dozen copy-pasted offsets.
local LAYOUT = {
	WindowRadius = 20,
	WindowShadowPad = 36,
	WindowShadowDrop = 8,

	HeaderHeight = 76,
	HeaderTitleSize = 18,
	HeaderSubtitleSize = 12,

	SidebarWidth = 236,
	SidebarCollapsedWidth = 78,
	NavHeight = 50,
	NavRadius = 14,
	NavIconSize = 28,

	ContentTopHeight = 54,
	ContentTopRadius = 14,
	PageTopPadding = 16,

	SearchWidth = 300,
	SearchHeight = 40,

	CardRadius = 12,
	CardHeight = 46,
	SectionHeight = 30,

	ToggleSwitchW = 50,
	ToggleSwitchH = 28,
	ToggleKnob = 21,

	SliderHeight = 64,
	SliderTrackH = 8,
	SliderKnob = 18,

	DropdownHeight = 46,
	DropdownTopH = 44,
	DropdownOptionH = 30,

	KeybindHeight = 46,
	KeybindW = 116,

	TextBoxHeight = 48,
	TextBoxW = 164,

	ButtonHeight = 42,

	ColorPickerHeight = 46,
	ColorPickerSwatchW = 36,
	ColorPickerSVH = 130,
	ColorPickerHueH = 18,
	ColorPickerExpanded = 214,

	NotifyW = 340,
	NotifyH = 72,

	TabBarBottomPad = 116,
}

-- ------------------------------------------------------------------ themes
local function mix(a, b, t)
	return Color3.new(
		a.R + (b.R - a.R) * t,
		a.G + (b.G - a.G) * t,
		a.B + (b.B - a.B) * t
	)
end

local function darker(c, t) return mix(c, Color3.new(0, 0, 0), t) end
local function lighter(c, t) return mix(c, Color3.new(1, 1, 1), t) end

local baseDark = {
	Background = Color3.fromRGB(6, 8, 12),      -- window backdrop
	Sidebar = Color3.fromRGB(10, 13, 19),
	Element = Color3.fromRGB(16, 20, 28),      -- control cards
	ElementHover = Color3.fromRGB(24, 30, 40),
	Accent = Color3.fromRGB(78, 255, 185),
	Text = Color3.fromRGB(248, 250, 252),
	TextMuted = Color3.fromRGB(148, 156, 168),
	Border = Color3.fromRGB(48, 56, 70),
	Glow = Color3.fromRGB(200, 220, 235),
	Surface = Color3.fromRGB(12, 16, 23),
	SurfaceStrong = Color3.fromRGB(22, 28, 38),
	Glass = Color3.fromRGB(20, 26, 36),
}

local baseLight = {
	Background = Color3.fromRGB(240, 242, 245),
	Sidebar = Color3.fromRGB(232, 234, 238),
	Element = Color3.fromRGB(255, 255, 255),
	ElementHover = Color3.fromRGB(233, 236, 241),
	Accent = Color3.fromRGB(18, 22, 28),
	Text = Color3.fromRGB(22, 24, 28),
	TextMuted = Color3.fromRGB(105, 110, 120),
	Border = Color3.fromRGB(205, 209, 216),
	Glow = Color3.fromRGB(90, 100, 115),
	Surface = Color3.fromRGB(247, 248, 251),
	SurfaceStrong = Color3.fromRGB(238, 240, 244),
	Glass = Color3.fromRGB(250, 251, 253),
}

local Themes = {
	Dark = baseDark,
	Light = baseLight,
}

-- Named themes share the dark glass shell but carry their own accent pair,
-- so cycling themes actually does something visible now.
Themes.Emerald = table.clone(baseDark); Themes.Emerald.Accent = Color3.fromRGB(78, 255, 185)
Themes.Aurora = table.clone(baseDark); Themes.Aurora.Accent = Color3.fromRGB(170, 120, 255); Themes.Aurora.Glow = Color3.fromRGB(220, 190, 255)
Themes.Midnight = table.clone(baseDark); Themes.Midnight.Accent = Color3.fromRGB(120, 140, 255)
Themes.Ocean = table.clone(baseDark); Themes.Ocean.Accent = Color3.fromRGB(70, 220, 220)
Themes.Blue = table.clone(baseDark); Themes.Blue.Accent = Color3.fromRGB(80, 170, 255)
Themes.Violet = table.clone(baseDark); Themes.Violet.Accent = Color3.fromRGB(190, 130, 255)
Themes.Rose = table.clone(baseDark); Themes.Rose.Accent = Color3.fromRGB(255, 120, 170)
Themes.Amber = table.clone(baseDark); Themes.Amber.Accent = Color3.fromRGB(255, 180, 90)
Themes.Mono = table.clone(baseDark); Themes.Mono.Accent = Color3.fromRGB(245, 245, 247)

local ThemeNames = {
	"Dark", "Light", "Emerald", "Aurora", "Midnight", "Ocean",
	"Blue", "Violet", "Rose", "Amber", "Mono",
}

-- ------------------------------------------------------------------ fonts
local FontStandard = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local FontBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local TextMeasureFont = Enum.Font.Gotham

-- ------------------------------------------------------------------ library
local Library: { [string]: any } = {
	Debug = false,
	Instances = {},
	Connections = {},
	Flags = {},
	ConfigHandlers = {},
	Windows = {},
	ListeningKeybind = false,
	ScreenGui = nil,
	MainFrame = nil,
	ThemeName = "Emerald",
	Theme = table.clone(Themes.Emerald),
	Themes = Themes,
	CustomAccent = nil,
	UIScale = 1.00,
	ConfigFolder = "UI_Configs",
	ConfigurationSaving = false,
	OnDestroy = nil,
}

local Create

local function Log(...)
	if Library.Debug then
		print("[ZenUI]", ...)
	end
end

local function AddConnection(conn: RBXScriptConnection?)
	if conn then table.insert(Library.Connections, conn) end
	return conn
end

local function AddInstance(inst: Instance?)
	if inst then table.insert(Library.Instances, inst) end
	return inst
end

Create = function(className: string, properties: { [string]: any }): Instance
	local inst = Instance.new(className)
	for k, v in pairs(properties) do
		if k ~= "Parent" then
			pcall(function() inst[k] = v end)
		end
	end
	-- tag theme roles so SetTheme can repaint everything consistently
	pcall(function()
		for propName, value in pairs({
			BackgroundColor3 = properties.BackgroundColor3,
			TextColor3 = properties.TextColor3,
			PlaceholderColor3 = properties.PlaceholderColor3,
			ScrollBarImageColor3 = properties.ScrollBarImageColor3,
			Color = properties.Color,
		}) do
			if typeof(value) == "Color3" then
				for role, paletteValue in pairs(Library.Theme) do
					if typeof(paletteValue) == "Color3" and value == paletteValue then
						inst:SetAttribute("ZenThemeRole_" .. role, true)
					end
				end
			end
		end
	end)
	if properties.Parent then
		inst.Parent = properties.Parent
	end
	return inst
end

local function Stroke(parent, color, transparency, thickness)
	return Create("UIStroke", { Color = color or Library.Theme.Border, Transparency = transparency or 0.25, Thickness = thickness or 1, Parent = parent })
end

local function Corner(parent, radius)
	return Create("UICorner", { CornerRadius = UDim.new(0, radius or LAYOUT.CardRadius), Parent = parent })
end

local function Tween(instance: Instance?, properties: { [string]: any }, duration: number?)
	if not instance or instance.Parent == nil then return nil end
	local ok, t = pcall(function()
		return TweenService:Create(instance, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
	end)
	if not ok or not t then return nil end
	t:Play()
	return t
end

local function SpringTween(instance: Instance?, properties: { [string]: any }, duration: number?)
	if not instance or instance.Parent == nil then return nil end
	local ok, t = pcall(function()
		return TweenService:Create(instance, TweenInfo.new(duration or 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), properties)
	end)
	if not ok or not t then return nil end
	t:Play()
	return t
end

local function GlowDot(parent, size, position, color, transparency)
	local dot = Create("Frame", {
		Size = UDim2.new(0, size, 0, size),
		Position = position,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color or Library.Theme.Accent,
		BackgroundTransparency = transparency or 0.25,
		BorderSizePixel = 0,
		Parent = parent,
	})
	Corner(dot, size)
	return dot
end

-- -------------------------------------------------------------- icon system
local function MarkIconPart(inst: Instance)
	pcall(function() inst:SetAttribute("ZenIconPart", true) end)
	return inst
end

local function IconBar(parent: Instance, size: UDim2, position: UDim2, rotation: number?, color: Color3)
	local bar = Create("Frame", {
		Size = size,
		Position = position,
		Rotation = rotation or 0,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = parent,
	})
	return MarkIconPart(bar)
end

local function IconCircle(parent: Instance, size: UDim2, position: UDim2, color: Color3, stroked: boolean?)
	local circle = Create("Frame", {
		Size = size,
		Position = position,
		BackgroundColor3 = stroked and Library.Theme.Background or color,
		BackgroundTransparency = stroked and 1 or 0,
		BorderSizePixel = 0,
		Parent = parent,
	})
	Corner(circle, 99)
	if stroked then
		local st = Create("UIStroke", { Color = color, Thickness = 1.6, Transparency = 0, Parent = circle })
		MarkIconPart(st)
	end
	return MarkIconPart(circle)
end

local function CreateIcon(parent: Instance, iconName: string?, color: Color3?)
	local icon = Create("Frame", {
		Size = UDim2.new(0, 28, 0, 28),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = parent,
	})
	local iconColor = color or Library.Theme.TextMuted
	local name = string.lower(tostring(iconName or "menu"))

	if name == "home" then
		IconBar(icon, UDim2.new(0, 12, 0, 9), UDim2.new(0, 8, 0, 10), 0, iconColor)
		local roofL = IconBar(icon, UDim2.new(0, 10, 0, 2), UDim2.new(0, 6, 0, 8), -42, iconColor)
		local roofR = IconBar(icon, UDim2.new(0, 10, 0, 2), UDim2.new(0, 12, 0, 2), 42, iconColor)
		IconBar(icon, UDim2.new(0, 3, 0, 6), UDim2.new(0, 12, 0, 13), 0, Library.Theme.Background)
	elseif name == "user" or name == "player" then
		IconCircle(icon, UDim2.new(0, 7, 0, 7), UDim2.new(0, 10.5, 0, 3), iconColor, false)
		local body = IconBar(icon, UDim2.new(0, 14, 0, 9), UDim2.new(0, 7, 0, 12), 0, iconColor)
		Corner(body, 7)
	elseif name == "users" then
		IconCircle(icon, UDim2.new(0, 6, 0, 6), UDim2.new(0, 5, 0, 4), iconColor, false)
		IconCircle(icon, UDim2.new(0, 6, 0, 6), UDim2.new(0, 16, 0, 6), iconColor, false)
		local b1 = IconBar(icon, UDim2.new(0, 10, 0, 8), UDim2.new(0, 3, 0, 13), 0, iconColor); Corner(b1, 6)
		local b2 = IconBar(icon, UDim2.new(0, 9, 0, 7), UDim2.new(0, 14, 0, 14), 0, iconColor); Corner(b2, 6)
	elseif name == "settings" or name == "gear" then
		IconCircle(icon, UDim2.new(0, 13, 0, 13), UDim2.new(0, 7.5, 0, 7.5), iconColor, true)
		IconCircle(icon, UDim2.new(0, 5, 0, 5), UDim2.new(0, 11.5, 0, 11.5), iconColor, true)
		for _, cfg in ipairs({ { 10, 2, 0 }, { 10, 14, 0 }, { 2, 10, 90 }, { 14, 10, 90 } }) do
			IconBar(icon, UDim2.new(0, 5, 0, 2), UDim2.new(0, cfg[1], 0, cfg[2]), cfg[3], iconColor)
		end
	elseif name == "target" or name == "crosshair" then
		IconCircle(icon, UDim2.new(0, 17, 0, 17), UDim2.new(0, 5.5, 0, 5.5), iconColor, true)
		IconCircle(icon, UDim2.new(0, 9, 0, 9), UDim2.new(0, 9.5, 0, 9.5), iconColor, true)
		IconBar(icon, UDim2.new(0, 20, 0, 1), UDim2.new(0, 4, 0, 13.5), 0, iconColor)
		IconBar(icon, UDim2.new(0, 1, 0, 20), UDim2.new(0, 13.5, 0, 4), 0, iconColor)
	elseif name == "sword" or name == "combat" then
		IconBar(icon, UDim2.new(0, 18, 0, 3), UDim2.new(0, 5, 0, 9), 45, iconColor)
		IconBar(icon, UDim2.new(0, 3, 0, 8), UDim2.new(0, 9, 0, 15), 45, iconColor)
		IconBar(icon, UDim2.new(0, 10, 0, 2), UDim2.new(0, 8, 0, 15), 45, iconColor)
	elseif name == "shield" then
		local sh = Create("Frame", { Size = UDim2.new(0, 14, 0, 16), Position = UDim2.new(0, 7, 0, 5), BackgroundColor3 = iconColor, BorderSizePixel = 0, Parent = icon })
		Corner(sh, 5); MarkIconPart(sh)
		local cut = Create("Frame", { Size = UDim2.new(0, 10, 0, 12), Position = UDim2.new(0, 9, 0, 7), BackgroundColor3 = Library.Theme.Background, BorderSizePixel = 0, Parent = icon })
		Corner(cut, 4); MarkIconPart(cut)
		IconBar(icon, UDim2.new(0, 5, 0, 2), UDim2.new(0, 11.5, 0, 11), 0, iconColor)
	elseif name == "monitor" or name == "desktop" then
		local mon = Create("Frame", { Size = UDim2.new(0, 18, 0, 12), Position = UDim2.new(0, 5, 0, 4), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = icon })
		Corner(mon, 3)
		local st = Create("UIStroke", { Color = iconColor, Thickness = 1.7, Parent = mon }); MarkIconPart(st); MarkIconPart(mon)
		IconBar(icon, UDim2.new(0, 2, 0, 5), UDim2.new(0, 13, 0, 16), 0, iconColor)
		IconBar(icon, UDim2.new(0, 10, 0, 2), UDim2.new(0, 9, 0, 20), 0, iconColor)
	elseif name == "folder" then
		local f = Create("Frame", { Size = UDim2.new(0, 18, 0, 13), Position = UDim2.new(0, 5, 0, 7), BackgroundColor3 = iconColor, BorderSizePixel = 0, Parent = icon })
		Corner(f, 4); MarkIconPart(f)
		local notch = Create("Frame", { Size = UDim2.new(0, 7, 0, 3), Position = UDim2.new(0, 6, 0, 5), BackgroundColor3 = Library.Theme.Background, BorderSizePixel = 0, Parent = icon })
		Corner(notch, 2); MarkIconPart(notch)
		pcall(function() notch:SetAttribute("ZenIconCutout", true) end)
	elseif name == "code" then
		IconBar(icon, UDim2.new(0, 9, 0, 2), UDim2.new(0, 3, 0, 11), -40, iconColor)
		IconBar(icon, UDim2.new(0, 9, 0, 2), UDim2.new(0, 15, 0, 16), -40, iconColor)
		IconBar(icon, UDim2.new(0, 8, 0, 2), UDim2.new(0, 10, 0, 5), 90, iconColor)
	elseif name == "up" or name == "expand" or name == "restore" then
		IconBar(icon, UDim2.new(0, 14, 0, 2), UDim2.new(0, 7, 0, 18), 0, iconColor)
		IconBar(icon, UDim2.new(0, 14, 0, 2), UDim2.new(0, 7, 0, 12), 0, iconColor)
		IconCircle(icon, UDim2.new(0, 9, 0, 9), UDim2.new(0, 9.5, 0, 3), iconColor, true)
	else
		for y = 7, 17, 5 do
			IconBar(icon, UDim2.new(0, 14, 0, 2), UDim2.new(0, 7, 0, y), 0, iconColor)
		end
	end
	return icon
end

local function SetIconColor(icon: GuiObject, color: Color3)
	if not icon then return end
	for _, inst in ipairs(icon:GetDescendants()) do
		if inst:GetAttribute("ZenIconPart") then
			if inst:IsA("UIStroke") then
				Tween(inst, { Color = color }, 0.14)
			elseif inst:IsA("Frame") then
				if not inst:GetAttribute("ZenIconCutout") then
					Tween(inst, { BackgroundColor3 = color }, 0.14)
				end
			end
		end
	end
end-- ------------------------------------------------------------------ theme
local function ThemeColor(role: string): Color3
	return Library.Theme[role] or Library.Theme.Background
end

local function RepaintIcons(root)
	for _, inst in ipairs(root:GetDescendants()) do
		if inst:GetAttribute("ZenIconPart") then
			pcall(function()
				if inst:IsA("UIStroke") then
					inst.Color = Library.Theme.TextMuted
				elseif inst:IsA("Frame") then
					inst.BackgroundColor3 = Library.Theme.TextMuted
				end
			end)
		end
	end
end

function Library:SetTheme(name)
	local palette = Themes[name]
	if not palette then return false end
	Library.ThemeName = name
	Library.Theme = table.clone(palette)
	if Library.CustomAccent then
		Library.Theme.Accent = Library.CustomAccent
	end
	local root = Library.ScreenGui
	if root then
		pcall(function()
			local mw = root:FindFirstChild("MainWindow")
			local gradient = mw and mw:FindFirstChildOfClass("UIGradient")
			if gradient and gradient:GetAttribute("ZenGradient") then
				gradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, palette.SurfaceStrong),
					ColorSequenceKeypoint.new(0.5, palette.Background),
					ColorSequenceKeypoint.new(1, palette.Sidebar),
				})
			end
		end)
		for _, inst in ipairs(root:GetDescendants()) do
			if inst:GetAttribute("ZenIconPart") then
				pcall(function()
					if inst:IsA("UIStroke") then inst.Color = palette.TextMuted
					elseif inst:IsA("Frame") then inst.BackgroundColor3 = palette.TextMuted end
				end)
			end
			for role, value in pairs(palette) do
				if typeof(value) == "Color3" and inst:GetAttribute("ZenThemeRole_" .. role) then
					pcall(function()
						if inst:IsA("UIStroke") then
							inst.Color = value
						elseif inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
							if role == "Text" or role == "TextMuted" then inst.TextColor3 = value end
							if role == "TextMuted" then pcall(function() inst.PlaceholderColor3 = value end) end
						else
							inst.BackgroundColor3 = value
						end
					end)
				end
			end
		end
	end
	return true
end

function Library:GetThemes()
	local out = {}
	for _, name in ipairs(ThemeNames) do
		table.insert(out, name)
	end
	return out
end

function Library:GetTheme()
	return Library.ThemeName
end

function Library:SetAccentColor(color: Color3)
	if typeof(color) ~= "Color3" then return end
	Library.CustomAccent = color
	Library.Theme.Accent = color
	local root = Library.ScreenGui
	if not root then return end
	for _, inst in ipairs(root:GetDescendants()) do
		if inst:GetAttribute("ZenThemeRole_Accent") then
			pcall(function() inst.BackgroundColor3 = color end)
			pcall(function() inst.TextColor3 = color end)
			pcall(function() inst.ImageColor3 = color end)
			pcall(function() inst.Color = color end)
		end
	end
end

function Library:ResetAccentColor()
	Library.CustomAccent = nil
	Library:SetTheme(Library.ThemeName)
end

function Library:Destroy()
	Log("Destroying UI instance...")
	if type(self.OnDestroy) == "function" then
		pcall(self.OnDestroy)
	end
	self.OnDestroy = nil
	if type(self.DestroyExtensions) == "function" then
		pcall(function() self:DestroyExtensions() end)
	end
	for _, conn in ipairs(self.Connections) do
		if conn and typeof(conn) == "RBXScriptConnection" then
			pcall(function() conn:Disconnect() end)
		end
	end
	table.clear(self.Connections)
	for _, inst in ipairs(self.Instances) do
		if inst and typeof(inst) == "Instance" then
			pcall(function() inst:Destroy() end)
		end
	end
	table.clear(self.Instances)
	table.clear(self.Flags)
	table.clear(self.ConfigHandlers)
	table.clear(self.Windows)
	self.ScreenGui = nil
	self.MainFrame = nil
	self.ListeningKeybind = false
	pcall(function()
		ENV.Library = nil
	end)
	Log("destroyed")
end

-- clean any previous ZenUI instance on reload
if getgenvReal().Library and type(getgenvReal().Library.Destroy) == "function" then
	pcall(function() getgenvReal().Library:Destroy() end)
end

pcall(function()
	local guiParent = safe_gethui()
	for _, child in ipairs(guiParent:GetChildren()) do
		if child:IsA("ScreenGui") and child.Name == "ZenUI" then
			child:Destroy()
		end
	end
end)

ENV.Library = Library

function Library.new(settings)
	settings = settings or {}
	if Library.ScreenGui then
		Library:Destroy()
	end
	Library.Debug = settings.Debug or false
	Library.CustomAccent = typeof(settings.AccentColor) == "Color3" and settings.AccentColor or nil
	Library.UIScale = math.clamp(tonumber(settings.UIScale) or 1.00, 0.85, 1.30)
	Library:SetTheme(settings.Theme or "Emerald")

	local guiParent = safe_gethui()
	local ScreenGui = Create("ScreenGui", {
		Name = "ZenUI",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = guiParent,
	})
	AddInstance(ScreenGui)
	Library.ScreenGui = ScreenGui

	local NotificationContainer = Create("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -LAYOUT.NotifyW - 24, 1, -24),
		Size = UDim2.new(0, LAYOUT.NotifyW, 1, 0),
		AnchorPoint = Vector2.new(0, 1),
		Parent = ScreenGui,
	})
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 10),
		Parent = NotificationContainer,
	})
	Library.NotificationContainer = NotificationContainer

	-- ------------------------------------------------------ glass loading
	local LoadingFrame = Create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Library.Theme.Background,
		BackgroundTransparency = 1,
		Parent = ScreenGui,
		ZIndex = 100,
	})
	local LoadingText = Create("TextLabel", {
		Size = UDim2.new(0, 320, 0, 46),
		Position = UDim2.new(0.5, -160, 0.5, -40),
		BackgroundTransparency = 1,
		Text = settings.Name or "ZenUI",
		TextColor3 = Library.Theme.Text,
		TextTransparency = 1,
		FontFace = FontBold,
		TextSize = 30,
		Parent = LoadingFrame,
	})
	local LoadingGlow = Create("Frame", {
		Size = UDim2.new(0, 80, 0, 3),
		Position = UDim2.new(0.5, -40, 0.5, 14),
		BackgroundColor3 = Library.Theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = LoadingFrame,
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = LoadingGlow })

	task.spawn(function()
		pcall(function()
			Tween(LoadingFrame, { BackgroundTransparency = 0 }, 0.3)
			Tween(LoadingText, { TextTransparency = 0 }, 0.35)
			Tween(LoadingGlow, { BackgroundTransparency = 0.3 }, 0.5)
			Tween(LoadingGlow, { Size = UDim2.new(0, 260, 0, 3) }, 0.9)
			task.wait(1.1)
			Tween(LoadingFrame, { BackgroundTransparency = 1 }, 0.3)
			Tween(LoadingText, { TextTransparency = 1 }, 0.3)
			Tween(LoadingGlow, { BackgroundTransparency = 1 }, 0.3)
			task.wait(0.3)
			if LoadingFrame.Parent then LoadingFrame:Destroy() end
		end)
	end)

	Log("loaded OK")
	return Library
end

-- ------------------------------------------------------------------ config
local function serialize(v)
	local t = typeof(v)
	if t == "Color3" then
		return { "__c", v.R, v.G, v.B }
	elseif t == "table" then
		local out = {}
		for k, val in pairs(v) do
			out[k] = serialize(val)
		end
		return out
	end
	return v
end

local function deserialize(v)
	if type(v) == "table" then
		if v[1] == "__c" then
			return Color3.new(v[2], v[3], v[4])
		end
		local out = {}
		for k, val in pairs(v) do
			out[k] = deserialize(val)
		end
		return out
	end
	return v
end

local function WriteConfig(name)
	if not Library.ConfigurationSaving then return end
	if type(writefile) ~= "function" then return end
	local ok_folder, has_folder = safe_call(isfolder, Library.ConfigFolder)
	if ok_folder and not has_folder then
		safe_call(makefolder, Library.ConfigFolder)
	end
	local path = tostring(Library.ConfigFolder) .. "/" .. tostring(name) .. ".json"
	local data = {}
	for flag, value in pairs(Library.Flags) do
		data[flag] = serialize(value)
	end
	local ok_encode, json = pcall(function() return HttpService:JSONEncode(data) end)
	if ok_encode and type(json) == "string" then
		safe_call(writefile, path, json)
	end
end

local function LoadConfig(name)
	if not Library.ConfigurationSaving then return end
	if type(readfile) ~= "function" then return end
	local path = tostring(Library.ConfigFolder) .. "/" .. tostring(name) .. ".json"
	local ok_file, has_file = safe_call(isfile, path)
	if not (ok_file and has_file) then return end
	local ok_read, content = safe_call(readfile, path)
	if ok_read and type(content) == "string" then
		local ok_dec, data = pcall(function() return HttpService:JSONDecode(content) end)
		if ok_dec and type(data) == "table" then
			for flag, value in pairs(data) do
				local realValue = deserialize(value)
				Library.Flags[flag] = realValue
				local handler = Library.ConfigHandlers[flag]
				if handler then
					pcall(handler, realValue)
				end
			end
		end
	end
end

function Library:SaveConfig(name) WriteConfig(name) end
function Library:LoadConfig(name) LoadConfig(name) end

function Library:DeleteConfig(name)
	if type(delfile) ~= "function" then return end
	local path = tostring(Library.ConfigFolder) .. "/" .. tostring(name) .. ".json"
	safe_call(delfile, path)
end

function Library:ListConfigs()
	if type(listfiles) ~= "function" or type(isfolder) ~= "function" then return {} end
	local ok_folder, has_folder = safe_call(isfolder, Library.ConfigFolder)
	if ok_folder and not has_folder then return {} end
	if ok_folder then
		local ok, files = safe_call(listfiles, Library.ConfigFolder)
		if ok and type(files) == "table" then
			local out = {}
			for _, f in ipairs(files) do
				table.insert(out, tostring(f):match("([^/\\]+)%.json$") or tostring(f))
			end
			return out
		end
	end
	return {}
end-- ------------------------------------------------------------------ helpers
local function CardMotion(card: GuiObject, hoverColor: Color3?)
	if not card then return end
	card.Active = true
	local scale = card:FindFirstChildOfClass("UIScale") or Create("UIScale", { Scale = 1, Parent = card })
	local base = card.BackgroundColor3
	AddConnection(card.MouseEnter:Connect(function()
		SpringTween(scale, { Scale = 1.012 }, 0.18)
		if card.BackgroundTransparency < 1 then
			Tween(card, { BackgroundColor3 = hoverColor or Library.Theme.ElementHover }, 0.16)
		end
	end))
	AddConnection(card.MouseLeave:Connect(function()
		SpringTween(scale, { Scale = 1 }, 0.16)
		if card.BackgroundTransparency < 1 then
			Tween(card, { BackgroundColor3 = base }, 0.18)
		end
	end))
end

local function CardSheen(card: GuiObject)
	if not card or card:FindFirstChild("ZenSheen") then return end
	local sheen = Create("Frame", {
		Name = "ZenSheen",
		Size = UDim2.new(0, 90, 1.6, 0),
		Position = UDim2.new(-1, 0, -0.3, 0),
		Rotation = 18,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		ZIndex = (card.ZIndex or 1) + 1,
		Visible = false,
		Parent = card,
	})
	Create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.25),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = sheen,
	})
	AddConnection(card.MouseEnter:Connect(function()
		if card.Visible == false or card.AbsoluteSize.X < 40 then return end
		sheen.Visible = true
		sheen.Position = UDim2.new(-1, 0, -0.3, 0)
		Tween(sheen, { Position = UDim2.new(1.3, 0, -0.3, 0) }, 0.5, Enum.EasingStyle.Quad)
	end))
	AddConnection(card.MouseLeave:Connect(function()
		sheen.Visible = false
	end))
	return sheen
end

local function WindowShadow(target: GuiObject, parent: Instance, mainScale: UIScale?)
	local shadow = Create("Frame", {
		Name = "ZenShadow",
		Size = UDim2.new(target.Size.X.Scale, target.Size.X.Offset + LAYOUT.WindowShadowPad, target.Size.Y.Scale, target.Size.Y.Offset + LAYOUT.WindowShadowPad),
		Position = UDim2.new(target.Position.X.Scale, target.Position.X.Offset, target.Position.Y.Scale, target.Position.Y.Offset + LAYOUT.WindowShadowDrop),
		AnchorPoint = target.AnchorPoint,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = parent,
	})
	Corner(shadow, LAYOUT.WindowRadius + 2)
	local shadowScale: UIScale? = nil
	if mainScale then
		shadowScale = Create("UIScale", { Scale = mainScale.Scale, Parent = shadow })
	end
	AddConnection(target:GetPropertyChangedSignal("Position"):Connect(function()
		shadow.Position = UDim2.new(target.Position.X.Scale, target.Position.X.Offset, target.Position.Y.Scale, target.Position.Y.Offset + LAYOUT.WindowShadowDrop)
	end))
	AddConnection(target:GetPropertyChangedSignal("Size"):Connect(function()
		shadow.Size = UDim2.new(target.Size.X.Scale, target.Size.X.Offset + LAYOUT.WindowShadowPad, target.Size.Y.Scale, target.Size.Y.Offset + LAYOUT.WindowShadowPad)
	end))
	AddConnection(target:GetPropertyChangedSignal("Visible"):Connect(function()
		shadow.Visible = target.Visible
	end))
	if mainScale and shadowScale then
		AddConnection(mainScale:GetPropertyChangedSignal("Scale"):Connect(function()
			shadowScale.Scale = mainScale.Scale
		end))
	end
	return shadow
end

local function AddAccentRail(parent: GuiObject, height)
	local rail = Create("Frame", {
		Size = UDim2.new(0, 3, 0, height or 20),
		Position = UDim2.new(0, 0, 0.5, -(height or 20) / 2),
		BackgroundColor3 = Library.Theme.Accent,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Parent = parent,
	})
	Corner(rail, 2)
	return rail
end

-- ------------------------------------------------------------------ window
function Library:CreateWindow(options)
	options = options or {}
	if Library.MainFrame then
		Library:Destroy()
	end

	local Window: { [string]: any } = {
		Tabs = {},
		CurrentTab = nil,
		Elements = {},
		Columns = {},
	}

	Library.ConfigurationSaving = options.ConfigurationSaving or false
	Library.ConfigFolder = options.ConfigFolder or "UI_Configs"
	local ToggleKeybind = options.Keybind or Enum.KeyCode.Insert

	local BaseWindowWidth = math.clamp(tonumber(options.Width) or 1100, 900, 1600)
	local BaseWindowHeight = math.clamp(tonumber(options.Height) or 640, 560, 980)
	local MinWindowWidth, MaxWindowWidth = 900, 1600
	local MinWindowHeight, MaxWindowHeight = 560, 980

	-- ------------------------------------------------------------ frame
	local MainFrame = Create("Frame", {
		Name = "MainWindow",
		Size = UDim2.new(0, BaseWindowWidth, 0, BaseWindowHeight),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = Library.Theme.Background,
		ClipsDescendants = true,
		BackgroundTransparency = 0,
		ZIndex = 5,
		Parent = Library.ScreenGui,
	})
	AddInstance(MainFrame)
	Library.MainFrame = MainFrame
	Corner(MainFrame, LAYOUT.WindowRadius)
	Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1.2, Transparency = 0.75, Parent = MainFrame })

	local WindowGradient = Create("UIGradient", {
		Rotation = 135,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Library.Theme.SurfaceStrong),
			ColorSequenceKeypoint.new(0.5, Library.Theme.Background),
			ColorSequenceKeypoint.new(1, Library.Theme.Sidebar),
		}),
		Parent = MainFrame,
	})
	pcall(function() WindowGradient:SetAttribute("ZenGradient", true) end)

	local MainScale = Create("UIScale", { Scale = Library.UIScale, Parent = MainFrame })
	WindowShadow(MainFrame, Library.ScreenGui, MainScale)

	-- ------------------------------------------------------------ header
	local Header = Create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, LAYOUT.HeaderHeight),
		BackgroundTransparency = 1,
		Active = true,
		ClipsDescendants = true,
		Parent = MainFrame,
	})
	local HeaderGlowHeader = Create("Frame", { Size = UDim2.new(1, 0, 0, LAYOUT.HeaderHeight), BackgroundColor3 = Library.Theme.SurfaceStrong, BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = Header })
	Create("UIGradient", {
		Rotation = 0,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Library.Theme.SurfaceStrong),
			ColorSequenceKeypoint.new(1, Library.Theme.Surface),
		}),
		Transparency = NumberSequence.new(0.45),
		Parent = HeaderGlowHeader,
	})
	Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.8, Parent = HeaderGlowHeader })

	-- drag
	local dragInput, dragging, dragStart, startPos
	local function IsOverGui(guiObject, pos)
		if not guiObject or not guiObject.Visible then return false end
		local p, z = guiObject.AbsolutePosition, guiObject.AbsoluteSize
		return pos.X >= p.X and pos.X <= p.X + z.X and pos.Y >= p.Y and pos.Y <= p.Y + z.Y
	end

	-- brand block: icon tile + name + subtitle
	local BrandTile = Create("Frame", {
		Size = UDim2.new(0, 42, 0, 42),
		Position = UDim2.new(0, 16, 0.5, -21),
		BackgroundColor3 = Library.Theme.Element,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = Header,
	})
	Corner(BrandTile, 12)
	Create("UIStroke", { Color = Library.Theme.Accent, Thickness = 1.4, Transparency = 0.55, Parent = BrandTile })
	local BrandIcon = CreateIcon(BrandTile, options.Icon or "home", Library.Theme.Accent)
	BrandIcon.Size = UDim2.new(0, 24, 0, 24)
	BrandIcon.Position = UDim2.new(0.5, -12, 0.5, -12)

	local Title = Create("TextLabel", {
		Size = UDim2.new(0, 260, 0, 24),
		Position = UDim2.new(0, 68, 0, 12),
		BackgroundTransparency = 1,
		Text = options.Name or "ZenUI",
		TextColor3 = Library.Theme.Text,
		FontFace = FontBold,
		TextSize = LAYOUT.HeaderTitleSize,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Header,
	})
	local Subtitle = Create("TextLabel", {
		Size = UDim2.new(0, 260, 0, 17),
		Position = UDim2.new(0, 68, 0, 38),
		BackgroundTransparency = 1,
		Text = "Roblox command control",
		TextColor3 = Library.Theme.TextMuted,
		FontFace = FontStandard,
		TextSize = LAYOUT.HeaderSubtitleSize,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Header,
	})

	-- search
	local SearchBox = Create("TextBox", {
		Name = "CommandSearch",
		Size = UDim2.new(0, LAYOUT.SearchWidth, 0, LAYOUT.SearchHeight),
		Position = UDim2.new(0.5, -LAYOUT.SearchWidth / 2, 0.5, -LAYOUT.SearchHeight / 2),
		BackgroundColor3 = Library.Theme.Element,
		BackgroundTransparency = 0.15,
		Text = "",
		PlaceholderText = "Search tabs...   Ctrl + K",
		TextColor3 = Library.Theme.Text,
		PlaceholderColor3 = Library.Theme.TextMuted,
		ClearTextOnFocus = false,
		FontFace = FontStandard,
		TextSize = 13,
		Parent = Header,
	})
	Corner(SearchBox, 11)
	Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.6, Parent = SearchBox })
	local SearchGlow = Create("Frame", { Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = Library.Theme.Accent, BackgroundTransparency = 0.85, BorderSizePixel = 0, Parent = SearchBox })
	Corner(SearchGlow, 2)

	-- ambient shadow breathing under the header
	local HeaderGlow = Create("Frame", { Name = "ZenHeaderGlow", Size = UDim2.new(1, -48, 0, 2), Position = UDim2.new(0, 24, 1, -2), BackgroundColor3 = Library.Theme.Accent, BackgroundTransparency = 0.25, BorderSizePixel = 0, Parent = Header })
	task.spawn(function()
		while HeaderGlow.Parent do
			Tween(HeaderGlow, { BackgroundTransparency = 0.55 }, 1.1)
			task.wait(1.1)
			Tween(HeaderGlow, { BackgroundTransparency = 0.2 }, 1.1)
			task.wait(1.1)
		end
	end)

	-- header buttons
	local MinimizeButton, CloseButton
	local function MakeHeaderButton(name, text, xOffset)
		local b = Create("TextButton", {
			Name = name, Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(1, xOffset, 0.5, -19),
			BackgroundColor3 = Library.Theme.Element, Text = "", TextColor3 = Library.Theme.TextMuted,
			AutoButtonColor = false, Parent = Header,
		})
		Corner(b, 11)
		Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.55, Parent = b })
		if name == "Close" then
			local x1 = Create("Frame", { Size = UDim2.new(0, 15, 0, 2.2), Position = UDim2.new(0.5, -7.5, 0.5, -1.1), Rotation = 45, BackgroundColor3 = Library.Theme.TextMuted, BorderSizePixel = 0, Parent = b })
			local x2 = Create("Frame", { Size = UDim2.new(0, 15, 0, 2.2), Position = UDim2.new(0.5, -7.5, 0.5, -1.1), Rotation = -45, BackgroundColor3 = Library.Theme.TextMuted, BorderSizePixel = 0, Parent = b })
			Corner(x1, 2); Corner(x2, 2)
		else
			Create("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Library.Theme.TextMuted, FontFace = FontBold, TextSize = 16, Parent = b })
		end
		AddConnection(b.MouseEnter:Connect(function()
			SpringTween(b, { Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(1, xOffset - 1, 0.5, -20), BackgroundColor3 = Library.Theme.ElementHover }, 0.16)
		end))
		AddConnection(b.MouseLeave:Connect(function()
			Tween(b, { Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(1, xOffset, 0.5, -19), BackgroundColor3 = Library.Theme.Element }, 0.14)
		end))
		return b
	end

	local ThemeButton = MakeHeaderButton("Theme", "◌", -166)
	MinimizeButton = MakeHeaderButton("Minimize", "—", -117)
	CloseButton = MakeHeaderButton("Close", "×", -68)

	local function CycleTheme()
		local names = Library:GetThemes()
		local idx = table.find(names, Library.ThemeName) or 1
		Library:SetTheme(names[(idx % #names) + 1])
	end
	AddConnection(ThemeButton.MouseButton1Click:Connect(CycleTheme))
	AddConnection(SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local query = string.lower(SearchBox.Text or "")
		for _, entry in ipairs(Window.Tabs) do
			entry.Button.Visible = query == "" or string.find(string.lower(entry.Name), query, 1, true) ~= nil
		end
	end))

	AddConnection(Header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if IsOverGui(MinimizeButton, input.Position) or IsOverGui(CloseButton, input.Position) or IsOverGui(SearchBox, input.Position) then return end
			dragging, dragStart, startPos = true, input.Position, MainFrame.Position
		end
	end))
	AddConnection(Header.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
	end))
	AddConnection(UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging and startPos then
			local d = input.Position - dragStart
			MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end))
	AddConnection(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end))-- ------------------------------------------------------------ sidebar
	local SidebarWidth = LAYOUT.SidebarWidth
	local Sidebar = Create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, SidebarWidth, 1, -LAYOUT.HeaderHeight),
		Position = UDim2.new(0, 0, 0, LAYOUT.HeaderHeight),
		BackgroundColor3 = Library.Theme.Sidebar,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Parent = MainFrame,
	})
	local SidebarGlass = Create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Library.Theme.Sidebar),
			ColorSequenceKeypoint.new(1, darker(Library.Theme.Sidebar, 0.12)),
		}),
		Transparency = NumberSequence.new(0.25),
		Parent = Sidebar,
	})
	Corner(Sidebar, 12)

	local NavLabel = Create("TextLabel", {
		Size = UDim2.new(1, -32, 0, 18),
		Position = UDim2.new(0, 16, 0, 10),
		BackgroundTransparency = 1,
		Text = "NAVIGATION",
		TextColor3 = Library.Theme.TextMuted,
		FontFace = FontBold,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Sidebar,
	})

	local TabContainer = Create("ScrollingFrame", {
		Name = "TabContainer",
		Size = UDim2.new(1, -12, 1, -LAYOUT.TabBarBottomPad),
		Position = UDim2.new(0, 6, 0, 32),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = Sidebar,
	})
	local TabListLayout = Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = TabContainer,
	})
	AddConnection(TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TabContainer.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y + 10)
	end))

	local CollapseButton = Create("TextButton", {
		Name = "CollapseButton",
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -40, 0, 6),
		BackgroundColor3 = Library.Theme.Element,
		Text = "‹",
		TextColor3 = Library.Theme.TextMuted,
		FontFace = FontBold,
		TextSize = 18,
		AutoButtonColor = false,
		Parent = Sidebar,
	})
	Corner(CollapseButton, 9)
	Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.55, Parent = CollapseButton })
	local Collapsed = false

	-- player footer
	local SidebarFooter = Create("Frame", {
		Name = "PlayerProfile",
		Size = UDim2.new(1, -24, 0, 64),
		Position = UDim2.new(0, 12, 1, -76),
		BackgroundColor3 = Library.Theme.SurfaceStrong,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = Sidebar,
	})
	Corner(SidebarFooter, 12)
	Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.6, Parent = SidebarFooter })
	local ProfileAccent = Create("Frame", {
		Size = UDim2.new(0, 3, 0, 32),
		Position = UDim2.new(0, 5, 0.5, -16),
		BackgroundColor3 = Library.Theme.Accent,
		BorderSizePixel = 0,
		Parent = SidebarFooter,
	})
	Corner(ProfileAccent, 2)

	local ProfileAvatar = Create("ImageLabel", {
		Name = "Avatar",
		Size = UDim2.new(0, 42, 0, 42),
		Position = UDim2.new(0, 14, 0.5, -21),
		BackgroundColor3 = Library.Theme.Element,
		BackgroundTransparency = 0,
		Image = "",
		ScaleType = Enum.ScaleType.Crop,
		Parent = SidebarFooter,
	})
	Corner(ProfileAvatar, 11)
	Create("UIStroke", { Color = Library.Theme.Accent, Thickness = 1.6, Transparency = 0.4, Parent = ProfileAvatar })

	local PlayerName = Create("TextLabel", {
		Name = "DisplayName",
		Size = UDim2.new(1, -66, 0, 20),
		Position = UDim2.new(0, 64, 0, 10),
		BackgroundTransparency = 1,
		Text = "Player",
		TextColor3 = Library.Theme.Text,
		FontFace = FontBold,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = SidebarFooter,
	})
	local Username = Create("TextLabel", {
		Name = "Username",
		Size = UDim2.new(1, -66, 0, 17),
		Position = UDim2.new(0, 64, 0, 31),
		BackgroundTransparency = 1,
		Text = "@player",
		TextColor3 = Library.Theme.TextMuted,
		FontFace = FontStandard,
		TextSize = 11,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = SidebarFooter,
	})

	local Player = Players.LocalPlayer
	if Player then
		PlayerName.Text = Player.DisplayName ~= "" and Player.DisplayName or Player.Name
		Username.Text = "@" .. Player.Name
		local okThumb, content = pcall(function()
			return Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if okThumb and type(content) == "string" then
			ProfileAvatar.Image = content
		else
			ProfileAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(Player.UserId) .. "&w=100&h=100"
		end
	end

	-- ------------------------------------------------------------ content
	local ContentContainer = Create("Frame", {
		Name = "ContentContainer",
		Size = UDim2.new(1, -SidebarWidth, 1, -LAYOUT.HeaderHeight),
		Position = UDim2.new(0, SidebarWidth, 0, LAYOUT.HeaderHeight),
		BackgroundTransparency = 1,
		Parent = MainFrame,
	})

	local ContentTop = Create("Frame", {
		Name = "ContentTop",
		Size = UDim2.new(1, -28, 0, LAYOUT.ContentTopHeight),
		Position = UDim2.new(0, 14, 0, 12),
		BackgroundColor3 = Library.Theme.Surface,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Parent = ContentContainer,
	})
	Corner(ContentTop, LAYOUT.ContentTopRadius)
	Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.7, Parent = ContentTop })
	local TopSheen = Create("Frame", { Size = UDim2.new(0, 3, 0, 30), Position = UDim2.new(0, 8, 0.5, -15), BackgroundColor3 = Library.Theme.Accent, BackgroundTransparency = 0.15, BorderSizePixel = 0, Parent = ContentTop })
	Corner(TopSheen, 2)

	local PageKicker = Create("TextLabel", {
		Size = UDim2.new(1, -300, 0, 15),
		Position = UDim2.new(0, 22, 0, 7),
		BackgroundTransparency = 1,
		Text = "WORKSPACE",
		TextColor3 = Library.Theme.TextMuted,
		FontFace = FontBold,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = ContentTop,
	})
	local CurrentPageLabel = Create("TextLabel", {
		Size = UDim2.new(1, -300, 0, 22),
		Position = UDim2.new(0, 22, 0, 23),
		BackgroundTransparency = 1,
		Text = "Select a tab",
		TextColor3 = Library.Theme.Text,
		FontFace = FontBold,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = ContentTop,
	})

	local ThemeMini = Create("TextButton", {
		Size = UDim2.new(0, 116, 0, 32),
		Position = UDim2.new(1, -128, 0.5, -16),
		BackgroundColor3 = Library.Theme.Element,
		Text = Library.ThemeName,
		TextColor3 = Library.Theme.Accent,
		FontFace = FontBold,
		TextSize = 11,
		AutoButtonColor = false,
		Parent = ContentTop,
	})
	Corner(ThemeMini, 9)
	Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.5, Parent = ThemeMini })
	AddConnection(ThemeMini.MouseButton1Click:Connect(CycleTheme))
	local ThemeMiniGlow = Create("Frame", { Size = UDim2.new(1, 10, 1, 10), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Library.Theme.Accent, BackgroundTransparency = 0.9, BorderSizePixel = 0, Parent = ThemeMini })
	Corner(ThemeMiniGlow, 16)

	-- collapse
	local function UpdateTabsCollapsed(collapsed)
		for _, entry in ipairs(Window.Tabs) do
			entry.Text.Visible = not collapsed
			if entry.Badge then entry.Badge.Visible = not collapsed end
			entry.Button.Size = UDim2.new(1, collapsed and -16 or -20, 0, LAYOUT.NavHeight)
			local iconCx = collapsed and 14 or 24
			entry.Icon.Position = UDim2.new(0, iconCx - 14, 0.5, -14)
		end
	end

	AddConnection(CollapseButton.MouseButton1Click:Connect(function()
		Collapsed = not Collapsed
		local targetWidth = Collapsed and LAYOUT.SidebarCollapsedWidth or SidebarWidth
		SpringTween(Sidebar, { Size = UDim2.new(0, targetWidth, 1, -LAYOUT.HeaderHeight) }, 0.26)
		SpringTween(ContentContainer, { Size = UDim2.new(1, -targetWidth, 1, -LAYOUT.HeaderHeight), Position = UDim2.new(0, targetWidth, 0, LAYOUT.HeaderHeight) }, 0.26)
		Tween(CollapseButton, { Rotation = Collapsed and 180 or 0 }, 0.2)
		NavLabel.Visible = not Collapsed
		SidebarFooter.Visible = not Collapsed
		UpdateTabsCollapsed(Collapsed)
	end))

	-- ------------------------------------------------------------ state
	local WindowState = { Minimized = false, Closed = false }
	local RestoreHeight = BaseWindowHeight

	local ReopenButton = Create("TextButton", {
		Name = "ReopenButton",
		Size = UDim2.new(0, 62, 0, 62),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -24),
		BackgroundColor3 = Library.Theme.Element,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 200,
		Parent = Library.ScreenGui,
	})
	AddInstance(ReopenButton)
	Corner(ReopenButton, 19)
	Create("UIStroke", { Color = Library.Theme.Accent, Thickness = 1.4, Transparency = 0.45, Parent = ReopenButton })
	local ReopenGlow = Create("Frame", { Size = UDim2.new(0, 82, 0, 82), Position = UDim2.new(1, -24, 1, -24), AnchorPoint = Vector2.new(1, 1), BackgroundColor3 = Library.Theme.Accent, BackgroundTransparency = 0.88, BorderSizePixel = 0, ZIndex = 199, Parent = Library.ScreenGui })
	Corner(ReopenGlow, 26)
	local ReopenScale = Create("UIScale", { Scale = 0.7, Parent = ReopenButton })
	local ReopenIcon = CreateIcon(ReopenButton, "up", Library.Theme.Accent)
	ReopenIcon.Size = UDim2.new(0, 30, 0, 30)
	ReopenIcon.Position = UDim2.new(0.5, -15, 0.5, -15)

	local function ShowLauncher()
		ReopenButton.Visible = true
		ReopenGlow.Visible = true
		SpringTween(ReopenScale, { Scale = 1 }, 0.35)
	end
	local function HideLauncher()
		SpringTween(ReopenScale, { Scale = 0.7 }, 0.18)
		task.delay(0.18, function()
			if ReopenButton.Parent then ReopenButton.Visible = false; ReopenGlow.Visible = false end
		end)
	end

	local function RestoreWindow()
		WindowState.Minimized = false
		HideLauncher()
		MainFrame.Visible = true
		Sidebar.Visible = true
		ContentContainer.Visible = true
		MainFrame.BackgroundTransparency = 0
		SpringTween(MainScale, { Scale = Library.UIScale }, 0.3)
		SpringTween(MainFrame, { Size = UDim2.new(0, BaseWindowWidth, 0, RestoreHeight) }, 0.34)
	end

	function WindowState:Minimize()
		if WindowState.Closed or WindowState.Minimized then return end
		WindowState.Minimized = true
		Sidebar.Visible = false
		ContentContainer.Visible = false
		SpringTween(MainScale, { Scale = 0.82 }, 0.16)
		task.delay(0.16, function()
			if MainFrame.Parent and WindowState.Minimized then
				MainFrame.Visible = false
				ShowLauncher()
			end
		end)
	end

	local function CloseWindow()
		if WindowState.Closed then return end
		WindowState.Closed = true
		Tween(MainFrame, { BackgroundTransparency = 0.35 }, 0.18)
		SpringTween(MainScale, { Scale = 0.9 }, 0.22)
		task.delay(0.22, function()
			if MainFrame.Parent and WindowState.Closed then
				MainFrame.Visible = false
				ShowLauncher()
			end
		end)
	end

	AddConnection(MinimizeButton.MouseButton1Click:Connect(function()
		if WindowState.Minimized then RestoreWindow() else WindowState:Minimize() end
	end))

	local DestroyOnClose = options.DestroyOnClose ~= false
	AddConnection(CloseButton.MouseButton1Click:Connect(function()
		if DestroyOnClose then Window:Destroy() else CloseWindow() end
	end))

	AddConnection(ReopenButton.MouseEnter:Connect(function()
		SpringTween(ReopenButton, { Size = UDim2.new(0, 68, 0, 68), BackgroundColor3 = Library.Theme.ElementHover }, 0.16)
	end))
	AddConnection(ReopenButton.MouseLeave:Connect(function()
		Tween(ReopenButton, { Size = UDim2.new(0, 62, 0, 62), BackgroundColor3 = Library.Theme.Element }, 0.14)
	end))
	AddConnection(ReopenButton.MouseButton1Click:Connect(function()
		WindowState.Closed = false
		WindowState.Minimized = false
		HideLauncher()
		MainFrame.Visible = true
		MainFrame.BackgroundTransparency = 0
		MainFrame.Size = UDim2.new(0, BaseWindowWidth, 0, BaseWindowHeight)
		MainScale.Scale = 0.88
		Sidebar.Visible = true
		ContentContainer.Visible = true
		SpringTween(MainScale, { Scale = Library.UIScale }, 0.38)
	end))

	local WindowVisible = true
	local function ShowWindow()
		WindowVisible = true
		WindowState.Closed = false
		MainFrame.Visible = true
		Sidebar.Visible = not WindowState.Minimized
		ContentContainer.Visible = not WindowState.Minimized
		MainFrame.BackgroundTransparency = 0
		SpringTween(MainScale, { Scale = Library.UIScale }, 0.28)
	end
	local function HideWindow()
		WindowVisible = false
		Tween(MainFrame, { BackgroundTransparency = 1 }, 0.2)
		Tween(MainScale, { Scale = 0.94 }, 0.22)
		task.delay(0.23, function()
			if not WindowVisible and MainFrame.Parent then MainFrame.Visible = false end
		end)
	end

	function Window:Minimize() WindowState:Minimize() end
	function Window:Restore() RestoreWindow() end
	function Window:ToggleMinimize() if WindowState.Minimized then RestoreWindow() else WindowState:Minimize() end end
	function Window:Close() if DestroyOnClose then self:Destroy() else CloseWindow() end end
	function Window:SetVisible(state) if state then ShowWindow() else HideWindow() end end
	function Window:CycleTheme() CycleTheme() end
	function Window:SetScale(scale)
		Library.UIScale = math.clamp(tonumber(scale) or 1, 0.85, 1.30)
		SpringTween(MainScale, { Scale = Library.UIScale }, 0.2)
	end
	function Window:GetScale() return Library.UIScale end
	function Window:SetSize(width, height)
		BaseWindowWidth = math.clamp(tonumber(width) or BaseWindowWidth, MinWindowWidth, MaxWindowWidth)
		BaseWindowHeight = math.clamp(tonumber(height) or BaseWindowHeight, MinWindowHeight, MaxWindowHeight)
		RestoreHeight = BaseWindowHeight
		if not WindowState.Minimized then
			SpringTween(MainFrame, { Size = UDim2.new(0, BaseWindowWidth, 0, BaseWindowHeight) }, 0.24)
		end
	end
	function Window:GetSize() return BaseWindowWidth, BaseWindowHeight end
	function Window:Destroy() Library:Destroy() end

	-- resize handle
	local ResizeHandle = Create("TextButton", {
		Name = "ResizeHandle", Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -30, 1, -30),
		BackgroundTransparency = 1, Text = "◢", TextColor3 = Library.Theme.TextMuted, TextSize = 13, FontFace = FontBold,
		AutoButtonColor = false, ZIndex = 50, Parent = MainFrame,
	})
	AddInstance(ResizeHandle)
	local resizing, resizeStart, resizeSize
	AddConnection(ResizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing, resizeStart, resizeSize = true, input.Position, Vector2.new(BaseWindowWidth, BaseWindowHeight)
		end
	end))
	AddConnection(UserInputService.InputChanged:Connect(function(input)
		if not resizing then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local delta = input.Position - resizeStart
		BaseWindowWidth = math.clamp(resizeSize.X + delta.X, MinWindowWidth, MaxWindowWidth)
		BaseWindowHeight = math.clamp(resizeSize.Y + delta.Y, MinWindowHeight, MaxWindowHeight)
		RestoreHeight = BaseWindowHeight
		MainFrame.Size = UDim2.new(0, BaseWindowWidth, 0, BaseWindowHeight)
	end))
	AddConnection(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then resizing = false end
	end))

	AddConnection(UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe or Library.ListeningKeybind then return end
		if input.KeyCode == ToggleKeybind then if WindowVisible then HideWindow() else ShowWindow() end end
		if input.KeyCode == Enum.KeyCode.K and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then SearchBox:CaptureFocus() end
	end))

	task.spawn(function()
		if MainFrame.Parent then
			Tween(MainFrame, { BackgroundTransparency = 0 }, 0.26)
			SpringTween(MainScale, { Scale = Library.UIScale }, 0.48)
		end
	end)-- ------------------------------------------------------------ tabs
	function Window:CreateTab(tabOptions)
		tabOptions = tabOptions or {}
		local Tab: { [string]: any } = { Elements = {} }
		local TabName = tabOptions.Name or "Tab"
		local TabButton = Create("TextButton", {
			Name = TabName .. "Btn",
			Size = UDim2.new(1, -20, 0, LAYOUT.NavHeight),
			BackgroundColor3 = Library.Theme.Element,
			BackgroundTransparency = 0.2,
			Text = "",
			TextColor3 = Library.Theme.TextMuted,
			FontFace = FontStandard,
			TextSize = 13,
			AutoButtonColor = false,
			Parent = TabContainer,
		})
		Corner(TabButton, LAYOUT.NavRadius)
		Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.6, Parent = TabButton })
		local IconHolder = Create("Frame", { Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(0, 10, 0.5, -14), BackgroundTransparency = 1, Parent = TabButton })
		local TabIcon = CreateIcon(IconHolder, tabOptions.Icon or "menu", Library.Theme.TextMuted)
		local TabText = Create("TextLabel", {
			Size = UDim2.new(1, -52, 1, 0), Position = UDim2.new(0, 44, 0, 0),
			BackgroundTransparency = 1, Text = TabName, TextColor3 = Library.Theme.TextMuted, FontFace = FontBold, TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left, Parent = TabButton,
		})
		local TabAccent = Create("Frame", {
			Size = UDim2.new(0, 3, 0, 22), Position = UDim2.new(0, 7, 0.5, -11),
			BackgroundColor3 = Library.Theme.Accent, BackgroundTransparency = 0, BorderSizePixel = 0, Visible = #Window.Tabs == 0, Parent = TabButton,
		})
		Corner(TabAccent, 3)
		local Badge = nil
		if tabOptions.Badge then
			Badge = Create("TextLabel", {
				Size = UDim2.new(0, 30, 0, 20), Position = UDim2.new(1, -38, 0.5, -10),
				BackgroundColor3 = Library.Theme.SurfaceStrong, Text = tostring(tabOptions.Badge), TextColor3 = Library.Theme.TextMuted, FontFace = FontBold, TextSize = 10, Parent = TabButton,
			})
			Corner(Badge, 8)
		end

		AddConnection(TabButton.MouseEnter:Connect(function()
			if Window.CurrentTab ~= Tab then
				Tween(TabButton, { BackgroundColor3 = Library.Theme.ElementHover, BackgroundTransparency = 0.1 }, 0.14)
				SetIconColor(TabIcon, Library.Theme.Text)
			end
		end))
		AddConnection(TabButton.MouseLeave:Connect(function()
			if Window.CurrentTab ~= Tab then
				Tween(TabButton, { BackgroundColor3 = Library.Theme.Element, BackgroundTransparency = 0.2 }, 0.14)
				SetIconColor(TabIcon, Library.Theme.TextMuted)
			end
		end))

		local Page = Create("ScrollingFrame", {
			Name = TabName .. "Page",
			Size = UDim2.new(1, -4, 1, -32 - LAYOUT.ContentTopHeight),
			Position = UDim2.new(0, 2, 0, 24 + LAYOUT.ContentTopHeight),
			BackgroundTransparency = 1,
			ScrollBarThickness = 4,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarImageColor3 = Library.Theme.Border,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Visible = false,
			Parent = ContentContainer,
		})
		local PageScale = Create("UIScale", { Scale = 1, Parent = Page })
		Create("UIPadding", {
			PaddingTop = UDim.new(0, LAYOUT.PageTopPadding),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 18),
			PaddingRight = UDim.new(0, 18),
			Parent = Page,
		})
		local PageLayout = Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			Parent = Page,
		})
		AddConnection(PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			Page.CanvasSize = UDim2.new(0, 0, 0, math.max(Page.AbsoluteWindowSize.Y, PageLayout.AbsoluteContentSize.Y + 38))
		end))

		AddConnection(TabButton.MouseButton1Click:Connect(function()
			for _, tb in ipairs(Window.Tabs) do
				tb.Page.Visible = false
				tb.Accent.Visible = false
				Tween(tb.Button, { BackgroundColor3 = Library.Theme.Element, BackgroundTransparency = 0.2 }, 0.18)
				SetIconColor(tb.Icon, Library.Theme.TextMuted)
			end
			Window.CurrentTab = Tab
			CurrentPageLabel.Text = TabName
			PageKicker.Text = string.upper(TabName)
			Page.Visible = true
			PageScale.Scale = 0.985
			TabAccent.Visible = true
			SpringTween(PageScale, { Scale = 1 }, 0.3)
			SpringTween(TabButton, { BackgroundColor3 = Library.Theme.Accent, BackgroundTransparency = 0.12 }, 0.24)
			SetIconColor(TabIcon, Library.Theme.Background)
		end))

		if #Window.Tabs == 0 then
			Page.Visible = true
			Window.CurrentTab = Tab
			TabButton.BackgroundColor3 = Library.Theme.Accent
			TabButton.BackgroundTransparency = 0.12
			SetIconColor(TabIcon, Library.Theme.Background)
			TabAccent.Visible = true
			CurrentPageLabel.Text = TabName
			PageKicker.Text = string.upper(TabName)
		end

		table.insert(Window.Tabs, { Button = TabButton, Page = Page, Accent = TabAccent, Icon = TabIcon, Text = TabText, Badge = Badge, Name = TabName, PageScale = PageScale })

		-- columns
		function Tab:SetColumn(column)
			if type(column) == "table" and column._Parent then self._ParentOverride = column._Parent else self._ParentOverride = nil end
			return self
		end
		function Tab:UseColumn(column) return self:SetColumn(column) end
		function Tab:ClearColumnSelection() self._ParentOverride = nil; return self end

		function Tab:CreateColumns(countOrOptions)
			local count, gap = 2, 10
			if type(countOrOptions) == "number" then
				count = math.clamp(math.floor(countOrOptions), 2, 4)
			elseif type(countOrOptions) == "table" then
				count = math.clamp(math.floor(tonumber(countOrOptions.Count) or 2), 2, 4)
				gap = math.clamp(tonumber(countOrOptions.Gap) or 10, 0, 24)
			end
			local Row = Create("Frame", { Name = "Columns", Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = #self.Elements + 1, Parent = Page })
			Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, gap), Parent = Row })
			local columns = {}
			local widthScale = 1 / count
			for i = 1, count do
				local column = Create("Frame", { Name = "Column" .. i, Size = UDim2.new(widthScale, -gap * (count - 1) / count, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = i, Parent = Row })
				local list = Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = column })
				columns[i] = { _Parent = column, Index = i, Layout = list }
			end
			self._LastColumns = columns
			self._ParentOverride = nil
			table.insert(self.Elements, Row)
			return columns
		end

		-- ------------------------------------------------------------ toggle
		function Tab:CreateToggle(tOpts)
			local Toggle: { [string]: any } = { Value = tOpts.CurrentValue or false }
			if tOpts.Flag then Library.Flags[tOpts.Flag] = Toggle.Value end

			local Container = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 48),
				BackgroundColor3 = Library.Theme.Element,
				BackgroundTransparency = 0.1,
				Parent = Tab._ParentOverride or Page,
			})
			Container:SetAttribute("ZenSearchText", tOpts.Name or "Toggle")
			Corner(Container, LAYOUT.CardRadius)
			Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.6, Parent = Container })
			CardMotion(Container)
			CardSheen(Container)

			Create("TextLabel", {
				Size = UDim2.new(1, -84, 1, 0), Position = UDim2.new(0, 14, 0, 0),
				BackgroundTransparency = 1, Text = tOpts.Name or "Toggle", TextColor3 = Library.Theme.Text, FontFace = FontStandard, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left, Parent = Container,
			})

			local SwitchArea = Create("Frame", {
				Size = UDim2.new(0, LAYOUT.ToggleSwitchW, 0, LAYOUT.ToggleSwitchH),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(1, -38, 0.5, 0),
				BackgroundColor3 = Toggle.Value and Library.Theme.Accent or Library.Theme.SurfaceStrong,
				Parent = Container,
			})
			Corner(SwitchArea, LAYOUT.ToggleSwitchH / 2)
			Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.3, Parent = SwitchArea })

			local SwitchGlow = Create("Frame", {
				Size = UDim2.new(1, 12, 1, 12), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Library.Theme.Text, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = SwitchArea.ZIndex - 1, Parent = SwitchArea,
			})
			Corner(SwitchGlow, 18)

			local Indicator = Create("Frame", {
				Size = UDim2.new(0, LAYOUT.ToggleKnob, 0, LAYOUT.ToggleKnob),
				Position = Toggle.Value and UDim2.new(1, -LAYOUT.ToggleKnob - 3.5, 0.5, -LAYOUT.ToggleKnob / 2) or UDim2.new(0, 3.5, 0.5, -LAYOUT.ToggleKnob / 2),
				BackgroundColor3 = Toggle.Value and Library.Theme.Background or Library.Theme.Text,
				Parent = SwitchArea,
			})
			Corner(Indicator, LAYOUT.ToggleKnob / 2)
			Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.4, Parent = Indicator })

			local Btn = Create("TextButton", {
				Size = UDim2.new(0, LAYOUT.ToggleSwitchW, 0, LAYOUT.ToggleSwitchH),
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -38, 0.5, 0),
				BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = SwitchArea.ZIndex + 2, Parent = Container,
			})

			function Toggle:Get() return self.Value end
			function Toggle:Set(val, noCallback)
				self.Value = val
				if tOpts.Flag then Library.Flags[tOpts.Flag] = val end
				Tween(SwitchArea, { BackgroundColor3 = val and Library.Theme.Accent or Library.Theme.SurfaceStrong }, 0.2)
				Tween(SwitchGlow, { BackgroundTransparency = val and 0.8 or 1 }, 0.22)
				SpringTween(Indicator, {
					Position = val and UDim2.new(1, -LAYOUT.ToggleKnob - 3.5, 0.5, -LAYOUT.ToggleKnob / 2) or UDim2.new(0, 3.5, 0.5, -LAYOUT.ToggleKnob / 2),
					BackgroundColor3 = val and Library.Theme.Background or Library.Theme.Text,
				}, 0.22)
				if not noCallback and tOpts.Callback then task.spawn(tOpts.Callback, val) end
			end

			AddConnection(Btn.MouseButton1Click:Connect(function() Toggle:Set(not Toggle.Value) end))
			if tOpts.Keybind then
				local keyName = tostring(tOpts.Keybind)
				AddConnection(UserInputService.InputBegan:Connect(function(input, gpe)
					if gpe then return end
					if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == keyName then
						Toggle:Set(not Toggle.Value)
					elseif input.UserInputType.Name == keyName then
						Toggle:Set(not Toggle.Value)
					end
				end))
			end
			if tOpts.Flag then Library.ConfigHandlers[tOpts.Flag] = function(v) Toggle:Set(v, true) end end

			return Toggle
		end

		-- ------------------------------------------------------------ slider
		function Tab:CreateSlider(sOpts)
			sOpts = sOpts or {}
			local Min = sOpts.Min or 0
			local Max = sOpts.Max or 100
			local Increment = sOpts.Increment or 1
			local Suffix = sOpts.Suffix or ""
			local Slider: { [string]: any } = { Value = sOpts.Default or Min }
			if sOpts.Flag then Library.Flags[sOpts.Flag] = Slider.Value end

			local Container = Create("Frame", {
				Size = UDim2.new(1, 0, 0, LAYOUT.SliderHeight),
				BackgroundColor3 = Library.Theme.Element,
				BackgroundTransparency = 0.1,
				Parent = Tab._ParentOverride or Page,
			})
			Container:SetAttribute("ZenSearchText", sOpts.Name or "Slider")
			Corner(Container, LAYOUT.CardRadius)
			Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.6, Parent = Container })
			CardMotion(Container)
			CardSheen(Container)

			Create("TextLabel", {
				Size = UDim2.new(1, -110, 0, 26), Position = UDim2.new(0, 14, 0, 3),
				BackgroundTransparency = 1, Text = sOpts.Name or "Slider", TextColor3 = Library.Theme.Text, FontFace = FontStandard, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left, Parent = Container,
			})

			local ValueLabel = Create("TextLabel", {
				Size = UDim2.new(0, 90, 0, 26), Position = UDim2.new(1, -102, 0, 3),
				BackgroundTransparency = 1, Text = tostring(Slider.Value) .. Suffix, TextColor3 = Library.Theme.Accent, FontFace = FontStandard, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Right, Parent = Container,
			})

			local Track = Create("Frame", {
				Size = UDim2.new(1, -24, 0, LAYOUT.SliderTrackH),
				Position = UDim2.new(0, 12, 1, -14),
				BackgroundColor3 = Library.Theme.SurfaceStrong,
				Parent = Container,
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track })

			local Fill = Create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Library.Theme.Accent, Parent = Track })
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill })
			Create("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Library.Theme.Accent),
					ColorSequenceKeypoint.new(1, Library.Theme.Accent:Lerp(Color3.new(1, 1, 1), 0.25)),
				}),
				Parent = Fill,
			})

			local Knob = Create("Frame", {
				Size = UDim2.new(0, LAYOUT.SliderKnob, 0, LAYOUT.SliderKnob),
				Position = UDim2.new(0, -LAYOUT.SliderKnob / 2, 0.5, -LAYOUT.SliderKnob / 2),
				BackgroundColor3 = Library.Theme.Background,
				Parent = Track,
				ZIndex = 3,
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })
			Create("UIStroke", { Color = Library.Theme.Accent, Thickness = 2.2, Transparency = 0.1, Parent = Knob })

			local Btn = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = Container })

			local function syncKnob(pct)
				Knob.Position = UDim2.new(math.clamp(pct, 0, 1), -LAYOUT.SliderKnob / 2, 0.5, -LAYOUT.SliderKnob / 2)
			end

			function Slider:Get() return self.Value end
			function Slider:Set(val, noCallback)
				self.Value = val
				local range = Max - Min
				if range <= 0 then return end
				local clamped = math.clamp(val, Min, Max)
				local rounded = math.floor(clamped / Increment + 0.5) * Increment
				self.Value = rounded
				if sOpts.Flag then Library.Flags[sOpts.Flag] = rounded end
				local pct = (rounded - Min) / range
				Tween(Fill, { Size = UDim2.new(pct, 0, 1, 0) }, 0.1)
				syncKnob(pct)
				ValueLabel.Text = tostring(rounded) .. Suffix
				if not noCallback and sOpts.Callback then task.spawn(sOpts.Callback, rounded) end
			end

			Slider:Set(Slider.Value, true)
			local dragging = false
			AddConnection(Btn.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
			end))
			AddConnection(UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
			end))
			AddConnection(UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local mouseX = input.Position.X
					local trackX = Track.AbsolutePosition.X
					local trackW = Track.AbsoluteSize.X
					if trackW > 0 then
						local pct = math.clamp((mouseX - trackX) / trackW, 0, 1)
						Slider:Set(Min + (pct * (Max - Min)))
					end
				end
			end))
			if sOpts.Flag then Library.ConfigHandlers[sOpts.Flag] = function(v) Slider:Set(v, true) end end

			return Slider
		end-- ------------------------------------------------------ dropdown
		function Tab:CreateDropdown(dOpts)
			local Dropdown: { [string]: any } = { Value = dOpts.CurrentOption, Options = dOpts.Options or {} }
			if dOpts.Flag then Library.Flags[dOpts.Flag] = Dropdown.Value end
			local Expanded = false

			local Container = Create("Frame", {
				Size = UDim2.new(1, 0, 0, LAYOUT.DropdownHeight),
				BackgroundColor3 = Library.Theme.Element,
				BackgroundTransparency = 0.1,
				ClipsDescendants = true,
				Parent = Tab._ParentOverride or Page,
			})
			Container:SetAttribute("ZenSearchText", dOpts.Name or "Dropdown")
			Corner(Container, LAYOUT.CardRadius)
			Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.6, Parent = Container })
			CardMotion(Container)
			CardSheen(Container)

			local TopBar = Create("TextButton", { Size = UDim2.new(1, 0, 0, LAYOUT.DropdownTopH), BackgroundTransparency = 1, Text = "", Parent = Container })
			Create("TextLabel", {
				Size = UDim2.new(1, -56, 1, 0), Position = UDim2.new(0, 14, 0, 0),
				BackgroundTransparency = 1, Text = dOpts.Name or "Dropdown", TextColor3 = Library.Theme.Text, FontFace = FontStandard, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar,
			})

			local SelectedLabel = Create("TextLabel", {
				Size = UDim2.new(0, 190, 1, 0),
				Position = UDim2.new(1, -248, 0, 0),
				BackgroundTransparency = 1,
				Text = type(Dropdown.Value) == "table" and table.concat(Dropdown.Value, ", ") or tostring(Dropdown.Value or ""),
				TextColor3 = Library.Theme.Accent,
				FontFace = FontStandard,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = TopBar,
			})

			local Chevron = Create("TextLabel", {
				Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -32, 0.5, -12),
				BackgroundTransparency = 1, Text = "▾", TextColor3 = Library.Theme.TextMuted, FontFace = FontBold, TextSize = 13, Parent = TopBar,
			})

			local ListContainer = Create("Frame", {
				Size = UDim2.new(1, -20, 1, -48),
				Position = UDim2.new(0, 10, 0, 48),
				BackgroundTransparency = 1,
				Parent = Container,
			})
			local ListLayout = Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = ListContainer })
			local OptionBtns = {}

			function Dropdown:Get() return self.Value end
			function Dropdown:Set(val, noCallback)
				self.Value = val
				if dOpts.Flag then Library.Flags[dOpts.Flag] = val end
				SelectedLabel.Text = type(val) == "table" and table.concat(val, ", ") or tostring(val or "")
				for opt, btn in pairs(OptionBtns) do
					local isSelected = false
					if type(val) == "table" then
						isSelected = table.find(val, opt) ~= nil
					else
						isSelected = (val == opt)
					end
					btn.TextColor3 = isSelected and Library.Theme.Accent or Library.Theme.TextMuted
				end
				if not noCallback and dOpts.Callback then task.spawn(dOpts.Callback, val) end
			end

			local function Populate()
				for _, child in ipairs(ListContainer:GetChildren()) do
					if child:IsA("TextButton") then child:Destroy() end
				end
				OptionBtns = {}
				for _, opt in ipairs(Dropdown.Options) do
					local isSelected = false
					if type(Dropdown.Value) == "table" then
						isSelected = table.find(Dropdown.Value, opt) ~= nil
					else
						isSelected = (Dropdown.Value == opt)
					end
					local OptBtn = Create("TextButton", {
						Size = UDim2.new(1, 0, 0, LAYOUT.DropdownOptionH),
						BackgroundColor3 = Library.Theme.ElementHover,
						BackgroundTransparency = 0.2,
						Text = tostring(opt),
						TextColor3 = isSelected and Library.Theme.Accent or Library.Theme.TextMuted,
						FontFace = FontStandard,
						TextSize = 14,
						AutoButtonColor = false,
						Parent = ListContainer,
					})
					Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = OptBtn })
					OptionBtns[opt] = OptBtn
					local OptRail = Create("Frame", { Size = UDim2.new(0, 3, 0, 16), Position = UDim2.new(0, 0, 0.5, -8), BackgroundColor3 = Library.Theme.Accent, BackgroundTransparency = isSelected and 0.1 or 1, BorderSizePixel = 0, Parent = OptBtn })
					Corner(OptRail, 2)
					AddConnection(OptBtn.MouseEnter:Connect(function() Tween(OptBtn, { BackgroundTransparency = 0 }, 0.12) end))
					AddConnection(OptBtn.MouseLeave:Connect(function()
						local sel = false
						if type(Dropdown.Value) == "table" then sel = table.find(Dropdown.Value, opt) ~= nil else sel = Dropdown.Value == opt end
						Tween(OptBtn, { BackgroundTransparency = sel and 0.05 or 0.2 }, 0.12)
					end))
					AddConnection(OptBtn.MouseButton1Click:Connect(function()
						if dOpts.MultiSelection then
							local current = type(Dropdown.Value) == "table" and {} or {}
							for _, v in ipairs(type(Dropdown.Value) == "table" and Dropdown.Value or {}) do table.insert(current, v) end
							local pos = table.find(current, opt)
							if pos then table.remove(current, pos) else table.insert(current, opt) end
							Dropdown:Set(current)
						else
							Dropdown:Set(opt)
							Expanded = false
							Tween(Container, { Size = UDim2.new(1, 0, 0, LAYOUT.DropdownHeight) }, 0.2)
							Tween(Chevron, { Rotation = 0 }, 0.2)
						end
					end))
				end
				if Expanded then
					Container.Size = UDim2.new(1, 0, 0, LAYOUT.DropdownHeight + 6 + ListLayout.AbsoluteContentSize.Y + 10)
				end
			end

			AddConnection(TopBar.MouseButton1Click:Connect(function()
				Expanded = not Expanded
				if Expanded then
					Populate()
					Tween(Container, { Size = UDim2.new(1, 0, 0, LAYOUT.DropdownHeight + 6 + ListLayout.AbsoluteContentSize.Y + 10) }, 0.2)
					Tween(Chevron, { Rotation = 180 }, 0.2)
				else
					Tween(Container, { Size = UDim2.new(1, 0, 0, LAYOUT.DropdownHeight) }, 0.2)
					Tween(Chevron, { Rotation = 0 }, 0.2)
				end
			end))

			function Dropdown:Refresh(newOptions, keepSelection)
				self.Options = newOptions or {}
				if not keepSelection then self:Set(dOpts.MultiSelection and {} or nil, true) end
				Populate()
			end
			if dOpts.Flag then Library.ConfigHandlers[dOpts.Flag] = function(v) Dropdown:Set(v, true) end end
			Populate()
			return Dropdown
		end

		-- ------------------------------------------------------ keybind
		function Tab:CreateKeybind(kOpts)
			local Keybind: { [string]: any } = { Value = kOpts.CurrentKeybind or "None" }
			if kOpts.Flag then Library.Flags[kOpts.Flag] = Keybind.Value end
			local Listening = false

			local Container = Create("Frame", {
				Size = UDim2.new(1, 0, 0, LAYOUT.KeybindHeight),
				BackgroundColor3 = Library.Theme.Element,
				BackgroundTransparency = 0.1,
				Parent = Tab._ParentOverride or Page,
			})
			Container:SetAttribute("ZenSearchText", kOpts.Name or "Keybind")
			Corner(Container, LAYOUT.CardRadius)
			Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.6, Parent = Container })
			CardMotion(Container)
			CardSheen(Container)
			Create("TextLabel", {
				Size = UDim2.new(1, -140, 1, 0), Position = UDim2.new(0, 14, 0, 0),
				BackgroundTransparency = 1, Text = kOpts.Name or "Keybind", TextColor3 = Library.Theme.Text, FontFace = FontStandard, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left, Parent = Container,
			})

			local BindBtn = Create("TextButton", {
				Size = UDim2.new(0, LAYOUT.KeybindW, 0, 30),
				Position = UDim2.new(1, -LAYOUT.KeybindW - 14, 0.5, -15),
				BackgroundColor3 = Library.Theme.SurfaceStrong,
				Text = tostring(Keybind.Value),
				TextColor3 = Library.Theme.Accent,
				FontFace = FontStandard,
				TextSize = 14,
				Parent = Container,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 9), Parent = BindBtn })
			Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.4, Parent = BindBtn })
			AddConnection(BindBtn.MouseEnter:Connect(function() Tween(BindBtn, { BackgroundColor3 = Library.Theme.ElementHover }, 0.14) end))
			AddConnection(BindBtn.MouseLeave:Connect(function() Tween(BindBtn, { BackgroundColor3 = Library.Theme.SurfaceStrong }, 0.14) end))
			AddConnection(BindBtn.MouseButton1Click:Connect(function()
				Listening = true
				Library.ListeningKeybind = true
				BindBtn.Text = "Listening..."
			end))

			AddConnection(UserInputService.InputBegan:Connect(function(input)
				if Listening then
					if input.KeyCode == Enum.KeyCode.Escape then
						Listening = false
						Library.ListeningKeybind = false
						BindBtn.Text = tostring(Keybind.Value)
						return
					end
					if input.UserInputType == Enum.UserInputType.Keyboard then
						local key = input.KeyCode.Name
						if key ~= "Unknown" then
							Listening = false
							Library.ListeningKeybind = false
							Keybind:Set(key)
						end
					elseif input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.MouseButton2
						or input.UserInputType == Enum.UserInputType.MouseButton3 then
						Listening = false
						Library.ListeningKeybind = false
						Keybind:Set(input.UserInputType.Name)
					end
				else
					if not Library.ListeningKeybind and Keybind.Value ~= "None" then
						if (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == Keybind.Value)
							or (input.UserInputType.Name == Keybind.Value) then
							if kOpts.Callback then task.spawn(kOpts.Callback) end
						end
					end
				end
			end))

			function Keybind:Get() return self.Value end
			function Keybind:Set(val, noCallback)
				self.Value = val
				if kOpts.Flag then Library.Flags[kOpts.Flag] = val end
				BindBtn.Text = tostring(val)
			end
			if kOpts.Flag then Library.ConfigHandlers[kOpts.Flag] = function(v) Keybind:Set(v, true) end end
			return Keybind
		end

		-- ------------------------------------------------------ textbox
		function Tab:CreateTextBox(tOpts)
			tOpts = tOpts or {}
			local Container = Create("Frame", {
				Size = UDim2.new(1, 0, 0, LAYOUT.TextBoxHeight),
				BackgroundColor3 = Library.Theme.Element,
				BackgroundTransparency = 0.1,
				Parent = Tab._ParentOverride or Page,
			})
			Container:SetAttribute("ZenSearchText", tOpts.Name or "TextBox")
			Corner(Container, LAYOUT.CardRadius)
			Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.6, Parent = Container })
			CardMotion(Container)
			CardSheen(Container)
			Create("TextLabel", {
				Size = UDim2.new(1, -192, 1, 0), Position = UDim2.new(0, 14, 0, 0),
				BackgroundTransparency = 1, Text = tOpts.Name or "TextBox", TextColor3 = Library.Theme.Text, FontFace = FontStandard, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left, Parent = Container,
			})

			local Box = Create("TextBox", {
				Size = UDim2.new(0, LAYOUT.TextBoxW, 0, 30),
				Position = UDim2.new(1, -LAYOUT.TextBoxW - 14, 0.5, -15),
				BackgroundColor3 = Library.Theme.SurfaceStrong,
				Text = "",
				PlaceholderText = tOpts.PlaceholderText or "Enter text...",
				TextColor3 = Library.Theme.Text,
				PlaceholderColor3 = Library.Theme.TextMuted,
				ClearTextOnFocus = tOpts.ClearTextOnFocus == nil and true or tOpts.ClearTextOnFocus,
				FontFace = FontStandard,
				TextSize = 14,
				Parent = Container,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 9), Parent = Box })
			Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.4, Parent = Box })
			AddConnection(Box.Focused:Connect(function() Tween(Box, { BackgroundColor3 = Library.Theme.ElementHover }, 0.14) end))
			AddConnection(Box.FocusLost:Connect(function() Tween(Box, { BackgroundColor3 = Library.Theme.SurfaceStrong }, 0.14) end))
			AddConnection(Box.FocusLost:Connect(function(enterPressed)
				if tOpts.Callback then task.spawn(tOpts.Callback, Box.Text) end
			end))

			local tb: { [string]: any } = {}
			function tb:Get() return Box.Text end
			function tb:Set(v) Box.Text = tostring(v) end
			function tb:Clear() Box.Text = "" end
			return tb
		end

		-- ------------------------------------------------------ button
		function Tab:CreateButton(bOpts)
			bOpts = bOpts or {}
			local Btn = Create("TextButton", {
				Size = UDim2.new(1, 0, 0, LAYOUT.ButtonHeight),
				BackgroundColor3 = Library.Theme.Element,
				BackgroundTransparency = 0.1,
				Text = bOpts.Name or "Button",
				TextColor3 = Library.Theme.Text,
				FontFace = FontStandard,
				TextSize = 15,
				AutoButtonColor = false,
				Parent = Tab._ParentOverride or Page,
			})
			Btn:SetAttribute("ZenSearchText", bOpts.Name or "Button")
			Corner(Btn, LAYOUT.CardRadius)
			Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.55, Parent = Btn })
			CardMotion(Btn)
			CardSheen(Btn)
			AddConnection(Btn.MouseEnter:Connect(function() Tween(Btn, { BackgroundColor3 = Library.Theme.ElementHover }, 0.2) end))
			AddConnection(Btn.MouseLeave:Connect(function() Tween(Btn, { BackgroundColor3 = Library.Theme.Element }, 0.2) end))
			AddConnection(Btn.MouseButton1Down:Connect(function() SpringTween(Btn, { Size = UDim2.new(1, -4, 0, LAYOUT.ButtonHeight - 2) }, 0.12) end))
			AddConnection(Btn.MouseButton1Up:Connect(function() Tween(Btn, { Size = UDim2.new(1, 0, 0, LAYOUT.ButtonHeight) }, 0.14) end))
			AddConnection(Btn.MouseButton1Click:Connect(function()
				if bOpts.Callback then task.spawn(bOpts.Callback) end
			end))
			local handle: { [string]: any } = {}
			function handle:Set(text) Btn.Text = tostring(text) end
			return handle
		end

		-- ------------------------------------------------------ labels
		function Tab:CreateLabel(lOpts)
			local Lbl = Create("TextLabel", {
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundTransparency = 1,
				Text = lOpts.Text or "Label",
				TextColor3 = Library.Theme.TextMuted,
				FontFace = FontStandard,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Tab._ParentOverride or Page,
			})
			local handle: { [string]: any } = {}
			function handle:Set(txt) Lbl.Text = tostring(txt) end
			return handle
		end

		function Tab:CreateParagraph(pOpts)
			local Para = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundColor3 = Library.Theme.Element,
				BackgroundTransparency = 0.1,
				Parent = Tab._ParentOverride or Page,
			})
			Para:SetAttribute("ZenSearchText", pOpts.Title or "Paragraph")
			Corner(Para, LAYOUT.CardRadius)
			Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.6, Parent = Para })
			CardMotion(Para)
			CardSheen(Para)
			local ParaRail = Create("Frame", { Size = UDim2.new(0, 3, 0, 28), Position = UDim2.new(0, 8, 0, 10), BackgroundColor3 = Library.Theme.Accent, BackgroundTransparency = 0.2, BorderSizePixel = 0, Parent = Para })
			Corner(ParaRail, 2)
			local Title = Create("TextLabel", {
				Size = UDim2.new(1, -28, 0, 26), Position = UDim2.new(0, 18, 0, 6),
				BackgroundTransparency = 1, Text = pOpts.Title or "Title", TextColor3 = Library.Theme.Text, FontFace = FontBold, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left, Parent = Para,
			})
			local Content = Create("TextLabel", {
				Size = UDim2.new(1, -28, 0, 0), Position = UDim2.new(0, 18, 0, 34),
				BackgroundTransparency = 1, Text = pOpts.Content or "Content", TextColor3 = Library.Theme.TextMuted, FontFace = FontStandard, TextSize = 13,
				TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = Para,
			})
			local function updateSize()
				local textSize = TextService:GetTextSize(Content.Text, 13, TextMeasureFont, Vector2.new(math.max(1, Para.AbsoluteSize.X - 28), 9999))
				Content.Size = UDim2.new(1, -28, 0, textSize.Y)
				Para.Size = UDim2.new(1, 0, 0, 40 + textSize.Y + 12)
			end
			updateSize()
			AddConnection(Para:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSize))
			local handle: { [string]: any } = {}
			function handle:Set(conf)
				if conf.Title then Title.Text = conf.Title end
				if conf.Content then Content.Text = conf.Content end
				updateSize()
			end
			return handle
		end

		function Tab:CreateSection(sOpts)
			local SectionFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, LAYOUT.SectionHeight), BackgroundTransparency = 1, Parent = Tab._ParentOverride or Page })
			local bar = Create("Frame", { Size = UDim2.new(0, 3, 0, 16), Position = UDim2.new(0, 0, 0.5, -8), BackgroundColor3 = Library.Theme.Accent, BackgroundTransparency = 0.1, BorderSizePixel = 0, Parent = SectionFrame })
			Corner(bar, 2)
			Create("TextLabel", {
				Size = UDim2.new(1, -14, 1, 0), Position = UDim2.new(0, 12, 0, 0),
				BackgroundTransparency = 1, Text = sOpts.Text or "Section", TextColor3 = Library.Theme.Accent, FontFace = FontBold, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left, Parent = SectionFrame,
			})
		end

		function Tab:CreateLine()
			Create("Frame", {
				Size = UDim2.new(1, -20, 0, 1),
				Position = UDim2.new(0, 10, 0, 0),
				BackgroundColor3 = Library.Theme.Border,
				Transparency = 0.5,
				Parent = Tab._ParentOverride or Page,
			})
		end

		-- ------------------------------------------------------ color picker
		function Tab:CreateColorPicker(cOpts)
			local Picker: { [string]: any } = { Value = cOpts.Color or Color3.new(1, 1, 1) }
			if cOpts.Flag then Library.Flags[cOpts.Flag] = serialize(Picker.Value) end
			local H, S, V = Picker.Value:ToHSV()
			local Expanded = false

			local Container = Create("Frame", {
				Size = UDim2.new(1, 0, 0, LAYOUT.ColorPickerHeight),
				BackgroundColor3 = Library.Theme.Element,
				BackgroundTransparency = 0.1,
				ClipsDescendants = true,
				Parent = Tab._ParentOverride or Page,
			})
			Container:SetAttribute("ZenSearchText", cOpts.Name or "Color Picker")
			Corner(Container, LAYOUT.CardRadius)
			Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.6, Parent = Container })
			CardMotion(Container)
			CardSheen(Container)

			local TopBar = Create("TextButton", { Size = UDim2.new(1, 0, 0, LAYOUT.DropdownTopH), BackgroundTransparency = 1, Text = "", Parent = Container })
			Create("TextLabel", {
				Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 14, 0, 0),
				BackgroundTransparency = 1, Text = cOpts.Name or "Color Picker", TextColor3 = Library.Theme.Text, FontFace = FontStandard, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar,
			})

			local Swatch = Create("Frame", {
				Size = UDim2.new(0, LAYOUT.ColorPickerSwatchW, 0, 24),
				Position = UDim2.new(1, -50, 0.5, -12),
				BackgroundColor3 = Picker.Value,
				Parent = TopBar,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Swatch })
			Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.3, Parent = Swatch })

			local SVMap = Create("Frame", {
				Size = UDim2.new(1, -20, 0, LAYOUT.ColorPickerSVH),
				Position = UDim2.new(0, 10, 0, 48),
				BackgroundColor3 = Color3.fromHSV(H, 1, 1),
				Parent = Container,
			})
			local SVWhite = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2, Parent = SVMap })
			Create("UIGradient", {
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
				Parent = SVWhite,
			})
			local SVBlack = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 3, Parent = SVMap })
			Create("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
				Parent = SVBlack,
			})
			local SVButton = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 4, Parent = SVMap })
			local SVMarker = Create("Frame", {
				Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(S, 0, 1 - V, 0), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 6, Parent = SVMap,
			})
			Create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 3, Transparency = 0, Parent = SVMarker })
			Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.4, Transparency = 0, Parent = SVMarker })
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SVMarker })

			local HueBar = Create("Frame", {
				Size = UDim2.new(1, -20, 0, LAYOUT.ColorPickerHueH),
				Position = UDim2.new(0, 10, 0, 52 + LAYOUT.ColorPickerSVH),
				BackgroundColor3 = Color3.new(1, 1, 1),
				Parent = Container,
			})
			Create("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
					ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
					ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
					ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
					ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
					ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
				}),
				Parent = HueBar,
			})
			local HueButton = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = HueBar })
			local HueMarker = Create("Frame", {
				Size = UDim2.new(0, 20, 0, LAYOUT.ColorPickerHueH), Position = UDim2.new(1 - H, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Picker.Value, BorderSizePixel = 0, ZIndex = 6, Parent = HueBar,
			})
			Create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2.2, Transparency = 0, Parent = HueMarker })
			Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = HueMarker })

			function Picker:Get() return self.Value end
			function Picker:Set(col, noCallback)
				self.Value = col
				if cOpts.Flag then Library.Flags[cOpts.Flag] = serialize(col) end
				H, S, V = col:ToHSV()
				Swatch.BackgroundColor3 = col
				HueMarker.BackgroundColor3 = col
				SVMap.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
				SVMarker.Position = UDim2.new(S, 0, 1 - V, 0)
				HueMarker.Position = UDim2.new(1 - H, 0, 0.5, 0)
				if not noCallback and cOpts.Callback then task.spawn(cOpts.Callback, col) end
			end

			local function UpdateColorFromInputs()
				Picker:Set(Color3.fromHSV(H % 1, S, V))
			end
			local svDragging, hueDragging = false, false
			AddConnection(SVButton.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then svDragging = true end
			end))
			AddConnection(HueButton.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hueDragging = true end
			end))
			AddConnection(UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then svDragging = false; hueDragging = false end
			end))
			AddConnection(UserInputService.InputChanged:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
				if svDragging and SVMap.AbsoluteSize.X > 0 and SVMap.AbsoluteSize.Y > 0 then
					local relX = math.clamp((input.Position.X - SVMap.AbsolutePosition.X) / SVMap.AbsoluteSize.X, 0, 1)
					local relY = math.clamp((input.Position.Y - SVMap.AbsolutePosition.Y) / SVMap.AbsoluteSize.Y, 0, 1)
					S = relX
					V = 1 - relY
					UpdateColorFromInputs()
				elseif hueDragging and HueBar.AbsoluteSize.X > 0 then
					local relX = math.clamp((input.Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
					H = 1 - relX
					UpdateColorFromInputs()
				end
			end))
			AddConnection(TopBar.MouseButton1Click:Connect(function()
				Expanded = not Expanded
				Tween(Container, { Size = Expanded and UDim2.new(1, 0, 0, LAYOUT.ColorPickerExpanded) or UDim2.new(1, 0, 0, LAYOUT.ColorPickerHeight) }, 0.2)
			end))
			if cOpts.Flag then Library.ConfigHandlers[cOpts.Flag] = function(v) if typeof(v) == "Color3" then Picker:Set(v, true) end end end
			return Picker
		end

		return Tab
	end-- built-in Settings tab
	local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "settings", Badge = "UI" })
	SettingsTab:CreateSection({ Text = "Appearance" })
	SettingsTab:CreateDropdown({
		Name = "UI Scale",
		CurrentOption = Library.UIScale <= 0.95 and "Compact" or (Library.UIScale >= 1.15 and "Large" or "Normal"),
		Options = { "Compact", "Normal", "Large" },
		Callback = function(value)
			local scales = { Compact = 0.90, Normal = 1.00, Large = 1.15 }
			Window:SetScale(scales[value] or 0.9)
		end,
	})
	SettingsTab:CreateSlider({
		Name = "Custom Scale", Min = 85, Max = 130, Default = math.floor(Library.UIScale * 100 + 0.5), Increment = 1, Suffix = "%",
		Callback = function(value) Window:SetScale(value / 100) end,
	})
	SettingsTab:CreateColorPicker({
		Name = "UI Accent", Color = Library.Theme.Accent,
		Callback = function(color) Library:SetAccentColor(color) end,
	})
	SettingsTab:CreateButton({ Name = "Reset Accent", Callback = function() Library:ResetAccentColor() end })
	SettingsTab:CreateSection({ Text = "Window" })
	SettingsTab:CreateSlider({
		Name = "Window Width", Min = MinWindowWidth, Max = MaxWindowWidth, Default = BaseWindowWidth, Increment = 10, Suffix = "px",
		Callback = function(value) Window:SetSize(value, BaseWindowHeight) end,
	})
	SettingsTab:CreateSlider({
		Name = "Window Height", Min = MinWindowHeight, Max = MaxWindowHeight, Default = BaseWindowHeight, Increment = 10, Suffix = "px",
		Callback = function(value) Window:SetSize(BaseWindowWidth, value) end,
	})
	SettingsTab:CreateButton({ Name = "Reset Window Size", Callback = function() Window:SetSize(1100, 640) end })
	SettingsTab:CreateParagraph({ Title = "Resizable UI", Content = "Drag the corner grip to resize the window. Settings ships in every ZenUI window." })

	return Window
end

-- ------------------------------------------------------------------ notify
function Library:Notify(options)
	options = options or {}
	if not Library.NotificationContainer then return end
	local Notif = Create("Frame", {
		Size = UDim2.new(1, 0, 0, LAYOUT.NotifyH),
		BackgroundTransparency = 1,
		Parent = Library.NotificationContainer,
	})
	local NotifScale = Create("UIScale", { Scale = 0.9, Parent = Notif })
	local Inner = Create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 40, 0, 0),
		BackgroundColor3 = Library.Theme.SurfaceStrong,
		BackgroundTransparency = 0.2,
		ClipsDescendants = true,
		Parent = Notif,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = Inner })
	Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.55, Parent = Inner })
	local NotifRail = Create("Frame", {
		Size = UDim2.new(0, 4, 0, 38),
		Position = UDim2.new(0, 10, 0.5, -19),
		BackgroundColor3 = Library.Theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = Inner,
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = NotifRail })
	local NotifGlow = Create("Frame", {
		Size = UDim2.new(0.9, 0, 0, 2),
		Position = UDim2.new(0.5, 0, 1, -1),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Library.Theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = Inner,
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = NotifGlow })
	Create("TextLabel", {
		Size = UDim2.new(1, -28, 0, 22), Position = UDim2.new(0, 24, 0, 8),
		BackgroundTransparency = 1, Text = options.Title or "Notification", TextColor3 = Library.Theme.Text, FontFace = FontBold, TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = Inner,
	})
	Create("TextLabel", {
		Size = UDim2.new(1, -28, 0, 22), Position = UDim2.new(0, 24, 0, 32),
		BackgroundTransparency = 1, Text = options.Content or "", TextColor3 = Library.Theme.TextMuted, FontFace = FontStandard, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = Inner,
	})
	Tween(Inner, { BackgroundTransparency = 0.2, Position = UDim2.new(0, 0, 0, 0) }, 0.32)
	SpringTween(NotifScale, { Scale = 1 }, 0.32)
	Tween(NotifRail, { BackgroundTransparency = 0.05 }, 0.4)
	Tween(NotifGlow, { BackgroundTransparency = 0.6 }, 0.5)
	task.spawn(function()
		pcall(function()
			task.wait(options.Duration or 3.5)
			if not Notif.Parent then return end
			Tween(Inner, { BackgroundTransparency = 1, Position = UDim2.new(0, 40, 0, 0) }, 0.4)
			task.wait(0.45)
			if Notif.Parent then Notif:Destroy() end
		end)
	end)
end

function Library:CreateNotify(options)
	self:Notify(options)
end

return Library