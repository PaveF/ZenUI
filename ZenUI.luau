--[=[
ZenUI Apex Edition
Copyright (c) 2026 PaveF. All rights reserved.
Official source: https://github.com/PaveF/ZenUI
License: see LICENSE

IMPORTANT:
This file is an official ZenUI entry point. Modified copies must not be
presented as official ZenUI builds or use ZenUI branding to imply endorsement.
]=]
local HttpService=game:GetService("HttpService")
local ENV=(getgenv and getgenv()) or _G
local CORE_COMMIT="2bce1372ed8a5f813f2fd4deb42994b0c7c8a15e"
local EXTENSION_COMMIT="78778774df0031c720e2152e5163dfec3595f606"
local CORE="https://raw.githubusercontent.com/PaveF/ZenUI/"..CORE_COMMIT.."/ZenUI.luau"
local EXT="https://raw.githubusercontent.com/PaveF/ZenUI/"..EXTENSION_COMMIT.."/ZenUI.Extensions.luau"
local SOURCE_ROOT="https://github.com/PaveF/ZenUI"
local MANIFEST="https://raw.githubusercontent.com/PaveF/ZenUI/main/OFFICIAL_BUILD.json"
local OFFICIAL_AUTHOR="PaveF"
local OFFICIAL_VERSION="2.3"
local BUILD_ID="ZENUI-APEX-2.3"
local SOURCE_BLOB="UNPUBLISHED"

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
 SourceFile="ZenUI.luau",
 SourceBlob=SOURCE_BLOB,
 ManifestURL=MANIFEST,
 Provenance={
  EntryPoint="ZenUI.luau",
  CoreCommit=CORE_COMMIT,
  ExtensionCommit=EXTENSION_COMMIT,
  Notice="NOTICE.md",
  LicenseFile="LICENSE",
  AuthenticityModel="provenance",
 }
}

function Library:GetBuildInfo()
 return table.clone(self.Metadata)
end

function Library:GetOfficialRepository()
 return SOURCE_ROOT
end

function Library:IsOfficialBuild()
 return self.Metadata and self.Metadata.Official==true and self.Metadata.Author==OFFICIAL_AUTHOR and self.Metadata.Repository==SOURCE_ROOT and self.Metadata.License=="ZenUI Source-Available License v1.0" and self.Metadata.SourceBlob~="UNPUBLISHED"
end

function Library:FetchOfficialManifest()
 local ok,raw=pcall(function() return game:HttpGet(MANIFEST) end)
 if not ok or type(raw)~="string" then return nil,"Unable to fetch official provenance manifest." end
 local decodedOk,data=pcall(function() return HttpService:JSONDecode(raw) end)
 if not decodedOk or type(data)~="table" then return nil,"Official provenance manifest is invalid." end
 return data
end

function Library:VerifyOfficialBuild(fetchRemote)
 local result={
  status="unknown",
  official=false,
  repository=self.Metadata.Repository,
  build=self.Metadata.Build,
  version=self.Metadata.Version,
  source_blob=self.Metadata.SourceBlob,
  core_commit=CORE_COMMIT,
  extension_commit=EXTENSION_COMMIT,
  manifest_url=MANIFEST,
  reasons={},
 }
 if self.Metadata.Repository~=SOURCE_ROOT then result.status="unofficial"; table.insert(result.reasons,"Repository is not canonical."); return result end
 if self.Metadata.SourceBlob=="UNPUBLISHED" then
  result.status="unverified"
  table.insert(result.reasons,"This entry point has not yet been assigned its published source fingerprint.")
  if fetchRemote==false then return result end
 end
 if fetchRemote~=false then
  local manifest,err=self:FetchOfficialManifest()
  if not manifest then table.insert(result.reasons,err); return result end
  result.manifest=manifest
  local matches=manifest.project==self.Metadata.Name
   and manifest.author==self.Metadata.Author
   and manifest.repository==self.Metadata.Repository
   and manifest.license==self.Metadata.License
   and manifest.official_source_file==self.Metadata.SourceFile
   and manifest.official_version==self.Metadata.Version
   and manifest.build_id==self.Metadata.Build
   and manifest.core_commit==CORE_COMMIT
   and manifest.extension_commit==EXTENSION_COMMIT
   and manifest.official_source_blob==self.Metadata.SourceBlob
  if matches and self.Metadata.SourceBlob~="UNPUBLISHED" then
   result.status="official"
   result.official=true
   result.reasons={"Local provenance matches the canonical published manifest."}
  else
   result.status="modified-or-unofficial"
   result.reasons={"Local provenance does not match the canonical published manifest.","Treat this distribution as modified or unofficial until manually verified."}
  end
 end
 return result
end

function Library:GetAuthenticityStatus(fetchRemote)
 local result=self:VerifyOfficialBuild(fetchRemote)
 return result.status,result
end

local ok,err=pcall(function()loadRemote(EXT,"ZenUI.Extensions")end)
Library.Apex={
 Version=OFFICIAL_VERSION,
 ExtensionURL=EXT,
 ExtensionCommit=EXTENSION_COMMIT,
 ExtensionLoaded=ok,
 ExtensionError=ok and nil or tostring(err),
 Features={"PremiumGlass","AmbientMotion","CommandCenter","StatusBar","ContextMenu","StatGrid","Segmented","Stepper","Progress","InfoCard","ActionGroup","QuickToggle","AIManifest","Provenance","AuthenticityVerification"}
}

function Library:LoadApexExtensions(force)
 if self.Apex.ExtensionLoaded and not force then return true end
 local success,reason=pcall(function()loadRemote(EXT,"ZenUI.Extensions")end)
 self.Apex.ExtensionLoaded=success
 self.Apex.ExtensionError=success and nil or tostring(reason)
 return success,reason
end

return Library
