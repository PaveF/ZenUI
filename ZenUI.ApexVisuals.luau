-- ZenUI Apex Visual System
-- Stable visual enhancement layer: preserves core layout and avoids animated overlays.
local TweenService = game:GetService("TweenService")
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
        tween(scale, {Scale = 1.015}, 0.12, Enum.EasingStyle.Back)
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
        tween(scale, {Scale = 0.985}, 0.06, Enum.EasingStyle.Quad)
    end)
    con(button.MouseButton1Up, function()
        tween(scale, {Scale = 1.015}, 0.08, Enum.EasingStyle.Back)
    end)
end

local function applySkin(window, options)
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
    corner(window, 18)
    accentStroke(window, accent, 0.74, 1.15)

    local header = window:FindFirstChild("Header")
    if header then
        header.BackgroundColor3 = panel
        header.BackgroundTransparency = 0
        header.ClipsDescendants = true
        corner(header, 16)
        accentStroke(header, Library.Theme.Border, 0.72, 1)
    end

    local sidebar = window:FindFirstChild("Sidebar")
    if sidebar then
        sidebar.BackgroundColor3 = panelSoft
        sidebar.BackgroundTransparency = 0
        sidebar.ClipsDescendants = true
        corner(sidebar, 14)
        accentStroke(sidebar, Library.Theme.Border, 0.82, 1)
    end

    local content = window:FindFirstChild("ContentContainer")
    if content then
        local top = content:FindFirstChild("ContentTop")
        if top then
            top.BackgroundColor3 = panel
            top.BackgroundTransparency = 0
            corner(top, 12)
            accentStroke(top, accent, 0.86, 1)
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
        end
    end

    con(window.DescendantAdded, function(instance)
        task.defer(function()
            if instance.Parent and instance:IsA("GuiButton") then
                styleButton(instance, hover, instance.BackgroundColor3)
            end
        end)
    end)

    pcall(function()
        Library:SetAccentColor(accent)
    end)
end

local oldCreateWindow = Library.CreateWindow
local oldDestroy = Library.Destroy

Library.CreateWindow = function(self, options)
    options = type(options) == "table" and table.clone(options) or {}
    if typeof(options.AccentColor) ~= "Color3" then
        options.AccentColor = Color3.fromRGB(78, 255, 185)
    end
    options.UIScale = math.clamp(tonumber(options.UIScale) or 0.90, 0.80, 1.08)
    local window = oldCreateWindow(self, options)
    task.defer(function()
        applySkin(self.MainFrame, options)
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
return Library
