-- ZenUI Apex Visual System
-- Premium visual layer: applies animated depth, sheen, and polish to an
-- already-constructed ZenUI Library. No network access, no core loading.
-- Usage: local Library = loadstring(game:HttpGet(...ZenUI.luau...))()
--        -- ZenUI.luau loads this module internally.
--
-- This module is also safe to run standalone AFTER a ZenUI core exists:
--   local Library = getgenv().Library
--   loadstring(game:HttpGet(".../ZenUI.ApexVisuals.luau"))()(Library)

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

local function styleButton(button, hoverColor, normalColor)
	if not button or not button:IsA("GuiButton") or button:GetAttribute("ZenApexStyled") then return end
	button:SetAttribute("ZenApexStyled", true)
	local scale = button:FindFirstChild("ZenApexScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "ZenApexScale"
		scale.Scale = 1
		scale.Parent = button
	end
	con(button.MouseEnter, function()
		tween(scale, {Scale = 1.02}, 0.14, Enum.EasingStyle.Back)
		if button.BackgroundTransparency < 1 then
			tween(button, {BackgroundColor3 = hoverColor}, 0.12)
		end
	end)
	con(button.MouseLeave, function()
		tween(scale, {Scale = 1}, 0.12, Enum.EasingStyle.Back)
		if button.BackgroundTransparency < 1 then
			tween(button, {BackgroundColor3 = normalColor}, 0.12)
		end
	end)
	con(button.MouseButton1Down, function()
		tween(scale, {Scale = 0.97}, 0.06, Enum.EasingStyle.Quad)
	end)
	con(button.MouseButton1Up, function()
		tween(scale, {Scale = 1.02}, 0.08, Enum.EasingStyle.Back)
	end)
end

local function sheenSweep(target)
	if not target or not target.Parent or target:GetAttribute("ZenApexSheen") then return end
	target:SetAttribute("ZenApexSheen", true)
	local sheen = Instance.new("Frame")
	sheen.Name = "ZenApexSheenBar"
	sheen.Size = UDim2.new(0, 80, 1.4, 0)
	sheen.Position = UDim2.new(-1.2, 0, -0.2, 0)
	sheen.Rotation = 20
	sheen.BackgroundColor3 = Color3.new(1, 1, 1)
	sheen.BackgroundTransparency = 0.92
	sheen.BorderSizePixel = 0
	sheen.ZIndex = (target.ZIndex or 1) + 1
	sheen.Visible = false
	sheen.Parent = target
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	grad.Parent = sheen
	con(target.MouseEnter, function()
		if target.ClipsDescendants == false and target.Visible then
			sheen.Visible = true
			sheen.Position = UDim2.new(-1.2, 0, -0.2, 0)
			tween(sheen, {Position = UDim2.new(1.4, 0, -0.2, 0)}, 0.55, Enum.EasingStyle.Quad)
		end
	end)
	con(target.MouseLeave, function()
		sheen.Visible = false
	end)
	return sheen
end

local function applySkin(Library, window, options)
	if not window or not window.Parent or window:GetAttribute("ZenApexSkinApplied") then return end
	window:SetAttribute("ZenApexSkinApplied", true)

	local accent = options and options.AccentColor
	if typeof(accent) ~= "Color3" then
		accent = Color3.fromRGB(78, 255, 185)
	end

	local base = Color3.fromRGB(8, 12, 16)
	local panel = Color3.fromRGB(11, 16, 22)
	local panelSoft = Color3.fromRGB(14, 20, 27)
	local text = Color3.fromRGB(244, 247, 250)
	local muted = Color3.fromRGB(145, 154, 164)
	local hover = Color3.fromRGB(24, 32, 40)

	window.BackgroundColor3 = base
	window.BackgroundTransparency = 0
	window.ClipsDescendants = true
	corner(window, 20)
	accentStroke(window, accent, 0.68, 1.25)

	local header = window:FindFirstChild("Header")
	if header then
		header.BackgroundColor3 = panel
		header.BackgroundTransparency = 0
		header.ClipsDescendants = true
		corner(header, 18)
		accentStroke(header, accent, 0.7, 1.1)
		local sheen = header:FindFirstChild("HeaderSheen")
		if sheen then
			sheen.BackgroundTransparency = 0.955
		end
	end

	local sidebar = window:FindFirstChild("Sidebar")
	if sidebar then
		sidebar.BackgroundColor3 = panelSoft
		sidebar.BackgroundTransparency = 0
		sidebar.ClipsDescendants = true
		corner(sidebar, 16)
		accentStroke(sidebar, accent, 0.78, 1.1)
	end

	local content = window:FindFirstChild("ContentContainer")
	if content then
		local top = content:FindFirstChild("ContentTop")
		if top then
			top.BackgroundColor3 = panel
			top.BackgroundTransparency = 0
			corner(top, 14)
			accentStroke(top, accent, 0.84, 1)
		end
	end

	for _, instance in ipairs(window:GetDescendants()) do
		if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
			if instance.TextColor3 == Color3.fromRGB(248, 248, 250) then
				instance.TextColor3 = text
			elseif instance.TextColor3 == Color3.fromRGB(150, 152, 158) then
				instance.TextColor3 = muted
			end
		end

		if instance:IsA("GuiButton") then
			styleButton(instance, hover, instance.BackgroundColor3)
			sheenSweep(instance)
		end
	end

	con(window.DescendantAdded, function(instance)
		task.defer(function()
			if instance.Parent and instance:IsA("GuiButton") then
				styleButton(instance, hover, instance.BackgroundColor3)
				sheenSweep(instance)
			end
		end)
	end)

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
			options.AccentColor = Color3.fromRGB(78, 255, 185)
		end
		options.UIScale = math.clamp(tonumber(options.UIScale) or 1.00, 0.85, 1.30)
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