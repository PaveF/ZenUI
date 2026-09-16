-- ZenUI Apex Edition
-- Premium visual layer + stable ZenUI core + advanced extension layer.
local ENV=(getgenv and getgenv()) or _G
local CORE="https://raw.githubusercontent.com/PaveF/ZenUI/2bce1372ed8a5f813f2fd4deb42994b0c7c8a15e/ZenUI.luau"
local EXT="https://raw.githubusercontent.com/PaveF/ZenUI/main/ZenUI.Extensions.luau"
local function loadRemote(url,name)
 local src=game:HttpGet(url)
 local chunk,err=(loadstring or load)(src,"="..name)
 assert(chunk,err)
 return chunk()
end
local Library=loadRemote(CORE,"ZenUI.ApexVisuals")
ENV.Library=Library
local ok,err=pcall(function()loadRemote(EXT,"ZenUI.Extensions")end)
Library.Apex={Version="2.1",ExtensionURL=EXT,ExtensionLoaded=ok,ExtensionError=ok and nil or tostring(err),Features={"PremiumGlass","AmbientMotion","CommandCenter","StatusBar","ContextMenu","StatGrid","Segmented","Stepper","Progress","InfoCard","ActionGroup","QuickToggle","AIManifest"}}
function Library:LoadApexExtensions(force)
 if self.Apex.ExtensionLoaded and not force then return true end
 local success,reason=pcall(function()loadRemote(EXT,"ZenUI.Extensions")end)
 self.Apex.ExtensionLoaded=success
 self.Apex.ExtensionError=success and nil or tostring(reason)
 return success,reason
end
return Library
