-- ZenUI Apex Edition
-- Premium visual layer + composable advanced controls + AI-facing capability metadata.
-- The original ZenUI core remains the rendering/behavior engine; this file adds a stable, discoverable extension layer.
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ENV = (getgenv and getgenv()) or _G

local CORE = "https://raw.githubusercontent.com/PaveF/ZenUI/cad0cb56f3c51fabb0d6445fc8adf187b95d1f95/ZenUI.luau"
local function loadCore()
    local src = game:HttpGet(CORE)
    local chunk, err = (loadstring or load)(src, "=ZenUI.Core")
    assert(chunk, err)
    return chunk()
end

local Library = loadCore()
local ExtraConnections = {}
local ExtraInstances = {}
local EnhancedWindows = setmetatable({}, { __mode = "k" })
local EnhancedTabs = setmetatable({}, { __mode = "k" })

local function con(signal, fn)
    local ok, connection = pcall(function() return signal:Connect(fn) end)
    if ok and connection then table.insert(ExtraConnections, connection) end
    return connection
end

local function track(instance)
    if instance then table.insert(ExtraInstances, instance) end
    return instance
end

local function tw(i, props, duration, style, direction)
    if not i or not i.Parent then return end
    pcall(function()
        TweenService:Create(i, TweenInfo.new(duration or .2, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), props):Play()
    end)
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = parent
    return c
end

local function stroke(parent, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Transparency = transparency or .4
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function clampNumber(v, min, max)
    v = tonumber(v) or min
    return math.clamp(v, min, max)
end

local function normalizeOptions(options)
    return type(options) == "table" and table.clone(options) or {}
end

local DEFAULT_ACCENT = Color3.fromRGB(78, 255, 185)
local PREMIUM_TEXT = Color3.fromRGB(244, 247, 250)
local PREMIUM_MUTED = Color3.fromRGB(142, 151, 161)
local PREMIUM_HOVER = Color3.fromRGB(27, 36, 43)

local function bindButton(button, accent)
    if not button or not button:IsA("GuiButton") or button:GetAttribute("ZenApexBound") then return end
    button:SetAttribute("ZenApexBound", true)
    local scale = Instance.new("UIScale")
    scale.Name = "ZenApexScale"
    scale.Parent = button
    local base = button.BackgroundColor3
    con(button.MouseEnter, function()
        tw(scale, { Scale = 1.025 }, .15, Enum.EasingStyle.Back)
        if button.BackgroundTransparency < 1 then
            tw(button, { BackgroundColor3 = PREMIUM_HOVER }, .14)
        end
    end)
    con(button.MouseLeave, function()
        tw(scale, { Scale = 1 }, .16, Enum.EasingStyle.Back)
        if button.Parent and button.BackgroundTransparency < 1 then
            tw(button, { BackgroundColor3 = base }, .14)
        end
    end)
    con(button.MouseButton1Down, function() tw(scale, { Scale = .965 }, .07, Enum.EasingStyle.Quad) end)
    con(button.MouseButton1Up, function() tw(scale, { Scale = 1.025 }, .1, Enum.EasingStyle.Back) end)
end

local function premium(window, opts)
    if not window or not window.Parent or window:GetAttribute("ZenApexPremium") then return end
    window:SetAttribute("ZenApexPremium", true)
    local accent = opts and opts.AccentColor
    if typeof(accent) ~= "Color3" then accent = DEFAULT_ACCENT end

    window.BackgroundColor3 = Color3.fromRGB(7, 11, 15)
    window.BackgroundTransparency = 0
    window.ZIndex = 2
    corner(window, 20)
    local outerStroke = window:FindFirstChildOfClass("UIStroke") or stroke(window, accent, .76, 1.25)
    outerStroke.Color = accent
    outerStroke.Transparency = .76
    outerStroke.Thickness = 1.25

    local shadow = track(Instance.new("Frame"))
    shadow.Name = "ZenApexShadow"
    shadow.AnchorPoint = Vector2.new(.5, .5)
    shadow.Position = window.Position
    shadow.Size = UDim2.new(0, window.AbsoluteSize.X + 44, 0, window.AbsoluteSize.Y + 44)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = .48
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 0
    shadow.Parent = window.Parent
    corner(shadow, 28)
    con(RunService.RenderStepped, function()
        if shadow.Parent and window.Parent then
            shadow.Position = window.Position
            shadow.Size = UDim2.fromOffset(window.AbsoluteSize.X + 44, window.AbsoluteSize.Y + 44)
        end
    end)

    local ambient = track(Instance.new("Frame"))
    ambient.Name = "ZenApexAmbient"
    ambient.Size = UDim2.fromScale(1, 1)
    ambient.BackgroundTransparency = 1
    ambient.ClipsDescendants = true
    ambient.ZIndex = 1
    ambient.Parent = window
    local orbA = track(Instance.new("Frame")); orbA.Name = "OrbA"; orbA.Size = UDim2.fromOffset(280,280); orbA.BackgroundColor3 = accent; orbA.BackgroundTransparency = .935; orbA.BorderSizePixel = 0; orbA.Parent = ambient; corner(orbA, 999)
    local orbB = track(Instance.new("Frame")); orbB.Name = "OrbB"; orbB.Size = UDim2.fromOffset(240,240); orbB.BackgroundColor3 = Color3.fromRGB(93, 126, 255); orbB.BackgroundTransparency = .955; orbB.BorderSizePixel = 0; orbB.Parent = ambient; corner(orbB, 999)
    local orbC = track(Instance.new("Frame")); orbC.Name = "OrbC"; orbC.Size = UDim2.fromOffset(180,180); orbC.BackgroundColor3 = Color3.fromRGB(255, 102, 194); orbC.BackgroundTransparency = .968; orbC.BorderSizePixel = 0; orbC.Parent = ambient; corner(orbC, 999)
    con(RunService.RenderStepped, function()
        if not ambient.Parent then return end
        local t = os.clock()
        orbA.Position = UDim2.new(1, -145 + math.sin(t*.32)*22, 0, -135 + math.cos(t*.25)*18)
        orbB.Position = UDim2.new(0, -110 + math.cos(t*.21)*20, 1, -112 + math.sin(t*.29)*20)
        orbC.Position = UDim2.new(.52, -90 + math.sin(t*.17)*26, .56, -90 + math.cos(t*.23)*24)
    end)

    local sheen = track(Instance.new("Frame"))
    sheen.Name = "ZenApexSheen"
    sheen.Size = UDim2.new(0, 160, 1, 0)
    sheen.Position = UDim2.new(-.25, 0, 0, 0)
    sheen.BackgroundColor3 = Color3.new(1,1,1)
    sheen.BackgroundTransparency = .965
    sheen.BorderSizePixel = 0
    sheen.ZIndex = 5
    sheen.Parent = window
    corner(sheen, 20)
    task.spawn(function()
        while sheen.Parent do
            tw(sheen, { Position = UDim2.new(1.15, 0, 0, 0) }, 1.2, Enum.EasingStyle.Linear)
            task.wait(4.5)
            sheen.Position = UDim2.new(-.25, 0, 0, 0)
            task.wait(.2)
        end
    end)

    local header = window:FindFirstChild("Header")
    if header then header.BackgroundColor3 = Color3.fromRGB(12,17,23); header.BackgroundTransparency = .015; corner(header,18); stroke(header,Color3.new(1,1,1),.93,1) end
    local sidebar = window:FindFirstChild("Sidebar")
    if sidebar then sidebar.BackgroundColor3 = Color3.fromRGB(9,14,19); sidebar.BackgroundTransparency = .01; corner(sidebar,16) end
    local content = window:FindFirstChild("ContentContainer")
    if content then
        local top = content:FindFirstChild("ContentTop")
        if top then top.BackgroundColor3 = Color3.fromRGB(13,19,25); top.BackgroundTransparency = .02; corner(top,14); stroke(top,accent,.86,1) end
    end

    for _, item in ipairs(window:GetDescendants()) do
        if item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox") then
            if item.TextColor3 == Color3.fromRGB(248,248,250) then item.TextColor3 = PREMIUM_TEXT end
            if item.TextColor3 == Color3.fromRGB(150,152,158) then item.TextColor3 = PREMIUM_MUTED end
        end
        if item:IsA("GuiButton") then bindButton(item, accent) end
    end
    con(window.DescendantAdded, function(item)
        task.defer(function()
            if item.Parent and item:IsA("GuiButton") then bindButton(item, accent) end
        end)
    end)
    pcall(function() Library:SetAccentColor(accent) end)
end

-- -------------------------------------------------------------------------
-- Apex controls: composable controls built from the stable ZenUI primitives.
-- -------------------------------------------------------------------------
local function enhanceTab(tab)
    if not tab or EnhancedTabs[tab] then return tab end
    EnhancedTabs[tab] = true

    function tab:CreateSegmented(options)
        options = options or {}
        local values = options.Options or options.Values or { "One", "Two" }
        local current = options.CurrentOption or options.Default or values[1]
        local state = { Value = current }
        local buttons = {}
        local parent = self
        local section = options.Section
        local title = options.Name or "Segmented"
        local callbacks = options.Callback

        local function activate(value, silent)
            state.Value = value
            for key, button in pairs(buttons) do
                local active = key == value
                if button and button.Parent then
                    tw(button, { BackgroundColor3 = active and (Library.Theme.Accent or DEFAULT_ACCENT) or (Library.Theme.Element or Color3.fromRGB(20,23,28)) }, .14)
                    button.TextColor3 = active and (Library.Theme.Background or Color3.fromRGB(8,9,11)) or (Library.Theme.Text or PREMIUM_TEXT)
                end
            end
            if not silent and type(callbacks) == "function" then task.spawn(callbacks, value) end
        end

        local label = parent:CreateLabel({ Name = title })
        local row = Instance.new("Frame")
        row.Name = "ApexSegmented"
        row.Size = UDim2.new(1,0,0,38)
        row.BackgroundTransparency = 1
        row.Parent = (parent._ParentOverride or nil) or label.Parent
        track(row)
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.Padding = UDim.new(0,6)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = row
        for index, value in ipairs(values) do
            local button = Instance.new("TextButton")
            button.Name = "Option"..index
            button.AutoButtonColor = false
            button.Size = UDim2.new(1/#values, -((#values-1)*6/#values), 1, 0)
            button.BackgroundColor3 = Color3.fromRGB(20,23,28)
            button.TextColor3 = PREMIUM_TEXT
            button.Font = Enum.Font.GothamMedium
            button.TextSize = 11
            button.Text = tostring(value)
            button.LayoutOrder = index
            button.Parent = row
            corner(button, 10); stroke(button, Library.Theme.Border or Color3.fromRGB(55,60,68), .45, 1)
            buttons[value] = button
            bindButton(button, DEFAULT_ACCENT)
            con(button.MouseButton1Click, function() activate(value) end)
        end
        activate(current, true)
        local result = {}
        function result:Get() return state.Value end
        function result:Set(value, silent)
            for _, v in ipairs(values) do if v == value then activate(value, silent); return end end
        end
        result.Frame = row
        result.Options = values
        return result
    end

    function tab:CreateStepper(options)
        options = options or {}
        local min = tonumber(options.Min) or 0
        local max = tonumber(options.Max) or 100
        local step = math.abs(tonumber(options.Step or options.Increment) or 1)
        local value = clampNumber(options.Default, min, max)
        local title = options.Name or "Value"
        local state = { Value = value }
        local callbacks = options.Callback
        local box = self:CreateTextBox({ Name = title, PlaceholderText = tostring(value), Text = tostring(value), Callback = function(text) end })
        local frame = box.Container or box.Frame or nil
        local out = { Value = value, Input = box, Frame = frame }
        local function set(v, silent)
            local snapped = min + math.floor(((v - min) / step) + .5) * step
            state.Value = math.clamp(snapped, min, max)
            out.Value = state.Value
            if options.Flag then Library.Flags[options.Flag] = state.Value end
            if not silent and type(callbacks) == "function" then task.spawn(callbacks, state.Value) end
        end
        function out:Get() return state.Value end
        function out:Set(v, silent) set(tonumber(v) or state.Value, silent) end
        if options.Flag then Library.Flags[options.Flag] = value end
        return out
    end

    function tab:CreateProgress(options)
        options = options or {}
        local max = tonumber(options.Max) or 100
        local value = math.clamp(tonumber(options.Value or options.Default) or 0, 0, max)
        local title = options.Name or "Progress"
        local container = Instance.new("Frame")
        container.Name = "ApexProgress"
        container.Size = UDim2.new(1,0,0,54)
        container.BackgroundColor3 = Library.Theme.Element or Color3.fromRGB(18,20,24)
        container.BorderSizePixel = 0
        container.Parent = self._ParentOverride or self.Page or (self.Elements and self.Elements[#self.Elements])
        track(container); corner(container,11); stroke(container, Library.Theme.Border or Color3.fromRGB(55,60,68), .45, 1)
        local text = Instance.new("TextLabel"); text.BackgroundTransparency=1; text.Position=UDim2.new(0,10,0,5); text.Size=UDim2.new(1,-20,0,18); text.Font=Enum.Font.GothamMedium; text.TextSize=11; text.TextColor3=Library.Theme.Text or PREMIUM_TEXT; text.TextXAlignment=Enum.TextXAlignment.Left; text.Text=title; text.Parent=container
        local trackBar = Instance.new("Frame"); trackBar.Position=UDim2.new(0,10,0,29); trackBar.Size=UDim2.new(1,-20,0,10); trackBar.BackgroundColor3=Library.Theme.SurfaceStrong or Color3.fromRGB(25,28,33); trackBar.BorderSizePixel=0; trackBar.Parent=container; corner(trackBar,8)
        local fill = Instance.new("Frame"); fill.Size=UDim2.new(value/max,0,1,0); fill.BackgroundColor3=Library.Theme.Accent or DEFAULT_ACCENT; fill.BorderSizePixel=0; fill.Parent=trackBar; corner(fill,8)
        table.insert(self.Elements, container)
        local out = { Value=value, Max=max, Frame=container }
        function out:Set(v)
            out.Value=math.clamp(tonumber(v) or out.Value,0,max)
            tw(fill,{Size=UDim2.new(out.Value/max,0,1,0)},.22)
            if options.Callback then task.spawn(options.Callback,out.Value) end
        end
        function out:Get() return out.Value end
        return out
    end

    function tab:CreateInfoCard(options)
        options = options or {}
        local card = self:CreateParagraph({ Title = options.Title or options.Name or "Info", Content = options.Content or options.Description or "" })
        return card
    end

    function tab:CreateActionGroup(options)
        options = options or {}
        local actions = {}
        for _, item in ipairs(options.Actions or {}) do
            local button = self:CreateButton({ Name = item.Name or item.Label or "Action", Callback = item.Callback })
            actions[#actions+1] = button
        end
        return actions
    end

    function tab:CreateQuickToggle(name, callback, default)
        return self:CreateToggle({ Name=name, CurrentValue=default == true, Callback=callback })
    end

    return tab
end

-- -------------------------------------------------------------------------
-- AI-facing contract. Keep this intentionally plain-data and deterministic so
-- an AI can inspect it, serialize it, or use it to select controls.
-- -------------------------------------------------------------------------
Library.AI = {
    Version = "1.1",
    Name = "ZenUI Apex Control Contract",
    Description = "Composable Roblox UI primitives plus advanced controls designed for human and AI-authored interfaces.",
    CoreURL = CORE,
    Capabilities = {
        Toggle = { Kind="boolean", Create="CreateToggle", Mutability="live" },
        Slider = { Kind="number", Create="CreateSlider", Mutability="live" },
        Dropdown = { Kind="enum", Create="CreateDropdown", Mutability="live" },
        MultiDropdown = { Kind="set", Create="CreateDropdown", Mutability="live" },
        Keybind = { Kind="key", Create="CreateKeybind", Mutability="live" },
        TextBox = { Kind="string", Create="CreateTextBox", Mutability="live" },
        Button = { Kind="action", Create="CreateButton", Mutability="event" },
        ColorPicker = { Kind="color", Create="CreateColorPicker", Mutability="live" },
        Segmented = { Kind="enum", Create="CreateSegmented", Mutability="live" },
        Stepper = { Kind="number", Create="CreateStepper", Mutability="live" },
        Progress = { Kind="progress", Create="CreateProgress", Mutability="live" },
        InfoCard = { Kind="information", Create="CreateInfoCard", Mutability="display" },
        ActionGroup = { Kind="action-group", Create="CreateActionGroup", Mutability="event" },
    },
    Rules = {
        "Prefer Flags for persistent state.",
        "Give controls stable Name values so search can discover them.",
        "Use CreateSegmented for mutually-exclusive modes.",
        "Use CreateStepper for bounded numeric values.",
        "Use CreateProgress for telemetry or task progress.",
        "Use CreateInfoCard for compact context before controls.",
        "Prefer callbacks that accept the new value as their first argument.",
    },
}

function Library:AIManifest(asJson)
    local manifest = {
        version = Library.AI.Version,
        name = Library.AI.Name,
        capabilities = Library.AI.Capabilities,
        conventions = Library.AI.Rules,
        methods = { "new", "CreateWindow", "Notify", "SetTheme", "SetAccentColor" },
    }
    if asJson then
        local ok, encoded = pcall(HttpService.JSONEncode, HttpService, manifest)
        if ok then return encoded end
    end
    return manifest
end

function Library:DescribeAI(query)
    if type(query) ~= "string" or query == "" then return Library:AIManifest(false) end
    local q = string.lower(query)
    local results = {}
    for name, info in pairs(Library.AI.Capabilities) do
        if string.find(string.lower(name), q, 1, true) or string.find(string.lower(info.Kind), q, 1, true) or string.find(string.lower(info.Create), q, 1, true) then
            results[name] = info
        end
    end
    return results
end

-- Window enhancement --------------------------------------------------------
local oldCreateWindow = Library.CreateWindow
local oldDestroy = Library.Destroy

Library.CreateWindow = function(self, options)
    options = normalizeOptions(options)
    if typeof(options.AccentColor) ~= "Color3" then options.AccentColor = DEFAULT_ACCENT end
    options.UIScale = math.clamp(tonumber(options.UIScale) or .92, .78, 1.15)
    local window = oldCreateWindow(self, options)
    if type(window) == "table" then
        EnhancedWindows[window] = true
        local oldCreateTab = window.CreateTab
        if type(oldCreateTab) == "function" then
            window.CreateTab = function(win, tabOptions)
                local tab = oldCreateTab(win, tabOptions)
                return enhanceTab(tab)
            end
        end
    end
    task.defer(function() premium(self.MainFrame, options) end)
    return window
end

-- Also patch the currently active factory when the core exposes a default tab creator.
local function patchExistingWindows()
    for _, win in ipairs(Library.Windows or {}) do
        if type(win) == "table" and type(win.CreateTab) == "function" and not EnhancedWindows[win] then
            local old = win.CreateTab
            win.CreateTab = function(w, opts) return enhanceTab(old(w, opts)) end
            EnhancedWindows[win] = true
        end
    end
end
patchExistingWindows()

Library.Destroy = function(self, ...)
    for _, connection in ipairs(ExtraConnections) do pcall(function() connection:Disconnect() end) end
    table.clear(ExtraConnections)
    for _, instance in ipairs(ExtraInstances) do pcall(function() if instance and instance.Parent then instance:Destroy() end end) end
    table.clear(ExtraInstances)
    return oldDestroy(self, ...)
end

ENV.Library = Library
return Library
