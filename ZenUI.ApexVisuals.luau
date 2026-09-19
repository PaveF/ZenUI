-- ZenUI Apex Visual System
-- Glass/neon accent layer. The v3 core carries the full glass design; this
-- module adds per-window accent plumbing, ambient glow feed, and safe
-- teardown. It is loaded by ZenUI.luau AFTER the core:
--
--   loadRemote(SKIN, "ZenUI.ApexVisuals", Library)
--
-- It is also safe standalone when a core already exists in getgenv().

local TweenService = game:GetService("TweenService")
local ENV = (getgenv and getgenv()) or _G

local ExtraConnections = {}

local function con(signal, fn)
	local ok, connection = pcall(function() return signal:Connect(fn) end)
	if ok and connection then table.insert(ExtraConnections, connection) end
	return connection
end

local function tween(instance, properties, duration, style)
	if not instance or not instance.Parent then return end
	local ok, animation = pcall(function()
		return TweenService:Create(
			instance,
			TweenInfo.new(duration or 0.16, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			properties
		)
	end)
	if ok and animation then animation:Play() end
end

local function corner(parent, radius)
	if not parent or not parent.Parent then return end
	local existing = parent:FindFirstChild("ZenApexCorner")
	if existing then return existing end
	local c = Instance.new("UICorner")
	c.Name = "ZenApexCorner"
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
	return c
end

local function accentStroke(parent, color, transparency, thickness)
	if not parent or not parent.Parent then return end
	local existing = parent:FindFirstChild("ZenApexStroke")
	if existing and existing:IsA("UIStroke") then
		existing.Color = color
		existing.Transparency = transparency
		existing.Thickness = thickness
		return existing
	end
	local s = Instance.new("UIStroke")
	s.Name = "ZenApexStroke"
	s.Color = color
	s.Transparency = transparency or 0.72
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

-- Ambient accent feed for the window: a soft top-edge light that breathes.
local function ambientGlow(window, accent)
	if not window or window:GetAttribute("ZenApexGlow") then return end
	window:SetAttribute("ZenApexGlow", true)
	local glow = Instance.new("Frame")
	glow.Name = "ZenApexAmbient"
	glow.Size = UDim2.new(1, 0, 0, 2)
	glow.Position = UDim2.new(0, 0, 0, 0)
	glow.BackgroundColor3 = accent
	glow.BackgroundTransparency = 0.35
	glow.BorderSizePixel = 0
	glow.ZIndex = 20
	glow.Parent = window
	corner(glow, 2)
	local on = true
	con(window.AncestryChanged, function()
		if not window.Parent then on = false end
	end)
	task.spawn(function()
		while on and glow.Parent do
			tween(glow, { BackgroundTransparency = 0.65 }, 1.2)
			task.wait(1.2)
			tween(glow, { BackgroundTransparency = 0.3 }, 1.2)
			task.wait(1.2)
		end
	end)
	return glow
end

local function applySkin(Library, window, options)
	if not window or not window.Parent or window:GetAttribute("ZenApexSkinApplied") then return end
	window:SetAttribute("ZenApexSkinApplied", true)

	local accent = options and options.AccentColor
	if typeof(accent) ~= "Color3" then
		accent = Library.Theme.Accent or Color3.fromRGB(78, 255, 185)
	end

	-- window rim
	accentStroke(window, accent, 0.8, 1.1)
	local header = window:FindFirstChild("Header")
	if header then
		accentStroke(header, accent, 0.85, 1)
	end
	local sidebar = window:FindFirstChild("Sidebar")
	if sidebar then
		accentStroke(sidebar, accent, 0.88, 1)
	end

	ambientGlow(window, accent)

	pcall(function()
		Library:SetAccentColor(accent)
	end)
end

return function(Library)
	Library = Library or ENV.Library
	if not Library then
		error("ZenUI.ApexVisuals requires a ZenUI Library to skin (first argument or getgenv().Library)", 2)
	end

	local oldCreateWindow = Library.CreateWindow
	local oldDestroy = Library.Destroy

	Library.CreateWindow = function(self, options)
		options = type(options) == "table" and table.clone(options) or {}
		if typeof(options.AccentColor) ~= "Color3" then
			options.AccentColor = Library.Theme.Accent or Color3.fromRGB(78, 255, 185)
		end
		local window = oldCreateWindow(self, options)
		task.defer(function()
			applySkin(self, self.MainFrame, options)
		end)
		return window
	end

	Library.Destroy = function(self, ...)
		for _, connection in ipairs(ExtraConnections) do
			pcall(function() connection:Disconnect() end)
		end
		table.clear(ExtraConnections)
		return oldDestroy(self, ...)
	end

	ENV.Library = Library
	Library.ApexSkin = true
	return Library
end