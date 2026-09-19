-- ZenUI Apex Extensions
-- Advanced controls, composable helpers, command surfaces, and AI metadata.
--
-- This module is loaded by ZenUI.luau AFTER the core so it can extend both
-- the Library and every Window/Tab created from it. It is also safe to load
-- standalone after a core exists:
--   local Library = getgenv().Library
--   loadstring(game:HttpGet(".../ZenUI.Extensions.luau"))()(Library)
-- or via the loader's Library:LoadApexExtensions(true).

local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ENV = (getgenv and getgenv()) or _G
local Library = ENV.Library or rawget(_G, "Library")
assert(Library, "Load ZenUI before ZenUI.Extensions")

local Connections = {}
local Instances = {}

local function con(s, f)
	local ok, c = pcall(function() return s:Connect(f) end)
	if ok and c then table.insert(Connections, c) end
	return c
end

local function track(x)
	if x then table.insert(Instances, x) end
	return x
end

local function tw(i, p, t, style)
	if not i or not i.Parent then return end
	pcall(function()
		TweenService:Create(i, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), p):Play()
	end)
end

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = p
	return c
end

local function stroke(p, c, tr, w)
	local s = Instance.new("UIStroke")
	s.Color = c
	s.Transparency = tr or 0.4
	s.Thickness = w or 1
	s.Parent = p
	return s
end

local function hoverLift(button)
	if not button or button:GetAttribute("ZenHoverLift") then return end
	button:SetAttribute("ZenHoverLift", true)
	local scale = button:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = button
	end
	con(button.MouseEnter, function()
		tw(scale, { Scale = 1.02 }, 0.12, Enum.EasingStyle.Back)
	end)
	con(button.MouseLeave, function()
		tw(scale, { Scale = 1 }, 0.12, Enum.EasingStyle.Back)
	end)
	con(button.MouseButton1Down, function()
		tw(scale, { Scale = 0.97 }, 0.06, Enum.EasingStyle.Quad)
	end)
	con(button.MouseButton1Up, function()
		tw(scale, { Scale = 1.02 }, 0.08, Enum.EasingStyle.Back)
	end)
	return scale
end

local function parentOf(tab)
	return tab._ParentOverride or tab.Page or (tab.Elements and tab.Elements[#tab.Elements])
end

local function row(tab, name, height)
	local f = track(Instance.new("Frame"))
	f.Name = name or "ZenControl"
	f.Size = UDim2.new(1, 0, 0, height or 48)
	f.BackgroundColor3 = Library.Theme.Element
	f.BorderSizePixel = 0
	f.Parent = parentOf(tab)
	corner(f, 12)
	stroke(f, Library.Theme.Border, 0.45, 1)
	if tab.Elements then table.insert(tab.Elements, f) end
	return f
end

function Library:CreateCommandCenter(o)
	o = o or {}
	local commands = o.Commands or {}
	local box = track(Instance.new("TextBox"))
	box.Name = "ZenCommandCenter"
	box.Size = UDim2.new(0, math.clamp(o.Width or 480, 280, 680), 0, 48)
	box.AnchorPoint = Vector2.new(0.5, 0)
	box.Position = UDim2.new(0.5, 0, 0, o.Top or 72)
	box.BackgroundColor3 = Library.Theme.Element
	box.TextColor3 = Library.Theme.Text
	box.PlaceholderColor3 = Library.Theme.TextMuted
	box.PlaceholderText = o.PlaceholderText or "Command, setting, action..."
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.GothamMedium
	box.TextSize = 15
	box.Parent = self.MainFrame
	corner(box, 14)
	stroke(box, Library.Theme.Accent, 0.25, 1.2)
	box:SetAttribute("ZenSearchText", "Command Center")

	local list = track(Instance.new("Frame"))
	list.Name = "Results"
	list.Position = UDim2.new(0, 0, 1, 8)
	list.Size = UDim2.new(1, 0, 0, 0)
	list.AutomaticSize = Enum.AutomaticSize.Y
	list.BackgroundColor3 = Library.Theme.Element
	list.Visible = false
	list.Parent = box
	corner(list, 14)
	stroke(list, Library.Theme.Border, 0.35, 1)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = list

	local function run(item)
		if item and item.Callback then task.spawn(item.Callback) end
		box.Text = ""
		list.Visible = false
	end

	local function render(q)
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		q = string.lower(q or "")
		local n = 0
		for _, item in ipairs(commands) do
			local label = tostring(item.Name or item.Label or "Command")
			if q == "" or string.find(string.lower(label), q, 1, true) then
				n = n + 1
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(1, -10, 0, 36)
				b.Position = UDim2.new(0, 5, 0, 0)
				b.BackgroundColor3 = Library.Theme.SurfaceStrong or Library.Theme.Element
				b.Text = label
				b.TextColor3 = Library.Theme.Text
				b.Font = Enum.Font.GothamMedium
				b.TextSize = 14
				b.TextXAlignment = Enum.TextXAlignment.Left
				b.AutoButtonColor = false
				b.Parent = list
				corner(b, 9)
				hoverLift(b)
				con(b.MouseEnter, function()
					tw(b, { BackgroundColor3 = Library.Theme.ElementHover }, 0.12)
				end)
				con(b.MouseLeave, function()
					tw(b, { BackgroundColor3 = Library.Theme.SurfaceStrong or Library.Theme.Element }, 0.12)
				end)
				con(b.MouseButton1Click, function() run(item) end)
			end
			if n >= math.clamp(o.MaxResults or 8, 1, 16) then break end
		end
		list.Visible = n > 0 and box:IsFocused()
	end

	con(box.Focused, function() render(box.Text) end)
	con(box:GetPropertyChangedSignal("Text"), function() render(box.Text) end)

	local api = { Box = box, List = list }
	function api:Set(text) box.Text = tostring(text or "") end
	function api:Clear() box.Text = ""; list.Visible = false end
	function api:GetText() return box.Text end
	return api
end

function Library:CreateStatusBar(o)
	o = o or {}
	local p = o.Parent or self.MainFrame
	local bar = track(Instance.new("Frame"))
	bar.Name = "ZenStatusBar"
	bar.Size = UDim2.new(1, -24, 0, 36)
	bar.Position = o.Position or UDim2.new(0, 12, 1, -48)
	bar.BackgroundColor3 = Library.Theme.SurfaceStrong or Library.Theme.Element
	bar.BorderSizePixel = 0
	bar.Parent = p
	corner(bar, 11)
	stroke(bar, Library.Theme.Border, 0.45, 1)

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 8, 0, 8)
	dot.Position = UDim2.new(0, 12, 0.5, -4)
	dot.BackgroundColor3 = Library.Theme.Accent
	dot.BorderSizePixel = 0
	dot.Parent = bar
	corner(dot, 4)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 28, 0, 0)
	label.Size = UDim2.new(1, -38, 1, 0)
	label.Text = tostring(o.Text or "Ready")
	label.TextColor3 = Library.Theme.TextMuted
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = bar

	local api = { Frame = bar }
	function api:Set(text, state)
		label.Text = tostring(text or "")
		local colors = {
			success = Color3.fromRGB(78, 255, 185),
			warning = Color3.fromRGB(255, 190, 80),
			error = Color3.fromRGB(255, 95, 110),
			info = Library.Theme.Accent,
		}
		local col = colors[state] or Library.Theme.TextMuted
		tw(label, { TextColor3 = col }, 0.14)
		tw(dot, { BackgroundColor3 = col }, 0.14)
		if state == "success" then tw(dot, { Size = UDim2.new(0, 12, 0, 12) }, 0.2, Enum.EasingStyle.Back); task.delay(0.2, function() tw(dot, { Size = UDim2.new(0, 8, 0, 8) }, 0.2) end) end
	end
	function api:Get() return label.Text end
	return api
end

function Library:CreateContextMenu(o)
	o = o or {}
	local items = o.Items or o.Actions or {}
	local menu = track(Instance.new("Frame"))
	menu.Name = "ZenContextMenu"
	menu.Size = UDim2.new(0, math.clamp(o.Width or 220, 150, 360), 0, 0)
	menu.AutomaticSize = Enum.AutomaticSize.Y
	menu.BackgroundColor3 = Library.Theme.Element
	menu.Visible = false
	menu.ZIndex = 500
	menu.Parent = self.MainFrame
	corner(menu, 12)
	stroke(menu, Library.Theme.Border, 0.3, 1.1)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 7)
	pad.PaddingBottom = UDim.new(0, 7)
	pad.Parent = menu
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 3)
	lay.Parent = menu

	local buttons = {}
	for _, item in ipairs(items) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, -12, 0, 38)
		b.BackgroundColor3 = Library.Theme.Element
		b.Text = tostring(item.Name or item.Label or "Action")
		b.TextColor3 = Library.Theme.Text
		b.Font = Enum.Font.GothamMedium
		b.TextSize = 14
		b.TextXAlignment = Enum.TextXAlignment.Left
		b.AutoButtonColor = false
		b.Parent = menu
		corner(b, 8)
		local rail = Instance.new("Frame")
		rail.Size = UDim2.new(0, 3, 0, 18)
		rail.Position = UDim2.new(0, 0, 0.5, -9)
		rail.BackgroundColor3 = item.Color or Library.Theme.Accent
		rail.BackgroundTransparency = 1
		rail.BorderSizePixel = 0
		rail.Parent = b
		corner(rail, 2)
		con(b.MouseEnter, function()
			tw(b, { BackgroundColor3 = Library.Theme.ElementHover }, 0.12)
			tw(rail, { BackgroundTransparency = 0 }, 0.14)
		end)
		con(b.MouseLeave, function()
			tw(b, { BackgroundColor3 = Library.Theme.Element }, 0.12)
			tw(rail, { BackgroundTransparency = 1 }, 0.14)
		end)
		con(b.MouseButton1Click, function()
			if item.Callback then task.spawn(item.Callback) end
			menu.Visible = false
		end)
		buttons[#buttons + 1] = b
	end

	local api = { Frame = menu, Buttons = buttons }
	function api:Show(pos)
		menu.Position = pos or UDim2.new(0.5, 0, 0.5, 0)
		menu.Visible = true
	end
	function api:Hide()
		menu.Visible = false
	end
	function api:Toggle(pos)
		if menu.Visible then self:Hide() else self:Show(pos) end
	end
	function api:SetItems(newItems)
		for _, b in ipairs(buttons) do
			if b.Parent then b:Destroy() end
		end
		table.clear(buttons)
		items = newItems or {}
		for _, item in ipairs(items) do
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, -12, 0, 38)
			b.BackgroundColor3 = Library.Theme.Element
			b.Text = tostring(item.Name or item.Label or "Action")
			b.TextColor3 = Library.Theme.Text
			b.Font = Enum.Font.GothamMedium
			b.TextSize = 14
			b.TextXAlignment = Enum.TextXAlignment.Left
			b.AutoButtonColor = false
			b.Parent = menu
			corner(b, 8)
			con(b.MouseEnter, function() tw(b, { BackgroundColor3 = Library.Theme.ElementHover }, 0.12) end)
			con(b.MouseLeave, function() tw(b, { BackgroundColor3 = Library.Theme.Element }, 0.12) end)
			con(b.MouseButton1Click, function()
				if item.Callback then task.spawn(item.Callback) end
				menu.Visible = false
			end)
			buttons[#buttons + 1] = b
		end
		return self
	end
	return api
end

function Library:CreateStatGrid(tab, stats)
	assert(tab, "CreateStatGrid requires a tab")
	stats = stats or {}
	local grid = row(tab, "ZenStatGrid", 88)
	grid.BackgroundTransparency = 1
	local n = math.max(1, #stats)
	for i, item in ipairs(stats) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1 / n, -((n - 1) * 10) / n, 1, 0)
		card.Position = UDim2.new((i - 1) / n, (i - 1) * 10 / n, 0, 0)
		card.BackgroundColor3 = Library.Theme.Element
		card.BorderSizePixel = 0
		card.Parent = grid
		card:SetAttribute("ZenStatCard", true)
		corner(card, 13)
		stroke(card, Library.Theme.Border, 0.45, 1)
		hoverLift(card)
		local rail = Instance.new("Frame")
		rail.Size = UDim2.new(1, -18, 0, 3)
		rail.Position = UDim2.new(0, 9, 0, -1.5)
		rail.AnchorPoint = Vector2.new(0, 1)
		rail.BackgroundColor3 = item.Color or Library.Theme.Accent
		rail.BackgroundTransparency = 0.4
		rail.BorderSizePixel = 0
		rail.Parent = card
		corner(rail, 2)
		local v = Instance.new("TextLabel")
		v.BackgroundTransparency = 1
		v.Position = UDim2.new(0, 12, 0, 10)
		v.Size = UDim2.new(1, -24, 0, 32)
		v.Text = tostring(item.Value or "0")
		v.TextColor3 = Library.Theme.Text
		v.Font = Enum.Font.GothamBold
		v.TextSize = 22
		v.TextXAlignment = Enum.TextXAlignment.Left
		v.Parent = card
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.new(0, 12, 0, 46)
		l.Size = UDim2.new(1, -24, 0, 20)
		l.Text = tostring(item.Name or "Metric")
		l.TextColor3 = Library.Theme.TextMuted
		l.Font = Enum.Font.GothamMedium
		l.TextSize = 13
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Parent = card
	end
	local api = { Frame = grid }
	function api:SetValues(newStats)
		for _, child in ipairs(grid:GetChildren()) do
			if child:IsA("Frame") and child:GetAttribute("ZenStatCard") then child:Destroy() end
		end
		stats = newStats or stats
		n = math.max(1, #stats)
		for i, item in ipairs(stats) do
			local card = Instance.new("Frame")
			card.Size = UDim2.new(1 / n, -((n - 1) * 10) / n, 1, 0)
			card.Position = UDim2.new((i - 1) / n, (i - 1) * 10 / n, 0, 0)
			card.BackgroundColor3 = Library.Theme.Element
			card.BorderSizePixel = 0
			card.Parent = grid
			card:SetAttribute("ZenStatCard", true)
			corner(card, 13)
			stroke(card, Library.Theme.Border, 0.45, 1)
			local v = Instance.new("TextLabel")
			v.BackgroundTransparency = 1
			v.Position = UDim2.new(0, 12, 0, 10)
			v.Size = UDim2.new(1, -24, 0, 32)
			v.Text = tostring(item.Value or "0")
			v.TextColor3 = Library.Theme.Text
			v.Font = Enum.Font.GothamBold
			v.TextSize = 22
			v.TextXAlignment = Enum.TextXAlignment.Left
			v.Parent = card
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Position = UDim2.new(0, 12, 0, 46)
			l.Size = UDim2.new(1, -24, 0, 20)
			l.Text = tostring(item.Name or "Metric")
			l.TextColor3 = Library.Theme.TextMuted
			l.Font = Enum.Font.GothamMedium
			l.TextSize = 13
			l.TextTruncate = Enum.TextTruncate.AtEnd
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.Parent = card
		end
		return self
	end
	return api
end

function Library:AIManifest()
	return {
		name = "ZenUI Apex",
		version = "3.0",
		core = "ZenUI.luau",
		extensions = {
			"CreateCommandCenter",
			"CreateStatusBar",
			"CreateContextMenu",
			"CreateStatGrid",
			"CreateSegmented",
			"CreateStepper",
			"CreateProgress",
			"CreateInfoCard",
			"CreateActionGroup",
			"CreateQuickToggle",
		},
		rules = {
			"Prefer Flags for persistent values",
			"Use stable Name fields for discovery",
			"Use Segmented for mutually exclusive modes",
			"Use Stepper for bounded numeric input",
			"Use Progress for live telemetry",
			"Use CommandCenter for searchable actions",
		},
	}
end

function Library:AIManifestJSON()
	local ok, v = pcall(HttpService.JSONEncode, HttpService, self:AIManifest())
	return ok and v or "{}"
end

function Library:Describe(query)
	local q = string.lower(tostring(query or ""))
	local m = self:AIManifest()
	if q == "" then return m end
	local out = {}
	for _, name in ipairs(m.extensions) do
		if string.find(string.lower(name), q, 1, true) then
			table.insert(out, name)
		end
	end
	return out
end

function Library:DestroyExtensions()
	for _, c in ipairs(Connections) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(Connections)
	for _, i in ipairs(Instances) do
		pcall(function()
			if i and i.Parent then i:Destroy() end
		end)
	end
	table.clear(Instances)
end

local function enhanceTab(tab)
	if not tab or tab.__ZenApexEnhanced then return tab end
	tab.__ZenApexEnhanced = true

	function tab:CreateSegmented(o)
		o = o or {}
		local values = o.Options or o.Values or { "One", "Two" }
		local current = o.CurrentOption or o.Default or values[1]
		local buttons = {}
		local rowFrame = row(self, "ZenSegmented", 46)
		rowFrame.BackgroundTransparency = 1
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 6)
		layout.Parent = rowFrame
		local state = { Value = current }
		local function applyState()
			for key, x in pairs(buttons) do
				local active = key == state.Value
				tw(x, {
					BackgroundColor3 = active and Library.Theme.Accent or (Library.Theme.SurfaceStrong or Library.Theme.Element),
					TextColor3 = active and Library.Theme.Background or Library.Theme.Text,
				}, 0.14)
				if active then
					hoverLift(x)
				end
			end
		end
		for i, v in ipairs(values) do
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1 / #values, -(6 * (#values - 1) / #values), 1, 0)
			b.BackgroundColor3 = Library.Theme.SurfaceStrong or Library.Theme.Element
			b.Text = tostring(v)
			b.TextColor3 = Library.Theme.Text
			b.Font = Enum.Font.GothamMedium
			b.TextSize = 13
			b.AutoButtonColor = false
			b.Parent = rowFrame
			corner(b, 10)
			hoverLift(b)
			buttons[v] = b
			con(b.MouseButton1Click, function()
				state.Value = v
				applyState()
				if o.Callback then task.spawn(o.Callback, v) end
			end)
		end
		local out = { Frame = rowFrame }
		function out:Get() return state.Value end
		function out:Set(v, silent)
			if buttons[v] then
				state.Value = v
				applyState()
				if not silent and o.Callback then task.spawn(o.Callback, v) end
			end
		end
		applyState()
		return out
	end

	function tab:CreateProgress(o)
		o = o or {}
		local max = tonumber(o.Max) or 100
		local value = math.clamp(tonumber(o.Value or o.Default) or 0, 0, max)
		local f = row(self, "ZenProgress", 64)
		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Position = UDim2.new(0, 12, 0, 6)
		title.Size = UDim2.new(1, -90, 0, 22)
		title.Text = o.Name or "Progress"
		title.TextColor3 = Library.Theme.Text
		title.Font = Enum.Font.GothamMedium
		title.TextSize = 14
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = f

		local pctLabel = Instance.new("TextLabel")
		pctLabel.BackgroundTransparency = 1
		pctLabel.Position = UDim2.new(1, -80, 0, 6)
		pctLabel.Size = UDim2.new(0, 68, 0, 22)
		pctLabel.Text = math.floor((value / max) * 100) .. "%"
		pctLabel.TextColor3 = Library.Theme.Accent
		pctLabel.Font = Enum.Font.GothamBold
		pctLabel.TextSize = 14
		pctLabel.TextXAlignment = Enum.TextXAlignment.Right
		pctLabel.Parent = f

		local trackBar = Instance.new("Frame")
		trackBar.Position = UDim2.new(0, 12, 0, 38)
		trackBar.Size = UDim2.new(1, -24, 0, 12)
		trackBar.BackgroundColor3 = Library.Theme.SurfaceStrong
		trackBar.BorderSizePixel = 0
		trackBar.Parent = f
		corner(trackBar, 10)

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(value / max, 0, 1, 0)
		fill.BackgroundColor3 = Library.Theme.Accent
		fill.BorderSizePixel = 0
		fill.Parent = trackBar
		corner(fill, 10)
		local grad = Instance.new("UIGradient")
		grad.Rotation = 90
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Library.Theme.Accent),
			ColorSequenceKeypoint.new(1, Library.Theme.Accent:Lerp(Color3.new(1, 1, 1), 0.3)),
		})
		grad.Parent = fill

		local glow = Instance.new("Frame")
		glow.Size = UDim2.new(1, 12, 1, 12)
		glow.Position = UDim2.new(0.5, 0, 0.5, 0)
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.BackgroundColor3 = Library.Theme.Accent
		glow.BackgroundTransparency = 1
		glow.BorderSizePixel = 0
		glow.Parent = fill

		local out = { Frame = f, Value = value, Max = max }
		function out:Set(v)
			out.Value = math.clamp(tonumber(v) or out.Value, 0, max)
			tw(fill, { Size = UDim2.new(out.Value / max, 0, 1, 0) }, 0.2)
			tw(glow, { BackgroundTransparency = 0.4 }, 0.2)
			pctLabel.Text = math.floor((out.Value / max) * 100) .. "%"
			if o.Callback then task.spawn(o.Callback, out.Value) end
		end
		function out:Get() return out.Value end
		function out:GetPercent() return out.Value / max end
		return out
	end

	function tab:CreateStepper(o)
		o = o or {}
		local min = tonumber(o.Min) or 0
		local max = tonumber(o.Max) or 100
		local step = math.abs(tonumber(o.Step or o.Increment) or 1)
		local value = math.clamp(tonumber(o.Default) or min, min, max)
		local f = row(self, "ZenStepper", 50)

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Position = UDim2.new(0, 12, 0, 0)
		label.Size = UDim2.new(1, -140, 1, 0)
		label.Text = o.Name or "Value"
		label.TextColor3 = Library.Theme.Text
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 15
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = f

		local down = Instance.new("TextButton")
		down.Size = UDim2.fromOffset(34, 34)
		down.Position = UDim2.new(1, -118, 0.5, -17)
		down.Text = "−"
		down.Font = Enum.Font.GothamBold
		down.TextSize = 18
		down.TextColor3 = Library.Theme.Text
		down.BackgroundColor3 = Library.Theme.SurfaceStrong
		down.AutoButtonColor = false
		down.Parent = f
		corner(down, 10)
		hoverLift(down)

		local valueLabel = Instance.new("TextLabel")
		valueLabel.Size = UDim2.fromOffset(64, 34)
		valueLabel.Position = UDim2.new(1, -79, 0.5, -17)
		valueLabel.Text = tostring(value)
		valueLabel.TextColor3 = Library.Theme.Accent
		valueLabel.Font = Enum.Font.GothamBold
		valueLabel.TextSize = 15
		valueLabel.Parent = f

		local up = Instance.new("TextButton")
		up.Size = UDim2.fromOffset(34, 34)
		up.Position = UDim2.new(1, -40, 0.5, -17)
		up.Text = "+"
		up.Font = Enum.Font.GothamBold
		up.TextSize = 18
		up.TextColor3 = Library.Theme.Text
		up.BackgroundColor3 = Library.Theme.SurfaceStrong
		up.AutoButtonColor = false
		up.Parent = f
		corner(up, 10)
		hoverLift(up)

		local out = { Frame = f, Value = value }
		local function set(v, silent)
			local snapped = min + math.floor(((v - min) / step) + 0.5) * step
			out.Value = math.clamp(snapped, min, max)
			valueLabel.Text = tostring(out.Value)
			if o.Flag then Library.Flags[o.Flag] = out.Value end
			if not silent and o.Callback then task.spawn(o.Callback, out.Value) end
		end
		con(down.MouseButton1Click, function() set(out.Value - step) end)
		con(up.MouseButton1Click, function() set(out.Value + step) end)
		function out:Get() return out.Value end
		function out:Set(v, silent) set(tonumber(v) or out.Value, silent) end
		function out:Increment() set(out.Value + step) end
		function out:Decrement() set(out.Value - step) end
		if o.Flag then Library.Flags[o.Flag] = value end
		return out
	end

	function tab:CreateInfoCard(o)
		o = o or {}
		return self:CreateParagraph({
			Title = o.Title or o.Name or "Info",
			Content = o.Content or o.Description or "",
		})
	end

	function tab:CreateActionGroup(o)
		o = o or {}
		local out = {}
		for _, a in ipairs(o.Actions or {}) do
			out[#out + 1] = self:CreateButton({ Name = a.Name or a.Label or "Action", Callback = a.Callback })
		end
		return out
	end

	function tab:CreateQuickToggle(name, callback, default)
		return self:CreateToggle({ Name = name, CurrentValue = default == true, Callback = callback })
	end

	return tab
end

local oldCreateWindow = Library.CreateWindow
Library.CreateWindow = function(self, o)
	o = type(o) == "table" and table.clone(o) or {}
	local w = oldCreateWindow(self, o)
	if type(w) == "table" and type(w.CreateTab) == "function" then
		local old = w.CreateTab
		w.CreateTab = function(win, opts)
			return enhanceTab(old(win, opts))
		end
	end
	return w
end

ENV.Library = Library
return function(target)
	Library = target or Library
	ENV.Library = Library
	return Library
end