--!nonstrict
-- Rayfield-style UI library for the Real executor (fixed)
-- Usage:
--   local Library = (loadstring or require)(...)
--   local lib = Library.new({ Name = "My Hub", Theme = "Blue" })
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
	Theme = {
		Background = Color3.fromRGB(20, 22, 26),
		Sidebar = Color3.fromRGB(17, 17, 21),
		Element = Color3.fromRGB(25, 27, 33),
		ElementHover = Color3.fromRGB(35, 37, 43),
		Accent = Color3.fromRGB(109, 231, 153),
		Text = Color3.fromRGB(240, 240, 240),
		TextMuted = Color3.fromRGB(150, 150, 150),
		Border = Color3.fromRGB(45, 45, 50),
	},
	ConfigFolder = "UI_Configs",
	ConfigurationSaving = false,
}

local FontStandard = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local FontBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)

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

local function Create(className: string, properties: { [string]: any }): Instance
	local inst = Instance.new(className)
	for k, v in pairs(properties) do
		if k ~= "Parent" then
			pcall(function() inst[k] = v end)
		end
	end
	if properties.Parent then
		inst.Parent = properties.Parent
	end
	return inst
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
	Library.Theme.Accent = settings.Theme == "Blue" and Color3.fromRGB(94, 122, 255) or Color3.fromRGB(109, 231, 153)

	local guiParent = safe_gethui()
	local ScreenGui = Create("ScreenGui", {
		Name = "RayfieldStyleUI",
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
		Size = UDim2.new(0, 600, 0, 400),
		Position = UDim2.new(0.5, -300, 0.5, -200),
		BackgroundColor3 = Library.Theme.Background,
		ClipsDescendants = false,
		BackgroundTransparency = 1,
		Parent = Library.ScreenGui,
	})
	AddInstance(MainFrame)
	Library.MainFrame = MainFrame
	Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = MainFrame })
	Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Parent = MainFrame })

	task.spawn(function()
		pcall(function()
			task.wait(1)
			if MainFrame.Parent then
				Tween(MainFrame, { BackgroundTransparency = 0 }, 0.4)
			end
		end)
	end)

	local Header = Create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Active = true,
		Parent = MainFrame,
	})

	Create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -60, 1, 0),
		Position = UDim2.new(0, 15, 0, 0),
		BackgroundTransparency = 1,
		Text = options.Name or "Window",
		TextColor3 = Library.Theme.Text,
		FontFace = FontBold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Header,
	})

	-- Window drag
	local dragging, dragInput, dragStart, startPos
	AddConnection(Header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position

			local inputEndConn
			inputEndConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if inputEndConn then inputEndConn:Disconnect() end
				end
			end)
		end
	end))

	AddConnection(Header.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end))

	AddConnection(UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging and startPos then
			local delta = input.Position - dragStart
			MainFrame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end))

	-- Sidebar
	local Sidebar = Create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 160, 1, -40),
		Position = UDim2.new(0, 0, 0, 40),
		BackgroundColor3 = Library.Theme.Sidebar,
		BorderSizePixel = 0,
		Parent = MainFrame,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Sidebar })
	Create("Frame", {
		Size = UDim2.new(0, 10, 1, 0),
		Position = UDim2.new(1, -10, 0, 0),
		BackgroundColor3 = Library.Theme.Sidebar,
		BorderSizePixel = 0,
		Parent = Sidebar,
	})

	local TabContainer = Create("ScrollingFrame", {
		Name = "TabContainer",
		Size = UDim2.new(1, 0, 1, -20),
		Position = UDim2.new(0, 0, 0, 10),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = Sidebar,
	})
	local TabListLayout = Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = TabContainer,
	})
	AddConnection(TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TabContainer.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y + 10)
	end))

	local ContentContainer = Create("Frame", {
		Name = "ContentContainer",
		Size = UDim2.new(1, -160, 1, -40),
		Position = UDim2.new(0, 160, 0, 40),
		BackgroundTransparency = 1,
		Parent = MainFrame,
	})

	-- UI visibility toggle
	local WindowVisible = true
	AddConnection(UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe or Library.ListeningKeybind then return end
		local focused = pcall(function() return UserInputService:GetFocusedTextBox() end)
		if focused and input.KeyCode == ToggleKeybind then
			WindowVisible = not WindowVisible
			MainFrame.Visible = WindowVisible
		end
	end))

	function Window:Destroy()
		Library:Destroy()
	end

	-- ============================= Tabs =============================

	function Window:CreateTab(tabOptions)
		tabOptions = tabOptions or {}
		local Tab: { [string]: any } = { Elements = {} }
		local TabName = tabOptions.Name or "Tab"

		local TabButton = Create("TextButton", {
			Name = TabName .. "Btn",
			Size = UDim2.new(1, -20, 0, 34),
			BackgroundColor3 = Library.Theme.Element,
			Text = TabName,
			TextColor3 = Library.Theme.TextMuted,
			FontFace = FontStandard,
			TextSize = 14,
			AutoButtonColor = false,
			Parent = TabContainer,
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TabButton })

		local Page = Create("ScrollingFrame", {
			Name = TabName .. "Page",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Library.Theme.Border,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Visible = false,
			Parent = ContentContainer,
		})
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 15),
			PaddingRight = UDim.new(0, 15),
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
				Tween(tb.Button, { BackgroundColor3 = Library.Theme.Element })
				Tween(tb.Button, { TextColor3 = Library.Theme.TextMuted })
			end
			Page.Visible = true
			Tween(TabButton, { BackgroundColor3 = Library.Theme.Accent })
			Tween(TabButton, { TextColor3 = Library.Theme.Background })
		end))

		if #Window.Tabs == 0 then
			Page.Visible = true
			TabButton.BackgroundColor3 = Library.Theme.Accent
			TabButton.TextColor3 = Library.Theme.Background
		end

		table.insert(Window.Tabs, { Button = TabButton, Page = Page })

		-- ============================= Toggle =============================

		function Tab:CreateToggle(tOpts)
			local Toggle: { [string]: any } = { Value = tOpts.CurrentValue or false }
			if tOpts.Flag then Library.Flags[tOpts.Flag] = Toggle.Value end

			local Container = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundColor3 = Library.Theme.Element,
				Parent = Page,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Container })

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
				Tween(Indicator, {
					Position = val and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
				}, 0.2)

				if not noCallback and tOpts.Callback then
					Log("Toggle:" .. (tOpts.Name or "?") .. " = " .. tostring(val))
					task.spawn(tOpts.Callback, val)
				end
			end

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
				Size = UDim2.new(1, 0, 0, 50),
				BackgroundColor3 = Library.Theme.Element,
				Parent = Page,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Container })

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
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundColor3 = Library.Theme.Element,
				ClipsDescendants = true,
				Parent = Page,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Container })

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
					Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = OptBtn })
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
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundColor3 = Library.Theme.Element,
				Parent = Page,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Container })
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
			Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = BindBtn })

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
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundColor3 = Library.Theme.Element,
				Parent = Page,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Container })
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
			Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Box })

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
			Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Btn })
			AddConnection(Btn.MouseEnter:Connect(function() Tween(Btn, { BackgroundColor3 = Library.Theme.ElementHover }, 0.2) end))
			AddConnection(Btn.MouseLeave:Connect(function() Tween(Btn, { BackgroundColor3 = Library.Theme.Element }, 0.2) end))
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
			Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Para })
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
			Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Container })

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
			Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Swatch })

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
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Notif })
	Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Parent = Notif })
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