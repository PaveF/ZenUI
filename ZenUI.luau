--!nonstrict
-- ZenUI - Rayfield-style UI library for the Real executor
-- Usage:
--   local Library = (loadstring or require)(...)
--   local lib = Library.new({ Name = "My Hub", Theme = "Midnight" })
--   lib:SetTheme("Aurora") -- live-switch any built-in theme
--   print(table.concat(lib:GetThemes(), ", "))
--   local Window = lib:CreateWindow({ Name = "My Hub", ConfigurationSaving = true })
--   local Tab = Window:CreateTab({ Name = "Main" })
--   Tab:CreateToggle({ Name = "Speed", CurrentValue = false, Callback = function(v) end, Keybind = "F", Flag = "Speed" })
--   lib:SaveConfig("main"); lib:LoadConfig("main")

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local getgenv = getgenv or function() return _G end

local function safe_gethui()
	local ok, res = pcall(function() return getgenv().gethui() end)
	if ok and res then return res end
	ok, res = pcall(function() return getgenv().get_hidden_gui() end)
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

-- Try filesystem API from getgenv() first, then the real globals, then _G.
local writefile = (type(getgenv().writefile) == "function") and getgenv().writefile
	or (type(rawget(_G, "writefile")) == "function" and rawget(_G, "writefile")) or nil
local readfile = (type(getgenv().readfile) == "function") and getgenv().readfile
	or (type(rawget(_G, "readfile")) == "function" and rawget(_G, "readfile")) or nil
local isfile = (type(getgenv().isfile) == "function") and getgenv().isfile
	or (type(rawget(_G, "isfile")) == "function" and rawget(_G, "isfile")) or nil
local isfolder = (type(getgenv().isfolder) == "function") and getgenv().isfolder
	or (type(rawget(_G, "isfolder")) == "function" and rawget(_G, "isfolder")) or nil
local makefolder = (type(getgenv().makefolder) == "function") and getgenv().makefolder
	or (type(rawget(_G, "makefolder")) == "function" and rawget(_G, "makefolder")) or nil
local listfiles = (type(getgenv().listfiles) == "function") and getgenv().listfiles
	or (type(rawget(_G, "listfiles")) == "function" and rawget(_G, "listfiles")) or nil
local delfile = (type(getgenv().delfile) == "function") and getgenv().delfile
	or (type(rawget(_G, "delfile")) == "function" and rawget(_G, "delfile")) or nil

local Themes = {
	Emerald = {
		Background = Color3.fromRGB(13, 16, 20),
		Sidebar = Color3.fromRGB(16, 20, 25),
		Element = Color3.fromRGB(22, 27, 33),
		ElementHover = Color3.fromRGB(31, 38, 46),
		Accent = Color3.fromRGB(104, 232, 164),
		Text = Color3.fromRGB(245, 248, 250),
		TextMuted = Color3.fromRGB(146, 157, 169),
		Border = Color3.fromRGB(46, 58, 69),
		Glow = Color3.fromRGB(69, 199, 137),
		Surface = Color3.fromRGB(19, 24, 30),
		SurfaceStrong = Color3.fromRGB(27, 33, 41),
	},
	Midnight = {
		Background = Color3.fromRGB(10, 11, 18),
		Sidebar = Color3.fromRGB(14, 15, 25),
		Element = Color3.fromRGB(20, 22, 34),
		ElementHover = Color3.fromRGB(31, 34, 51),
		Accent = Color3.fromRGB(121, 120, 255),
		Text = Color3.fromRGB(242, 242, 255),
		TextMuted = Color3.fromRGB(149, 151, 175),
		Border = Color3.fromRGB(48, 50, 73),
		Glow = Color3.fromRGB(98, 96, 224),
		Surface = Color3.fromRGB(16, 18, 29),
		SurfaceStrong = Color3.fromRGB(24, 27, 41),
	},
	Rose = {
		Background = Color3.fromRGB(19, 14, 18),
		Sidebar = Color3.fromRGB(25, 17, 23),
		Element = Color3.fromRGB(35, 23, 31),
		ElementHover = Color3.fromRGB(50, 31, 42),
		Accent = Color3.fromRGB(255, 110, 163),
		Text = Color3.fromRGB(255, 243, 248),
		TextMuted = Color3.fromRGB(177, 146, 161),
		Border = Color3.fromRGB(73, 45, 60),
		Glow = Color3.fromRGB(219, 79, 131),
		Surface = Color3.fromRGB(29, 20, 27),
		SurfaceStrong = Color3.fromRGB(42, 28, 37),
	},
	Ocean = {
		Background = Color3.fromRGB(9, 18, 25),
		Sidebar = Color3.fromRGB(11, 24, 33),
		Element = Color3.fromRGB(16, 34, 45),
		ElementHover = Color3.fromRGB(23, 47, 60),
		Accent = Color3.fromRGB(74, 208, 255),
		Text = Color3.fromRGB(238, 250, 255),
		TextMuted = Color3.fromRGB(139, 168, 181),
		Border = Color3.fromRGB(37, 67, 81),
		Glow = Color3.fromRGB(41, 162, 207),
		Surface = Color3.fromRGB(13, 29, 38),
		SurfaceStrong = Color3.fromRGB(20, 42, 55),
	},
	Amber = {
		Background = Color3.fromRGB(20, 17, 11),
		Sidebar = Color3.fromRGB(28, 22, 12),
		Element = Color3.fromRGB(38, 29, 15),
		ElementHover = Color3.fromRGB(53, 41, 20),
		Accent = Color3.fromRGB(255, 190, 76),
		Text = Color3.fromRGB(255, 249, 237),
		TextMuted = Color3.fromRGB(181, 160, 116),
		Border = Color3.fromRGB(78, 60, 29),
		Glow = Color3.fromRGB(207, 144, 35),
		Surface = Color3.fromRGB(33, 25, 13),
		SurfaceStrong = Color3.fromRGB(48, 37, 18),
	},
	Aurora = {
		Background = Color3.fromRGB(10, 17, 18),
		Sidebar = Color3.fromRGB(12, 24, 24),
		Element = Color3.fromRGB(17, 33, 33),
		ElementHover = Color3.fromRGB(23, 48, 45),
		Accent = Color3.fromRGB(82, 239, 202),
		Text = Color3.fromRGB(239, 255, 252),
		TextMuted = Color3.fromRGB(135, 177, 169),
		Border = Color3.fromRGB(34, 69, 63),
		Glow = Color3.fromRGB(42, 190, 157),
		Surface = Color3.fromRGB(14, 28, 29),
		SurfaceStrong = Color3.fromRGB(21, 43, 41),
	},
	Violet = {
		Background = Color3.fromRGB(15, 12, 22),
		Sidebar = Color3.fromRGB(21, 16, 30),
		Element = Color3.fromRGB(29, 22, 40),
		ElementHover = Color3.fromRGB(43, 32, 58),
		Accent = Color3.fromRGB(190, 122, 255),
		Text = Color3.fromRGB(248, 242, 255),
		TextMuted = Color3.fromRGB(167, 146, 190),
		Border = Color3.fromRGB(62, 46, 82),
		Glow = Color3.fromRGB(143, 86, 202),
		Surface = Color3.fromRGB(25, 19, 35),
		SurfaceStrong = Color3.fromRGB(37, 28, 51),
	},
	Mono = {
		Background = Color3.fromRGB(14, 14, 16),
		Sidebar = Color3.fromRGB(19, 19, 22),
		Element = Color3.fromRGB(27, 27, 31),
		ElementHover = Color3.fromRGB(40, 40, 45),
		Accent = Color3.fromRGB(224, 224, 229),
		Text = Color3.fromRGB(248, 248, 250),
		TextMuted = Color3.fromRGB(157, 157, 165),
		Border = Color3.fromRGB(52, 52, 58),
		Glow = Color3.fromRGB(170, 170, 180),
		Surface = Color3.fromRGB(22, 22, 25),
		SurfaceStrong = Color3.fromRGB(34, 34, 38),
	},
}

Themes.Blue = Themes.Midnight

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
	ConfigFolder = "UI_Configs",
	ConfigurationSaving = false,
}

local FontStandard = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local FontBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)

local Create

local function Stroke(parent, color, transparency, thickness)
	return Create("UIStroke", { Color = color or Library.Theme.Border, Transparency = transparency or 0.25, Thickness = thickness or 1, Parent = parent })
end

local function Corner(parent, radius)
	return Create("UICorner", { CornerRadius = UDim.new(0, radius or 10), Parent = parent })
end

local function GlowDot(parent, size, position, color, transparency)
	local dot = Create("Frame", { Size = UDim2.new(0, size, 0, size), Position = position, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = color or Library.Theme.Accent, BackgroundTransparency = transparency or 0.25, BorderSizePixel = 0, Parent = parent })
	Corner(dot, size)
	return dot
end

local function Log(...)
	if Library.Debug then
		print("[Lib]", ...)
	end
end

local function AddConnection(conn: RBXScriptConnection)
	if conn then table.insert(Library.Connections, conn) end
	return conn
end

local function AddInstance(inst: Instance)
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

	-- Tag palette-bound properties so SetTheme can recolor the live UI safely.
	for propertyName, value in pairs({
		BackgroundColor3 = properties.BackgroundColor3,
		TextColor3 = properties.TextColor3,
		PlaceholderColor3 = properties.PlaceholderColor3,
		ScrollBarImageColor3 = properties.ScrollBarImageColor3,
		Color = properties.Color,
	}) do
		if typeof(value) == "Color3" then
			for role, paletteValue in pairs(Library.Theme) do
				if typeof(paletteValue) == "Color3" and value == paletteValue then
					pcall(function() inst:SetAttribute("ZenThemeRole_" .. role, true) end)
				end
			end
		end
	end

	if properties.Parent then
		inst.Parent = properties.Parent
	end
	return inst
end

local function ThemeColor(role: string): Color3
	return Library.Theme[role] or Library.Theme.Background
end

function Library:SetTheme(name: string)
	local palette = Themes[name]
	if not palette then
		return false
	end
	Library.ThemeName = name
	Library.Theme = table.clone(palette)
	local root = Library.ScreenGui
	if root then
		local gradient = root:FindFirstChild("MainWindow") and root.MainWindow:FindFirstChildOfClass("UIGradient")
		if gradient and gradient:GetAttribute("ZenGradient") then
			pcall(function() gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, palette.Element),
				ColorSequenceKeypoint.new(0.55, palette.Background),
				ColorSequenceKeypoint.new(1, palette.Sidebar),
			}) end)
		end
		for _, inst in ipairs(root:GetDescendants()) do
			for role, value in pairs(palette) do
				if typeof(value) == "Color3" and inst:GetAttribute("ZenThemeRole_" .. role) then
					pcall(function()
						if inst:IsA("UIStroke") then
							inst.Color = value
						elseif inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
							if role == "Text" or role == "TextMuted" then inst.TextColor3 = value end
							if role == "TextMuted" then pcall(function() inst.PlaceholderColor3 = value end) end
						elseif role == "Glow" then
							inst.BackgroundColor3 = value
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

local function AddAccentRail(parent: GuiObject)
	local rail = Create("Frame", {
		Size = UDim2.new(0, 2, 0, 20),
		Position = UDim2.new(0, 0, 0.5, -10),
		BackgroundColor3 = Library.Theme.Accent,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Parent = parent,
	})
	Corner(rail, 2)
	return rail
end

local function FadeRecursive(root: Instance, transparency: number, duration: number?)
	for _, inst in ipairs(root:GetDescendants()) do
		if inst:IsA("GuiObject") then
			if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
				Tween(inst, {TextTransparency = transparency}, duration or 0.18)
			end
			if inst.BackgroundTransparency < 1 then
				Tween(inst, {BackgroundTransparency = math.max(inst.BackgroundTransparency, transparency)}, duration or 0.18)
			end
		elseif inst:IsA("UIStroke") then
			Tween(inst, {Transparency = math.min(1, math.max(inst.Transparency, transparency))}, duration or 0.18)
		end
	end
end

-- Serialize a value so it survives JSON roundtrips (Color3 -> "#hex"-style array).
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
			return Color3.fromRGB(v[2], v[3], v[4])
		end
		local out = {}
		for k, val in pairs(v) do
			out[k] = deserialize(val)
		end
		return out
	end
	return v
end

function Library:GetThemes()
	local out = {}
	for name in pairs(Themes) do
		table.insert(out, name)
	end
	table.sort(out)
	return out
end

function Library:GetTheme()
	return Library.ThemeName
end

function Library:Destroy()
	Log("Destroying previous UI instance...")
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
	Log("destroyed")
end

-- Top-level re-entry guard: re-running the file must not stack a second menu.
if getgenv().Library and type(getgenv().Library.Destroy) == "function" then
	pcall(function() getgenv().Library:Destroy() end)
end
getgenv().Library = Library

function Library.new(settings)
	settings = settings or {}
	if Library.ScreenGui then
		Library:Destroy()
	end
	Library.Debug = settings.Debug or false
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
		Position = UDim2.new(1, -320, 1, -20),
		Size = UDim2.new(0, 300, 1, 0),
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

	local LoadingFrame = Create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Library.Theme.Background,
		BackgroundTransparency = 1,
		Parent = ScreenGui,
		ZIndex = 100,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 0), Parent = LoadingFrame })
	local LoadingText = Create("TextLabel", {
		Size = UDim2.new(0, 300, 0, 50),
		Position = UDim2.new(0.5, -150, 0.5, -25),
		BackgroundTransparency = 1,
		Text = settings.Name or "Rayfield UI",
		TextColor3 = Library.Theme.Text,
		TextTransparency = 1,
		FontFace = FontBold,
		TextSize = 24,
		Parent = LoadingFrame,
	})

	task.spawn(function()
		pcall(function()
			Tween(LoadingFrame, { BackgroundTransparency = 0 }, 0.3)
			Tween(LoadingText, { TextTransparency = 0 }, 0.3)
			task.wait(1.2)
			Tween(LoadingFrame, { BackgroundTransparency = 1 }, 0.3)
			Tween(LoadingText, { TextTransparency = 1 }, 0.3)
			task.wait(0.3)
			if LoadingFrame.Parent then
				LoadingFrame:Destroy()
			end
		end)
	end)

	Log("loaded OK")
	return Library
end

-- ============================= Config (filesystem) =============================

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
		local ok, err = safe_call(writefile, path, json)
		if not ok then Log("SaveConfig failed to write:", err) end
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

function Library:SaveConfig(name)
	WriteConfig(name)
	Log("config saved:", name)
end

function Library:LoadConfig(name)
	LoadConfig(name)
	Log("config loaded:", name)
end

function Library:DeleteConfig(name)
	if type(delfile) ~= "function" then return end
	local path = tostring(Library.ConfigFolder) .. "/" .. tostring(name) .. ".json"
	safe_call(delfile, path)
	Log("config deleted:", name)
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
end

-- ============================= Window =============================

function Library:CreateWindow(options)
	options = options or {}
	if Library.MainFrame then
		Library:Destroy()
	end

	local Window: { [string]: any } = {
		Tabs = {},
		CurrentTab = nil,
		Elements = {},
	}

	Library.ConfigurationSaving = options.ConfigurationSaving or false
	Library.ConfigFolder = options.ConfigFolder or "UI_Configs"
	local ToggleKeybind = options.Keybind or Enum.KeyCode.Insert

	local MainFrame = Create("Frame", {
		Name = "MainWindow",
		Size = UDim2.new(0, 900, 0, 570),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = Library.Theme.Background,
		ClipsDescendants = true,
		BackgroundTransparency = 1,
		Parent = Library.ScreenGui,
	})
	AddInstance(MainFrame)
	Library.MainFrame = MainFrame
	Corner(MainFrame, 18)
	Stroke(MainFrame, Library.Theme.Border, 0.08, 1.4)

	local WindowGradient = Create("UIGradient", {
		Rotation = 135,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Library.Theme.SurfaceStrong or Library.Theme.Element),
			ColorSequenceKeypoint.new(0.45, Library.Theme.Background),
			ColorSequenceKeypoint.new(1, Library.Theme.Sidebar),
		}),
		Parent = MainFrame,
	})
	pcall(function() WindowGradient:SetAttribute("ZenGradient", true) end)

	local MainScale = Create("UIScale", { Scale = 0.90, Parent = MainFrame })
	local MainShadow = Create("Frame", {
		Name = "Shadow",
		Size = UDim2.new(1, 42, 1, 42),
		Position = UDim2.new(0.5, -21, 0.5, -21),
		BackgroundColor3 = Library.Theme.Glow,
		BackgroundTransparency = 0.965,
		BorderSizePixel = 0,
		ZIndex = 0,
		Parent = MainFrame,
	})
	Corner(MainShadow, 30)

	local AmbientA = GlowDot(MainFrame, 220, UDim2.new(1, 0, 0, 86), Library.Theme.Accent, 0.965)
	local AmbientB = GlowDot(MainFrame, 180, UDim2.new(0, 5, 1, -30), Library.Theme.Glow, 0.968)
	local AmbientC = GlowDot(MainFrame, 110, UDim2.new(0.48, 0, 0.2, 0), Library.Theme.Accent, 0.978)
	AmbientA.ZIndex, AmbientB.ZIndex, AmbientC.ZIndex = 0, 0, 0

	task.spawn(function()
		while MainFrame.Parent do
			Tween(AmbientA, { Position = UDim2.new(1, -35, 0, 64) }, 3.4)
			Tween(AmbientB, { Position = UDim2.new(0, 34, 1, -58) }, 3.1)
			Tween(AmbientC, { Position = UDim2.new(0.52, 0, 0.28, 0) }, 2.8)
			task.wait(3.4)
			Tween(AmbientA, { Position = UDim2.new(1, 18, 0, 105) }, 3.4)
			Tween(AmbientB, { Position = UDim2.new(0, 0, 1, -18) }, 3.1)
			Tween(AmbientC, { Position = UDim2.new(0.42, 0, 0.13, 0) }, 2.8)
			task.wait(3.4)
		end
	end)

	local Header = Create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundColor3 = Library.Theme.Surface or Library.Theme.Element,
		BackgroundTransparency = 0.10,
		Active = true,
		Parent = MainFrame,
	})
	Create("UIGradient", {
		Rotation = 0,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Library.Theme.SurfaceStrong or Library.Theme.Element),
			ColorSequenceKeypoint.new(1, Library.Theme.Surface or Library.Theme.Element),
		}),
		Transparency = NumberSequence.new(0.08),
		Parent = Header,
	})

	local BrandIcon = Create("Frame", {
		Size = UDim2.new(0, 36, 0, 36),
		Position = UDim2.new(0, 16, 0, 13),
		BackgroundColor3 = Library.Theme.Accent,
		Parent = Header,
	})
	Corner(BrandIcon, 11)
	local BrandIconScale = Create("UIScale", { Scale = 1, Parent = BrandIcon })
	Create("TextLabel", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "✦", TextColor3 = Library.Theme.Background, FontFace = FontBold, TextSize = 18, Parent = BrandIcon })

	Create("TextLabel", {
		Size = UDim2.new(0, 270, 0, 22),
		Position = UDim2.new(0, 62, 0, 10),
		BackgroundTransparency = 1,
		Text = options.Name or "ZenUI",
		TextColor3 = Library.Theme.Text,
		FontFace = FontBold,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Header,
	})
	Create("TextLabel", {
		Size = UDim2.new(0, 270, 0, 16),
		Position = UDim2.new(0, 62, 0, 31),
		BackgroundTransparency = 1,
		Text = "Adaptive interface",
		TextColor3 = Library.Theme.TextMuted,
		FontFace = FontStandard,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Header,
	})

	local SearchBox = Create("TextBox", {
		Name = "CommandSearch",
		Size = UDim2.new(0, 270, 0, 36),
		Position = UDim2.new(0.5, -135, 0.5, -18),
		BackgroundColor3 = Library.Theme.Background,
		BackgroundTransparency = 0.18,
		Text = "",
		PlaceholderText = "Search tabs...   Ctrl + K",
		TextColor3 = Library.Theme.Text,
		PlaceholderColor3 = Library.Theme.TextMuted,
		ClearTextOnFocus = false,
		FontFace = FontStandard,
		TextSize = 12,
		Parent = Header,
	})
	Corner(SearchBox, 10)
	Stroke(SearchBox, Library.Theme.Border, 0.35, 1)

	local MinimizeButton, CloseButton
	local ThemeMini, CycleTheme
	local dragInput, dragging, dragStart, startPos
	local function IsOverGui(guiObject, pos)
		if not guiObject or not guiObject.Visible then return false end
		local p, z = guiObject.AbsolutePosition, guiObject.AbsoluteSize
		return pos.X >= p.X and pos.X <= p.X + z.X and pos.Y >= p.Y and pos.Y <= p.Y + z.Y
	end
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
	end))

	local function MakeHeaderButton(name, text, xOffset)
		local b = Create("TextButton", {
			Name = name, Size = UDim2.new(0, 32, 0, 32), Position = UDim2.new(1, xOffset, 0.5, -16),
			BackgroundColor3 = Library.Theme.Element, Text = text, TextColor3 = Library.Theme.TextMuted,
			FontFace = FontBold, TextSize = 14, AutoButtonColor = false, Parent = Header,
		})
		Corner(b, 10); Stroke(b, Library.Theme.Border, 0.42, 1)
		AddConnection(b.MouseEnter:Connect(function() SpringTween(b, {Size = UDim2.new(0,35,0,35), Position = UDim2.new(1,xOffset-1.5,0.5,-17.5), BackgroundColor3 = Library.Theme.ElementHover}, 0.16) end))
		AddConnection(b.MouseLeave:Connect(function() Tween(b, {Size = UDim2.new(0,32,0,32), Position = UDim2.new(1,xOffset,0.5,-16), BackgroundColor3 = Library.Theme.Element}, 0.14) end))
		return b
	end
	local ThemeButton = MakeHeaderButton("Theme", "◌", -110)
	MinimizeButton = MakeHeaderButton("Minimize", "—", -72)
	CloseButton = MakeHeaderButton("Close", "×", -34)

	CycleTheme = function()
		local names = Library:GetThemes()
		local idx = table.find(names, Library.ThemeName) or 1
		Library:SetTheme(names[(idx % #names) + 1])
		if ThemeMini then ThemeMini.Text = Library.ThemeName end
	end
	AddConnection(ThemeButton.MouseButton1Click:Connect(CycleTheme))
	AddConnection(BrandIcon.MouseEnter:Connect(function() SpringTween(BrandIconScale, {Scale = 1.08}, 0.22) end))
	AddConnection(BrandIcon.MouseLeave:Connect(function() SpringTween(BrandIconScale, {Scale = 1}, 0.18) end))

	local HeaderGlow = Create("Frame", { Size = UDim2.new(1,-32,0,2), Position = UDim2.new(0,16,1,-2), BackgroundColor3 = Library.Theme.Accent, BackgroundTransparency = 0.12, BorderSizePixel = 0, Parent = Header })
	task.spawn(function() while HeaderGlow.Parent do Tween(HeaderGlow,{BackgroundTransparency=0.38},1.0); task.wait(1.0); Tween(HeaderGlow,{BackgroundTransparency=0.05},1.0); task.wait(1.0) end end)

	local SidebarWidth = 214
	local Sidebar = Create("Frame", {
		Name = "Sidebar", Size = UDim2.new(0, SidebarWidth, 1, -62), Position = UDim2.new(0,0,0,62),
		BackgroundColor3 = Library.Theme.Sidebar, BackgroundTransparency = 0.08, BorderSizePixel = 0, Parent = MainFrame,
	})
	Corner(Sidebar, 14); Stroke(Sidebar, Library.Theme.Border, 0.42, 1)

	local Brand = Create("Frame", { Size = UDim2.new(1,-24,0,56), Position = UDim2.new(0,12,0,12), BackgroundColor3 = Library.Theme.SurfaceStrong or Library.Theme.Element, Parent = Sidebar })
	Corner(Brand, 12); Stroke(Brand, Library.Theme.Border, 0.46, 1)
	local BrandMarker = AddAccentRail(Brand)
	Create("TextLabel", { Size=UDim2.new(1,-24,0,16), Position=UDim2.new(0,14,0,9), BackgroundTransparency=1, Text="NAVIGATION", TextColor3=Library.Theme.TextMuted, FontFace=FontBold, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, Parent=Brand })
	Create("TextLabel", { Name="BrandHint", Size=UDim2.new(1,-24,0,22), Position=UDim2.new(0,14,0,24), BackgroundTransparency=1, Text="Control panel", TextColor3=Library.Theme.Text, FontFace=FontBold, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, Parent=Brand })

	local CollapseButton = Create("TextButton", { Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,-40,0,26), BackgroundColor3=Library.Theme.Element, Text="‹", TextColor3=Library.Theme.TextMuted, FontFace=FontBold, TextSize=17, AutoButtonColor=false, Parent=Sidebar })
	Corner(CollapseButton, 9); Stroke(CollapseButton, Library.Theme.Border, 0.5, 1)
	local Collapsed = false

	local TabContainer = Create("ScrollingFrame", { Name="TabContainer", Size=UDim2.new(1,-12,1,-92), Position=UDim2.new(0,6,0,78), BackgroundTransparency=1, ScrollBarThickness=0, CanvasSize=UDim2.new(0,0,0,0), Parent=Sidebar })
	local TabListLayout = Create("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,7), HorizontalAlignment=Enum.HorizontalAlignment.Center, Parent=TabContainer })
	AddConnection(TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() TabContainer.CanvasSize=UDim2.new(0,0,0,TabListLayout.AbsoluteContentSize.Y+10) end))

	local SidebarFooter = Create("Frame", { Size=UDim2.new(1,-24,0,46), Position=UDim2.new(0,12,1,-58), BackgroundColor3=Library.Theme.Element, BackgroundTransparency=0.22, BorderSizePixel=0, Parent=Sidebar })
	Corner(SidebarFooter,11); Stroke(SidebarFooter,Library.Theme.Border,0.55,1)
	local FooterDot = GlowDot(SidebarFooter,8,UDim2.new(0,14,0.5,0),Library.Theme.Accent,0.08)
	local FooterText = Create("TextLabel", { Size=UDim2.new(1,-34,0,18), Position=UDim2.new(0,28,0,6), BackgroundTransparency=1, Text="UI ENGINE", TextColor3=Library.Theme.TextMuted, FontFace=FontBold, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, Parent=SidebarFooter })
	Create("TextLabel", { Size=UDim2.new(1,-34,0,16), Position=UDim2.new(0,28,0,23), BackgroundTransparency=1, Text="ZenUI Core", TextColor3=Library.Theme.Text, FontFace=FontBold, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, Parent=SidebarFooter })
	task.spawn(function() while FooterDot.Parent do Tween(FooterDot,{BackgroundTransparency=0.38},0.9); task.wait(0.9); Tween(FooterDot,{BackgroundTransparency=0.06},0.9); task.wait(0.9) end end)

	local ContentContainer = Create("Frame", { Name="ContentContainer", Size=UDim2.new(1,-SidebarWidth,1,-62), Position=UDim2.new(0,SidebarWidth,0,62), BackgroundTransparency=1, Parent=MainFrame })
	local ContentTop = Create("Frame", { Size=UDim2.new(1,-28,0,48), Position=UDim2.new(0,14,0,10), BackgroundColor3=Library.Theme.Surface or Library.Theme.Element, BackgroundTransparency=0.10, BorderSizePixel=0, Parent=ContentContainer })
	Corner(ContentTop,12); Stroke(ContentTop,Library.Theme.Border,0.45,1)
	local TopSheen = Create("Frame", { Size=UDim2.new(0,2,1,-12), Position=UDim2.new(0,6,0,6), BackgroundColor3=Library.Theme.Accent, BackgroundTransparency=0.18, BorderSizePixel=0, Parent=ContentTop })
	Corner(TopSheen,2)
	task.spawn(function() while TopSheen.Parent do Tween(TopSheen,{BackgroundTransparency=0.48},1.1); task.wait(1.1); Tween(TopSheen,{BackgroundTransparency=0.10},1.1); task.wait(1.1) end end)
	local PageKicker = Create("TextLabel", { Size=UDim2.new(1,-220,0,15), Position=UDim2.new(0,14,0,7), BackgroundTransparency=1, Text="WORKSPACE", TextColor3=Library.Theme.TextMuted, FontFace=FontBold, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, Parent=ContentTop })
	local CurrentPageLabel = Create("TextLabel", { Size=UDim2.new(1,-220,0,22), Position=UDim2.new(0,14,0,20), BackgroundTransparency=1, Text="Select a tab", TextColor3=Library.Theme.Text, FontFace=FontBold, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, Parent=ContentTop })
	ThemeMini = Create("TextButton", { Size=UDim2.new(0,100,0,30), Position=UDim2.new(1,-112,0.5,-15), BackgroundColor3=Library.Theme.Element, Text=Library.ThemeName, TextColor3=Library.Theme.Accent, FontFace=FontBold, TextSize=10, AutoButtonColor=false, Parent=ContentTop })
	Corner(ThemeMini,9); Stroke(ThemeMini,Library.Theme.Border,0.45,1)
	AddConnection(ThemeMini.MouseButton1Click:Connect(CycleTheme))

	local WindowState = { Minimized=false, Closed=false }
	local RestoreHeight = 570
	local ReopenButton = Create("TextButton", { Name="ReopenButton", Size=UDim2.new(0,58,0,58), AnchorPoint=Vector2.new(1,1), Position=UDim2.new(1,-24,1,-24), BackgroundColor3=Library.Theme.Element, Text="Z", TextColor3=Library.Theme.Accent, FontFace=FontBold, TextSize=21, AutoButtonColor=false, Visible=false, ZIndex=200, Parent=Library.ScreenGui })
	AddInstance(ReopenButton); Corner(ReopenButton,18); Stroke(ReopenButton,Library.Theme.Border,0.12,1.3)
	local ReopenScale=Create("UIScale",{Scale=0.7,Parent=ReopenButton})
	local function ShowLauncher() ReopenButton.Visible=true; SpringTween(ReopenScale,{Scale=1},0.35) end
	local function HideLauncher() SpringTween(ReopenScale,{Scale=0.7},0.18); task.delay(0.18,function() if ReopenButton.Parent then ReopenButton.Visible=false end end) end

	local function RestoreWindow() WindowState.Minimized=false; Sidebar.Visible=true; ContentContainer.Visible=true; SpringTween(MainFrame,{Size=UDim2.new(0,900,0,RestoreHeight)},0.34); end
	function WindowState:Minimize() if WindowState.Closed or WindowState.Minimized then return end; WindowState.Minimized=true; Sidebar.Visible=false; ContentContainer.Visible=false; SpringTween(MainFrame,{Size=UDim2.new(0,900,0,62)},0.34) end
	local function CloseWindow() if WindowState.Closed then return end; WindowState.Closed=true; Tween(MainFrame,{BackgroundTransparency=1},0.18); SpringTween(MainScale,{Scale=0.9},0.22); task.delay(0.22,function() if MainFrame.Parent and WindowState.Closed then MainFrame.Visible=false; ShowLauncher() end end) end
	AddConnection(MinimizeButton.MouseButton1Click:Connect(function() if WindowState.Minimized then RestoreWindow() else WindowState:Minimize() end end))
	AddConnection(CloseButton.MouseButton1Click:Connect(CloseWindow))
	AddConnection(ReopenButton.MouseEnter:Connect(function() SpringTween(ReopenButton,{Size=UDim2.new(0,64,0,64),BackgroundColor3=Library.Theme.ElementHover},0.16) end))
	AddConnection(ReopenButton.MouseLeave:Connect(function() Tween(ReopenButton,{Size=UDim2.new(0,58,0,58),BackgroundColor3=Library.Theme.Element},0.14) end))
	AddConnection(ReopenButton.MouseButton1Click:Connect(function() WindowState.Closed=false; WindowState.Minimized=false; HideLauncher(); MainFrame.Visible=true; MainFrame.BackgroundTransparency=1; MainScale.Scale=0.88; Sidebar.Visible=true; ContentContainer.Visible=true; SpringTween(MainScale,{Scale=1},0.38); Tween(MainFrame,{BackgroundTransparency=0},0.22) end))

	local WindowVisible=true
	local function ShowWindow() WindowVisible=true; WindowState.Closed=false; MainFrame.Visible=true; Sidebar.Visible=not WindowState.Minimized; ContentContainer.Visible=not WindowState.Minimized; MainFrame.BackgroundTransparency=0; SpringTween(MainScale,{Scale=1},0.28) end
	local function HideWindow() WindowVisible=false; Tween(MainFrame,{BackgroundTransparency=1},0.2); Tween(MainScale,{Scale=0.94},0.22); task.delay(0.23,function() if not WindowVisible and MainFrame.Parent then MainFrame.Visible=false end end) end
	function Window:Minimize() WindowState:Minimize() end
	function Window:Restore() RestoreWindow() end
	function Window:ToggleMinimize() if WindowState.Minimized then RestoreWindow() else WindowState:Minimize() end end
	function Window:Close() CloseWindow() end
	function Window:SetVisible(state) if state then ShowWindow() else HideWindow() end end
	function Window:CycleTheme() CycleTheme() end

	AddConnection(UserInputService.InputBegan:Connect(function(input,gpe)
		if gpe or Library.ListeningKeybind then return end
		if input.KeyCode == ToggleKeybind then if WindowVisible then HideWindow() else ShowWindow() end end
		if input.KeyCode == Enum.KeyCode.K and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then SearchBox:CaptureFocus() end
	end))
	AddConnection(SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local query=string.lower(SearchBox.Text or "")
		for _, entry in ipairs(Window.Tabs) do
			local label=string.lower(tostring(entry.Name or ""))
			entry.Button.Visible = query=="" or string.find(label,query,1,true)~=nil
		end
		if Window.CurrentTab and Window.CurrentTab.Page then
			for _, child in ipairs(Window.CurrentTab.Page:GetChildren()) do
				if child:IsA("GuiObject") and child:GetAttribute("ZenSearchText") then
					child.Visible = query=="" or string.find(string.lower(child:GetAttribute("ZenSearchText")),query,1,true)~=nil
				end
			end
		end
	end))

	function Window:Destroy() Library:Destroy() end

	task.spawn(function()
		if MainFrame.Parent then
			Tween(MainFrame,{BackgroundTransparency=0},0.26); SpringTween(MainScale,{Scale=1},0.48)
		end
	end)

	-- ============================= Tabs =============================

	function Window:CreateTab(tabOptions)
		tabOptions = tabOptions or {}
		local Tab: { [string]: any } = { Elements = {} }
		local TabName = tabOptions.Name or "Tab"
		local TabIconText = tabOptions.Icon or "◆"

		local TabButton = Create("TextButton", {
			Name = TabName .. "Btn",
			Size = UDim2.new(1, -24, 0, 46),
			BackgroundColor3 = Library.Theme.Element,
			Text = "",
			TextColor3 = Library.Theme.TextMuted,
			FontFace = FontStandard,
			TextSize = 14,
			AutoButtonColor = false,
			Parent = TabContainer,
		})
		Corner(TabButton, 12); Stroke(TabButton, Library.Theme.Border, 0.68, 1)
		local TabIcon = Create("TextLabel", { Size=UDim2.new(0,26,0,26), Position=UDim2.new(0,10,0.5,-13), BackgroundTransparency=1, Text=TabIconText, TextColor3=Library.Theme.TextMuted, FontFace=FontBold, TextSize=12, Parent=TabButton })
		local TabText = Create("TextLabel", { Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,40,0,0), BackgroundTransparency=1, Text=TabName, TextColor3=Library.Theme.TextMuted, FontFace=FontBold, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, Parent=TabButton })
		local TabAccent = Create("Frame", { Size = UDim2.new(0, 3, 0, 22), Position = UDim2.new(0, 4, 0.5, -11), BackgroundColor3 = Library.Theme.Accent, BackgroundTransparency = 0, BorderSizePixel = 0, Visible = #Window.Tabs == 0, Parent = TabButton })
		Corner(TabAccent, 3)
		local Badge = nil
		if tabOptions.Badge then
			Badge = Create("TextLabel", { Size=UDim2.new(0,30,0,20), Position=UDim2.new(1,-38,0.5,-10), BackgroundColor3=Library.Theme.SurfaceStrong or Library.Theme.Element, Text=tostring(tabOptions.Badge), TextColor3=Library.Theme.TextMuted, FontFace=FontBold, TextSize=9, Parent=TabButton })
			Corner(Badge,7)
		end
		AddConnection(TabButton.MouseEnter:Connect(function()
			if Window.CurrentTab ~= Tab then
				Tween(TabButton, { BackgroundColor3 = Library.Theme.ElementHover }, 0.14)
				Tween(TabIcon, { TextColor3 = Library.Theme.Text }, 0.14)
				Tween(TabText, { TextColor3 = Library.Theme.Text }, 0.14)
			end
		end))
		AddConnection(TabButton.MouseLeave:Connect(function()
			if Window.CurrentTab ~= Tab then
				Tween(TabButton, { BackgroundColor3 = Library.Theme.Element }, 0.14)
				Tween(TabIcon, { TextColor3 = Library.Theme.TextMuted }, 0.14)
				Tween(TabText, { TextColor3 = Library.Theme.TextMuted }, 0.14)
			end
		end))

		local Page = Create("ScrollingFrame", {
			Name = TabName .. "Page",
			Size = UDim2.new(1, 0, 1, -60),
			Position = UDim2.new(0, 0, 0, 60),
			BackgroundTransparency = 1,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Library.Theme.Border,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Visible = false,
			Parent = ContentContainer,
		})
		local PageScale = Create("UIScale", { Scale = 1, Parent = Page })
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 18),
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
			Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
		end))


		AddConnection(TabButton.MouseButton1Click:Connect(function()
			for _, tb in ipairs(Window.Tabs) do
				tb.Page.Visible = false
				tb.Accent.Visible = false
				Tween(tb.Button, { BackgroundColor3 = Library.Theme.Element }, 0.18)
				Tween(tb.Icon, { TextColor3 = Library.Theme.TextMuted }, 0.18)
				Tween(tb.Text, { TextColor3 = Library.Theme.TextMuted }, 0.18)
			end
			Window.CurrentTab = Tab
			CurrentPageLabel.Text = TabName
			PageKicker.Text = string.upper(TabName)
			Page.Visible = true
			PageScale.Scale = 0.985
			TabAccent.Visible = true
			SpringTween(PageScale, { Scale = 1 }, 0.30)
			SpringTween(TabButton, { BackgroundColor3 = Library.Theme.Accent }, 0.24)
			Tween(TabIcon, { TextColor3 = Library.Theme.Background }, 0.18)
			Tween(TabText, { TextColor3 = Library.Theme.Background }, 0.18)
			local q=string.lower(SearchBox.Text or "")
			for _, child in ipairs(Page:GetChildren()) do
				if child:IsA("GuiObject") and child:GetAttribute("ZenSearchText") then
					child.Visible = q=="" or string.find(string.lower(child:GetAttribute("ZenSearchText")),q,1,true)~=nil
				end
			end
		end))

		if #Window.Tabs == 0 then
			Page.Visible = true
			Window.CurrentTab = Tab
			TabButton.BackgroundColor3 = Library.Theme.Accent
			TabIcon.TextColor3 = Library.Theme.Background
			TabText.TextColor3 = Library.Theme.Background
			TabAccent.Visible = true
			CurrentPageLabel.Text = TabName
			PageKicker.Text = string.upper(TabName)
		end

		table.insert(Window.Tabs, { Button = TabButton, Page = Page, Accent = TabAccent, Icon = TabIcon, Text = TabText, Name = TabName, PageScale = PageScale })

		-- ============================= Toggle =============================

		function Tab:CreateToggle(tOpts)
			local Toggle: { [string]: any } = { Value = tOpts.CurrentValue or false }
			if tOpts.Flag then Library.Flags[tOpts.Flag] = Toggle.Value end

			local Container = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundColor3 = Library.Theme.Element,
				Parent = Page,
			})
			Container:SetAttribute("ZenSearchText", tOpts.Name or "Toggle")
			Corner(Container, 11); Stroke(Container, Library.Theme.Border, 0.45, 1); CardMotion(Container)
			Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.35, Parent = Container })

			Create("TextLabel", {
				Size = UDim2.new(1, -60, 1, 0),
				Position = UDim2.new(0, 10, 0, 0),
				BackgroundTransparency = 1,
				Text = tOpts.Name or "Toggle",
				TextColor3 = Library.Theme.Text,
				FontFace = FontStandard,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Container,
			})

			local SwitchArea = Create("Frame", {
				Size = UDim2.new(0, 40, 0, 20),
				Position = UDim2.new(1, -50, 0.5, -10),
				BackgroundColor3 = Toggle.Value and Library.Theme.Accent or Library.Theme.Border,
				Parent = Container,
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SwitchArea })
			local SwitchGlow = Create("Frame", { Size=UDim2.new(1,8,1,8), Position=UDim2.new(0.5,-4,0.5,-4), AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3=Library.Theme.Accent, BackgroundTransparency=Toggle.Value and 0.88 or 1, BorderSizePixel=0, ZIndex=SwitchArea.ZIndex-1, Parent=SwitchArea })
			Corner(SwitchGlow,20)

			local Indicator = Create("Frame", {
				Size = UDim2.new(0, 16, 0, 16),
				Position = Toggle.Value and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
				BackgroundColor3 = Library.Theme.Text,
				Parent = SwitchArea,
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Indicator })

			local Btn = Create("TextButton", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "",
				Parent = Container,
			})

			function Toggle:Get()
				return self.Value
			end

			function Toggle:Set(val, noCallback)
				self.Value = val
				if tOpts.Flag then Library.Flags[tOpts.Flag] = val end
				Tween(SwitchArea, { BackgroundColor3 = val and Library.Theme.Accent or Library.Theme.Border }, 0.2)
				Tween(SwitchGlow, { BackgroundTransparency = val and 0.86 or 1 }, 0.22)
				Tween(Indicator, {
					Position = val and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
				}, 0.2)

				if not noCallback and tOpts.Callback then
					Log("Toggle:" .. (tOpts.Name or "?") .. " = " .. tostring(val))
					task.spawn(tOpts.Callback, val)
				end
			end

			AddConnection(Btn.MouseEnter:Connect(function() Tween(Container, { BackgroundColor3 = Library.Theme.ElementHover }, 0.16) end))
			AddConnection(Btn.MouseLeave:Connect(function() Tween(Container, { BackgroundColor3 = Library.Theme.Element }, 0.16) end))
			AddConnection(Btn.MouseButton1Down:Connect(function() Tween(SwitchArea, { Size = UDim2.new(0, 38, 0, 18) }, 0.1) end))
			AddConnection(Btn.MouseButton1Up:Connect(function() Tween(SwitchArea, { Size = UDim2.new(0, 40, 0, 20) }, 0.12) end))
			AddConnection(Btn.MouseButton1Click:Connect(function()
				Toggle:Set(not Toggle.Value)
			end))

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

			if tOpts.Flag then
				Library.ConfigHandlers[tOpts.Flag] = function(v) Toggle:Set(v, true) end
			end

			return Toggle
		end

		-- ============================= Slider =============================

		function Tab:CreateSlider(sOpts)
			sOpts = sOpts or {}
			local Min = sOpts.Min or 0
			local Max = sOpts.Max or 100
			local Increment = sOpts.Increment or 1
			local Suffix = sOpts.Suffix or ""
			local Slider: { [string]: any } = { Value = sOpts.Default or Min }
			if sOpts.Flag then Library.Flags[sOpts.Flag] = Slider.Value end

			local Container = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 56),
				BackgroundColor3 = Library.Theme.Element,
				Parent = Page,
			})
			Container:SetAttribute("ZenSearchText", sOpts.Name or "Slider")
			Corner(Container, 11); Stroke(Container, Library.Theme.Border, 0.45, 1); CardMotion(Container)
			Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.35, Parent = Container })

			Create("TextLabel", {
				Size = UDim2.new(1, -100, 0, 25),
				Position = UDim2.new(0, 10, 0, 2),
				BackgroundTransparency = 1,
				Text = sOpts.Name or "Slider",
				TextColor3 = Library.Theme.Text,
				FontFace = FontStandard,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Container,
			})

			local ValueLabel = Create("TextLabel", {
				Size = UDim2.new(0, 80, 0, 25),
				Position = UDim2.new(1, -90, 0, 2),
				BackgroundTransparency = 1,
				Text = tostring(Slider.Value) .. Suffix,
				TextColor3 = Library.Theme.TextMuted,
				FontFace = FontStandard,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = Container,
			})

			local Track = Create("Frame", {
				Size = UDim2.new(1, -20, 0, 6),
				Position = UDim2.new(0, 10, 1, -15),
				BackgroundColor3 = Library.Theme.Border,
				Parent = Container,
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track })

			local Fill = Create("Frame", {
				Size = UDim2.new(0, 0, 1, 0),
				BackgroundColor3 = Library.Theme.Accent,
				Parent = Track,
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill })

			local Btn = Create("TextButton", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "",
				Parent = Container,
			})

			function Slider:Get()
				return self.Value
			end

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
				ValueLabel.Text = tostring(rounded) .. Suffix

				if not noCallback and sOpts.Callback then
					Log("Slider:" .. (sOpts.Name or "?") .. " = " .. tostring(rounded))
					task.spawn(sOpts.Callback, rounded)
				end
			end

			Slider:Set(Slider.Value, true)
			AddConnection(Btn.MouseEnter:Connect(function() Tween(Fill, { Size = UDim2.new(math.max(0.015, Fill.Size.X.Scale), 0, 1, 0) }, 0.12) end))

			local dragging = false
			AddConnection(Btn.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
				end
			end))
			AddConnection(UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
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

			if sOpts.Flag then
				Library.ConfigHandlers[sOpts.Flag] = function(v) Slider:Set(v, true) end
			end

			return Slider
		end

		-- ============================= Dropdown =============================

		function Tab:CreateDropdown(dOpts)
			local Dropdown: { [string]: any } = { Value = dOpts.CurrentOption, Options = dOpts.Options or {} }
			if dOpts.Flag then Library.Flags[dOpts.Flag] = Dropdown.Value end
			local Expanded = false

			local Container = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 38),
				BackgroundColor3 = Library.Theme.Element,
				ClipsDescendants = true,
				Parent = Page,
			})
			Container:SetAttribute("ZenSearchText", dOpts.Name or "Dropdown")
			Corner(Container, 11); Stroke(Container, Library.Theme.Border, 0.45, 1); CardMotion(Container)

			local TopBar = Create("TextButton", {
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundTransparency = 1,
				Text = "",
				Parent = Container,
			})
			Create("TextLabel", {
				Size = UDim2.new(1, -40, 1, 0),
				Position = UDim2.new(0, 10, 0, 0),
				BackgroundTransparency = 1,
				Text = dOpts.Name or "Dropdown",
				TextColor3 = Library.Theme.Text,
				FontFace = FontStandard,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = TopBar,
			})

			local SelectedLabel = Create("TextLabel", {
				Size = UDim2.new(1, -40, 1, 0),
				Position = UDim2.new(0, 10, 0, 0),
				BackgroundTransparency = 1,
				Text = type(Dropdown.Value) == "table" and table.concat(Dropdown.Value, ", ") or tostring(Dropdown.Value or ""),
				TextColor3 = Library.Theme.Accent,
				FontFace = FontStandard,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = TopBar,
			})

			local ListContainer = Create("Frame", {
				Size = UDim2.new(1, -20, 1, -40),
				Position = UDim2.new(0, 10, 0, 40),
				BackgroundTransparency = 1,
				Parent = Container,
			})
			local ListLayout = Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
				Parent = ListContainer,
			})

			local OptionBtns = {}

			function Dropdown:Get()
				return self.Value
			end

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
				if not noCallback and dOpts.Callback then
					Log("Dropdown:" .. (dOpts.Name or "?") .. " updated")
					task.spawn(dOpts.Callback, val)
				end
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
						Size = UDim2.new(1, 0, 0, 26),
						BackgroundColor3 = Library.Theme.ElementHover,
						Text = tostring(opt),
						TextColor3 = isSelected and Library.Theme.Accent or Library.Theme.TextMuted,
						FontFace = FontStandard,
						TextSize = 13,
						AutoButtonColor = false,
						Parent = ListContainer,
					})
					Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = OptBtn })
					OptionBtns[opt] = OptBtn

					AddConnection(OptBtn.MouseButton1Click:Connect(function()
						if dOpts.MultiSelection then
							local current = type(Dropdown.Value) == "table" and {} or {}
							for _, v in ipairs(table.unpack({ type(Dropdown.Value) == "table" and Dropdown.Value or {} })) do
								table.insert(current, v)
							end
							local pos = table.find(current, opt)
							if pos then
								table.remove(current, pos)
							else
								table.insert(current, opt)
							end
							Dropdown:Set(current)
						else
							Dropdown:Set(opt)
							Expanded = false
							Tween(Container, { Size = UDim2.new(1, 0, 0, 36) }, 0.2)
						end
					end))
				end
				if Expanded then
					Container.Size = UDim2.new(1, 0, 0, 40 + ListLayout.AbsoluteContentSize.Y + 10)
				end
			end

			AddConnection(TopBar.MouseButton1Click:Connect(function()
				Expanded = not Expanded
				if Expanded then
					Populate()
					Tween(Container, { Size = UDim2.new(1, 0, 0, 40 + ListLayout.AbsoluteContentSize.Y + 10) }, 0.2)
				else
					Tween(Container, { Size = UDim2.new(1, 0, 0, 36) }, 0.2)
				end
			end))

			function Dropdown:Refresh(newOptions, keepSelection)
				self.Options = newOptions or {}
				if not keepSelection then
					self:Set(dOpts.MultiSelection and {} or nil, true)
				end
				Populate()
			end

			if dOpts.Flag then
				Library.ConfigHandlers[dOpts.Flag] = function(v) Dropdown:Set(v, true) end
			end

			Populate()
			return Dropdown
		end

		-- ============================= Keybind =============================

		function Tab:CreateKeybind(kOpts)
			local Keybind: { [string]: any } = { Value = kOpts.CurrentKeybind or "None" }
			if kOpts.Flag then Library.Flags[kOpts.Flag] = Keybind.Value end
			local Listening = false

			local Container = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundColor3 = Library.Theme.Element,
				Parent = Page,
			})
			Container:SetAttribute("ZenSearchText", kOpts.Name or "Keybind")
			Corner(Container, 11); Stroke(Container, Library.Theme.Border, 0.45, 1); CardMotion(Container)
			Create("TextLabel", {
				Size = UDim2.new(1, -120, 1, 0),
				Position = UDim2.new(0, 10, 0, 0),
				BackgroundTransparency = 1,
				Text = kOpts.Name or "Keybind",
				TextColor3 = Library.Theme.Text,
				FontFace = FontStandard,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Container,
			})

			local BindBtn = Create("TextButton", {
				Size = UDim2.new(0, 100, 0, 24),
				Position = UDim2.new(1, -110, 0.5, -12),
				BackgroundColor3 = Library.Theme.Background,
				Text = tostring(Keybind.Value),
				TextColor3 = Library.Theme.Accent,
				FontFace = FontStandard,
				TextSize = 13,
				Parent = Container,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = BindBtn })

			function Keybind:Get()
				return self.Value
			end

			function Keybind:Set(val, noCallback)
				self.Value = val
				if kOpts.Flag then Library.Flags[kOpts.Flag] = val end
				BindBtn.Text = tostring(val)
				if not noCallback and kOpts.Callback then
					Log("Keybind:" .. (kOpts.Name or "?") .. " bound to " .. tostring(val))
				end
			end

			AddConnection(BindBtn.MouseButton1Click:Connect(function()
				Listening = true
				Library.ListeningKeybind = true
				BindBtn.Text = "Listening..."
			end))

			AddConnection(UserInputService.InputBegan:Connect(function(input)
				if Listening then
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
							if kOpts.Callback then
								Log("Keybind:" .. (kOpts.Name or "?") .. " fired")
								task.spawn(kOpts.Callback)
							end
						end
					end
				end
			end))

			if kOpts.Flag then
				Library.ConfigHandlers[kOpts.Flag] = function(v) Keybind:Set(v, true) end
			end

			return Keybind
		end

		-- ============================= TextBox =============================

		function Tab:CreateTextBox(tOpts)
			tOpts = tOpts or {}
			local Container = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 42),
				BackgroundColor3 = Library.Theme.Element,
				Parent = Page,
			})
			Container:SetAttribute("ZenSearchText", tOpts.Name or "TextBox")
			Corner(Container, 11); Stroke(Container, Library.Theme.Border, 0.45, 1); CardMotion(Container)
			Create("TextLabel", {
				Size = UDim2.new(1, -160, 1, 0),
				Position = UDim2.new(0, 10, 0, 0),
				BackgroundTransparency = 1,
				Text = tOpts.Name or "TextBox",
				TextColor3 = Library.Theme.Text,
				FontFace = FontStandard,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Container,
			})

			local Box = Create("TextBox", {
				Size = UDim2.new(0, 140, 0, 26),
				Position = UDim2.new(1, -150, 0.5, -13),
				BackgroundColor3 = Library.Theme.Background,
				Text = "",
				PlaceholderText = tOpts.PlaceholderText or "Enter text...",
				TextColor3 = Library.Theme.Text,
				PlaceholderColor3 = Library.Theme.TextMuted,
				ClearTextOnFocus = tOpts.ClearTextOnFocus == nil and true or tOpts.ClearTextOnFocus,
				FontFace = FontStandard,
				TextSize = 13,
				Parent = Container,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = Box })

			local tb: { [string]: any } = {}
			function tb:Get() return Box.Text end
			function tb:Set(v) Box.Text = tostring(v) end
			function tb:Clear() Box.Text = "" end

			AddConnection(Box.FocusLost:Connect(function()
				if tOpts.Callback then
					Log("TextBox:" .. (tOpts.Name or "?") .. " = " .. Box.Text)
					task.spawn(tOpts.Callback, Box.Text)
				end
			end))

			return tb
		end

		-- ============================= Button =============================

		function Tab:CreateButton(bOpts)
			bOpts = bOpts or {}
			local Btn = Create("TextButton", {
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundColor3 = Library.Theme.Element,
				Text = bOpts.Name or "Button",
				TextColor3 = Library.Theme.Text,
				FontFace = FontStandard,
				TextSize = 14,
				AutoButtonColor = false,
				Parent = Page,
			})
			Btn:SetAttribute("ZenSearchText", bOpts.Name or "Button")
			Corner(Btn, 11); Stroke(Btn, Library.Theme.Border, 0.45, 1); CardMotion(Btn)
			AddConnection(Btn.MouseEnter:Connect(function() Tween(Btn, { BackgroundColor3 = Library.Theme.ElementHover }, 0.2) end))
			AddConnection(Btn.MouseLeave:Connect(function() Tween(Btn, { BackgroundColor3 = Library.Theme.Element }, 0.2) end))
			AddConnection(Btn.MouseButton1Down:Connect(function() SpringTween(Btn, { Size = UDim2.new(1, -4, 0, 34) }, 0.12) end))
			AddConnection(Btn.MouseButton1Up:Connect(function() Tween(Btn, { Size = UDim2.new(1, 0, 0, 36) }, 0.14) end))
			AddConnection(Btn.MouseButton1Click:Connect(function()
				if bOpts.Callback then
					Log("Button:" .. (bOpts.Name or "?") .. " clicked")
					task.spawn(bOpts.Callback)
				end
			end))
			local handle: { [string]: any } = {}
			function handle:Set(text) Btn.Text = tostring(text) end
			return handle
		end

		-- ============================= Label / Paragraph / Section / Line =============================

		function Tab:CreateLabel(lOpts)
			local Lbl = Create("TextLabel", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = 1,
				Text = lOpts.Text or "Label",
				TextColor3 = Library.Theme.TextMuted,
				FontFace = FontStandard,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Page,
			})
			local handle: { [string]: any } = {}
			function handle:Set(txt) Lbl.Text = tostring(txt) end
			return handle
		end

		function Tab:CreateParagraph(pOpts)
			local Para = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundColor3 = Library.Theme.Element,
				Parent = Page,
			})
			Para:SetAttribute("ZenSearchText", pOpts.Title or "Paragraph")
			Corner(Para, 11); Stroke(Para, Library.Theme.Border, 0.45, 1); CardMotion(Para)
			local Title = Create("TextLabel", {
				Size = UDim2.new(1, -20, 0, 24),
				Position = UDim2.new(0, 10, 0, 5),
				BackgroundTransparency = 1,
				Text = pOpts.Title or "Title",
				TextColor3 = Library.Theme.Text,
				FontFace = FontBold,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Para,
			})
			local Content = Create("TextLabel", {
				Size = UDim2.new(1, -20, 0, 0),
				Position = UDim2.new(0, 10, 0, 30),
				BackgroundTransparency = 1,
				Text = pOpts.Content or "Content",
				TextColor3 = Library.Theme.TextMuted,
				FontFace = FontStandard,
				TextSize = 13,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				Parent = Para,
			})
			local function updateSize()
				local textSize = TextService:GetTextSize(Content.Text, 13, FontStandard, Vector2.new(Para.AbsoluteSize.X - 20, 9999))
				Content.Size = UDim2.new(1, -20, 0, textSize.Y)
				Para.Size = UDim2.new(1, 0, 0, 35 + textSize.Y + 10)
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
			Create("TextLabel", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = 1,
				Text = sOpts.Text or "Section",
				TextColor3 = Library.Theme.Accent,
				FontFace = FontBold,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Page,
			})
		end

		function Tab:CreateLine()
			Create("Frame", {
				Size = UDim2.new(1, -20, 0, 1),
				Position = UDim2.new(0, 10, 0, 0),
				BackgroundColor3 = Library.Theme.Border,
				Parent = Page,
			})
		end

		-- ============================= Color Picker =============================

		function Tab:CreateColorPicker(cOpts)
			local Picker: { [string]: any } = { Value = cOpts.Color or Color3.new(1, 1, 1) }
			if cOpts.Flag then Library.Flags[cOpts.Flag] = serialize(Picker.Value) end
			local H, S, V = Picker.Value:ToHSV()
			local Expanded = false

			local Container = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundColor3 = Library.Theme.Element,
				ClipsDescendants = true,
				Parent = Page,
			})
			Container:SetAttribute("ZenSearchText", cOpts.Name or "Color Picker")
			Corner(Container, 11); Stroke(Container, Library.Theme.Border, 0.45, 1); CardMotion(Container)

			local TopBar = Create("TextButton", {
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundTransparency = 1,
				Text = "",
				Parent = Container,
			})
			Create("TextLabel", {
				Size = UDim2.new(1, -60, 1, 0),
				Position = UDim2.new(0, 10, 0, 0),
				BackgroundTransparency = 1,
				Text = cOpts.Name or "Color Picker",
				TextColor3 = Library.Theme.Text,
				FontFace = FontStandard,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = TopBar,
			})

			local Swatch = Create("Frame", {
				Size = UDim2.new(0, 30, 0, 20),
				Position = UDim2.new(1, -40, 0.5, -10),
				BackgroundColor3 = Picker.Value,
				Parent = TopBar,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = Swatch })

			local SVMap = Create("Frame", {
				Size = UDim2.new(1, -20, 0, 120),
				Position = UDim2.new(0, 10, 0, 40),
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

			local HueBar = Create("Frame", {
				Size = UDim2.new(1, -20, 0, 15),
				Position = UDim2.new(0, 10, 0, 170),
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

			function Picker:Get()
				return self.Value
			end

			function Picker:Set(col, noCallback)
				self.Value = col
				if cOpts.Flag then Library.Flags[cOpts.Flag] = serialize(col) end
				H, S, V = col:ToHSV()
				Swatch.BackgroundColor3 = col
				SVMap.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
				if not noCallback and cOpts.Callback then
					Log("ColorPicker:" .. (cOpts.Name or "?") .. " updated")
					task.spawn(cOpts.Callback, col)
				end
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
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					svDragging = false
					hueDragging = false
				end
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
				Tween(Container, { Size = Expanded and UDim2.new(1, 0, 0, 195) or UDim2.new(1, 0, 0, 36) }, 0.2)
			end))

			if cOpts.Flag then
				Library.ConfigHandlers[cOpts.Flag] = function(v)
					if typeof(v) == "Color3" then Picker:Set(v, true) end
				end
			end

			return Picker
		end

		return Tab
	end

	return Window
end

-- ============================= Notifications =============================

function Library:Notify(options)
	options = options or {}
	if not Library.NotificationContainer then return end
	local Notif = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = Library.Theme.Element,
		BackgroundTransparency = 1,
		Parent = Library.NotificationContainer,
	})
	local NotifScale = Create("UIScale", { Scale = 0.9, Parent = Notif })
	Create("UICorner", { CornerRadius = UDim.new(0, 9), Parent = Notif })
	Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Transparency = 0.15, Parent = Notif })
	Create("TextLabel", {
		Size = UDim2.new(1, -20, 0, 20),
		Position = UDim2.new(0, 10, 0, 5),
		BackgroundTransparency = 1,
		Text = options.Title or "Notification",
		TextColor3 = Library.Theme.Text,
		FontFace = FontBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Notif,
	})
	Create("TextLabel", {
		Size = UDim2.new(1, -20, 0, 20),
		Position = UDim2.new(0, 10, 0, 25),
		BackgroundTransparency = 1,
		Text = options.Content or "",
		TextColor3 = Library.Theme.TextMuted,
		FontFace = FontStandard,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Notif,
	})
	SpringTween(NotifScale, { Scale = 1 }, 0.32)
	Tween(Notif, { BackgroundTransparency = 0 }, 0.3)
	task.spawn(function()
		pcall(function()
			task.wait(options.Duration or 3)
			if not Notif.Parent then return end
			Tween(Notif, { BackgroundTransparency = 1 }, 0.4)
			task.wait(0.45)
			if Notif.Parent then
				Notif:Destroy()
			end
		end)
	end)
end

function Library:CreateNotify(options)
	self:Notify(options)
end

return Library
