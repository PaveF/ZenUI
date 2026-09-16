-- ZenUI Premium Visual Edition
-- Keeps the original API and adds a polished visual skin around every window.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
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
local function con(signal, fn) local ok,c=pcall(function() return signal:Connect(fn) end); if ok and c then table.insert(ExtraConnections,c) end return c end
local function tw(i,p,t,s,d) if not i or not i.Parent then return end local ok,a=pcall(function() return TweenService:Create(i,TweenInfo.new(t or .2,s or Enum.EasingStyle.Quint,d or Enum.EasingDirection.Out),p) end); if ok then a:Play() end end
local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 12); c.Parent=p end
local function stroke(p,c,tr,w) local s=Instance.new("UIStroke"); s.Color=c; s.Transparency=tr or .4; s.Thickness=w or 1; s.Parent=p; return s end
local function premium(window,opts)
    if not window or not window.Parent or window:GetAttribute("ZenPremium") then return end
    window:SetAttribute("ZenPremium",true)
    local accent=(opts and opts.AccentColor); if typeof(accent)~="Color3" then accent=Color3.fromRGB(78,255,185) end
    local text=Color3.fromRGB(244,247,250); local muted=Color3.fromRGB(142,151,161); local hover=Color3.fromRGB(27,36,43)
    window.BackgroundColor3=Color3.fromRGB(8,12,16); window.BackgroundTransparency=0; window.ZIndex=2; corner(window,20)
    local ws=window:FindFirstChildOfClass("UIStroke"); if ws then ws.Color=accent; ws.Transparency=.76; ws.Thickness=1.25 else stroke(window,accent,.76,1.25) end
    local shadow=Instance.new("Frame"); shadow.Name="ZenPremiumShadow"; shadow.AnchorPoint=Vector2.new(.5,.5); shadow.Position=window.Position; shadow.Size=UDim2.new(0,window.Size.X.Offset+38,0,window.Size.Y.Offset+38); shadow.BackgroundColor3=Color3.new(0,0,0); shadow.BackgroundTransparency=.5; shadow.BorderSizePixel=0; shadow.ZIndex=0; shadow.Parent=window.Parent; corner(shadow,28)
    con(RunService.RenderStepped,function() if shadow.Parent and window.Parent then shadow.Position=window.Position; shadow.Size=UDim2.new(0,window.AbsoluteSize.X+38,0,window.AbsoluteSize.Y+38) end end)
    local ambient=Instance.new("Frame"); ambient.Name="ZenPremiumAmbient"; ambient.Size=UDim2.fromScale(1,1); ambient.BackgroundTransparency=1; ambient.ClipsDescendants=true; ambient.ZIndex=1; ambient.Parent=window
    for n,pos,size,col,tr in pairs({A={UDim2.new(1,-120,0,-110),250,accent,.93},B={UDim2.new(0,-90,1,-80),210,Color3.fromRGB(92,125,255),.95}}) do local o=Instance.new("Frame"); o.Name="Orb"..n; o.Position=pos; o.Size=UDim2.fromOffset(size,size); o.BackgroundColor3=col; o.BackgroundTransparency=tr; o.BorderSizePixel=0; o.Parent=ambient; corner(o,999) end
    con(RunService.RenderStepped,function() if not ambient.Parent then return end local t=os.clock(); local a=ambient.OrbA; local b=ambient.OrbB; a.Position=UDim2.new(1,-120+math.sin(t*.38)*18,0,-110+math.cos(t*.31)*14); b.Position=UDim2.new(0,-90+math.cos(t*.28)*16,1,-80+math.sin(t*.34)*15) end)
    local sheen=Instance.new("Frame"); sheen.Name="ZenPremiumSheen"; sheen.Size=UDim2.new(0,170,1,0); sheen.Position=UDim2.new(-.3,0,0,0); sheen.BackgroundColor3=Color3.new(1,1,1); sheen.BackgroundTransparency=.96; sheen.BorderSizePixel=0; sheen.ZIndex=5; sheen.Parent=window
    corner(sheen,20)
    task.spawn(function() while sheen.Parent do tw(sheen,{Position=UDim2.new(1.15,0,0,0)},1.15,Enum.EasingStyle.Linear); task.wait(4); sheen.Position=UDim2.new(-.3,0,0,0); task.wait(.2) end end)
    local header=window:FindFirstChild("Header"); if header then header.BackgroundColor3=Color3.fromRGB(12,17,23); header.BackgroundTransparency=.02; corner(header,18); stroke(header,Color3.new(1,1,1),.92,1) end
    local sidebar=window:FindFirstChild("Sidebar"); if sidebar then sidebar.BackgroundColor3=Color3.fromRGB(10,15,20); sidebar.BackgroundTransparency=.01; corner(sidebar,16) end
    local content=window:FindFirstChild("ContentContainer"); if content then local top=content:FindFirstChild("ContentTop"); if top then top.BackgroundColor3=Color3.fromRGB(13,19,25); top.BackgroundTransparency=.02; corner(top,14); stroke(top,accent,.87,1) end end
    for _,i in ipairs(window:GetDescendants()) do
        if i:IsA("TextLabel") or i:IsA("TextButton") or i:IsA("TextBox") then if i.TextColor3==Color3.fromRGB(248,248,250) then i.TextColor3=text elseif i.TextColor3==Color3.fromRGB(150,152,158) then i.TextColor3=muted end end
        if i:IsA("GuiButton") and not i:GetAttribute("ZenPremiumButton") then
            i:SetAttribute("ZenPremiumButton",true); local sc=Instance.new("UIScale"); sc.Name="ZenPremiumScale"; sc.Parent=i
            local base=i.BackgroundColor3
            con(i.MouseEnter,function() tw(sc,{Scale=1.025},.15,Enum.EasingStyle.Back); if i.BackgroundTransparency<1 then tw(i,{BackgroundColor3=hover},.14) end end)
            con(i.MouseLeave,function() tw(sc,{Scale=1},.16,Enum.EasingStyle.Back); if i.BackgroundTransparency<1 then tw(i,{BackgroundColor3=base},.14) end end)
            con(i.MouseButton1Down,function() tw(sc,{Scale=.965},.07,Enum.EasingStyle.Quad) end)
            con(i.MouseButton1Up,function() tw(sc,{Scale=1.025},.1,Enum.EasingStyle.Back) end)
        end
        if i:IsA("Frame") and (string.find(string.lower(i.Name),"toggle",1,true) or string.find(string.lower(i.Name),"slider",1,true) or string.find(string.lower(i.Name),"dropdown",1,true) or string.find(string.lower(i.Name),"button",1,true)) then corner(i,12) end
    end
    con(window.DescendantAdded,function(i) task.defer(function() if i.Parent and i:IsA("GuiButton") and not i:GetAttribute("ZenPremiumButton") then i:SetAttribute("ZenPremiumButton",true); local sc=Instance.new("UIScale"); sc.Name="ZenPremiumScale"; sc.Parent=i; con(i.MouseEnter,function() tw(sc,{Scale=1.025},.15,Enum.EasingStyle.Back) end); con(i.MouseLeave,function() tw(sc,{Scale=1},.16,Enum.EasingStyle.Back) end); con(i.MouseButton1Down,function() tw(sc,{Scale=.965},.07,Enum.EasingStyle.Quad) end); con(i.MouseButton1Up,function() tw(sc,{Scale=1.025},.1,Enum.EasingStyle.Back) end) end end) end)
    pcall(function() Library:SetAccentColor(accent) end)
end
local oldCreate=Library.CreateWindow
local oldDestroy=Library.Destroy
Library.CreateWindow=function(self,options) options=type(options)=="table" and table.clone(options) or {}; if typeof(options.AccentColor)~="Color3" then options.AccentColor=Color3.fromRGB(78,255,185) end; options.UIScale=math.clamp(tonumber(options.UIScale) or .94,.78,1.15); local w=oldCreate(self,options); task.defer(function() premium(self.MainFrame,options) end); return w end
Library.Destroy=function(self,...) for _,c in ipairs(ExtraConnections) do pcall(function() c:Disconnect() end) end; table.clear(ExtraConnections); return oldDestroy(self,...) end
ENV.Library=Library
return Library
