--[=[
ZenUI Apex Edition
Copyright (c) 2026 PaveF. All rights reserved.
Official source: https://github.com/PaveF/ZenUI
License: see LICENSE

IMPORTANT:
This file is an official ZenUI entry point. Modified copies must not be
presented as official ZenUI builds or use ZenUI branding to imply endorsement.
]=]
local ENV=(getgenv and getgenv()) or _G
local CORE="https://raw.githubusercontent.com/PaveF/ZenUI/2bce1372ed8a5f813f2fd4deb42994b0c7c8a15e/ZenUI.luau"
local EXT="https://raw.githubusercontent.com/PaveF/ZenUI/main/ZenUI.Extensions.luau"
local SOURCE_ROOT="https://github.com/PaveF/ZenUI"
local OFFICIAL_AUTHOR="PaveF"
local OFFICIAL_VERSION="2.2"
local BUILD_ID="ZENUI-APEX-2.2"

local function loadRemote(url,name)
 local src=game:HttpGet(url)
 local chunk,err=(loadstring or load)(src,"="..name)
 assert(chunk,err)
 return chunk()
end

local Library=loadRemote(CORE,"ZenUI.ApexVisuals")
ENV.Library=Library

Library.Metadata={
 Name="ZenUI",
 Author=OFFICIAL_AUTHOR,
 Version=OFFICIAL_VERSION,
 Build=BUILD_ID,
 Repository=SOURCE_ROOT,
 License="ZenUI Source-Available License v1.0",
 Official=true,
 Provenance={
  EntryPoint="ZenUI.luau",
  CoreCommit="2bce1372ed8a5f813f2fd4deb42994b0c7c8a15e",
  Extensions="ZenUI.Extensions.luau",
  Notice="NOTICE.md",
  LicenseFile="LICENSE",
 }
}

function Library:GetBuildInfo()
 return table.clone(self.Metadata)
end

function Library:IsOfficialBuild()
 return self.Metadata and self.Metadata.Author==OFFICIAL_AUTHOR and self.Metadata.Repository==SOURCE_ROOT and self.Metadata.License=="ZenUI Source-Available License v1.0"
end

local ok,err=pcall(function()loadRemote(EXT,"ZenUI.Extensions")end)
Library.Apex={
 Version=OFFICIAL_VERSION,
 ExtensionURL=EXT,
 ExtensionLoaded=ok,
 ExtensionError=ok and nil or tostring(err),
 Features={"PremiumGlass","AmbientMotion","CommandCenter","StatusBar","ContextMenu","StatGrid","Segmented","Stepper","Progress","InfoCard","ActionGroup","QuickToggle","AIManifest","Provenance"}
}

function Library:LoadApexExtensions(force)
 if self.Apex.ExtensionLoaded and not force then return true end
 local success,reason=pcall(function()loadRemote(EXT,"ZenUI.Extensions")end)
 self.Apex.ExtensionLoaded=success
 self.Apex.ExtensionError=success and nil or tostring(reason)
 return success,reason
end

return Library
