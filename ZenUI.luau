--[=[
ZenUI Apex Edition v3
Copyright (c) 2026 PaveF. All rights reserved.
Official source: https://github.com/PaveF/ZenUI
License: see LICENSE

IMPORTANT:
This file is an official ZenUI entry point. Modified copies must not be
presented as official ZenUI builds or use ZenUI branding to imply endorsement.
]=]
local HttpService = game:GetService("HttpService")
local ENV = (getgenv and getgenv()) or _G
local BUILD_ID = "ZENUI-APEX-3.0.0"
local PROVENANCE_ID = "ZENUI-PROV-3.0.0"
local SOURCE_ROOT = "https://github.com/vxa-020/ZenUI"
local RAW_ROOT = "https://raw.githubusercontent.com/vxa-020/ZenUI"
local OFFICIAL_AUTHOR = "PaveF"
local OFFICIAL_VERSION = "3.0.0"

-- Pinned to the content commit that contains all four files (see git log).
local CONTENT_COMMIT = "d63fe3bbfdfb2f5195118906e036838dff3f02d9"

local CORE = RAW_ROOT .. "/" .. CONTENT_COMMIT .. "/ZenUI.Core.luau"
local SKIN = RAW_ROOT .. "/" .. CONTENT_COMMIT .. "/ZenUI.ApexVisuals.luau"
local EXT = RAW_ROOT .. "/" .. CONTENT_COMMIT .. "/ZenUI.Extensions.luau"
local MANIFEST = RAW_ROOT .. "/main/OFFICIAL_BUILD.json"

local function loadRemote(url, name, apply)
	local src = game:HttpGet(url)
	local chunk, err = (loadstring or load)(src, "=" .. name)
	assert(chunk, err)
	local result = chunk()
	if apply and type(result) == "function" then
		result = result(apply)
	end
	return result
end

local Library = loadRemote(CORE, "ZenUI.Core")

Library.Metadata = {
	Name = "ZenUI",
	Author = OFFICIAL_AUTHOR,
	Version = OFFICIAL_VERSION,
	Build = BUILD_ID,
	Repository = SOURCE_ROOT,
	License = "ZenUI Source-Available License v1.0",
	Official = true,
	SourceFile = "ZenUI.luau",
	ProvenanceId = PROVENANCE_ID,
	ManifestURL = MANIFEST,
	Provenance = {
		EntryPoint = "ZenUI.luau",
		ContentCommit = CONTENT_COMMIT,
		Notice = "NOTICE.md",
		LicenseFile = "LICENSE",
		AuthenticityModel = "provenance",
	},
}

function Library:GetBuildInfo() return table.clone(self.Metadata) end
function Library:GetOfficialRepository() return SOURCE_ROOT end
function Library:IsOfficialBuild()
	return self.Metadata
		and self.Metadata.Official == true
		and self.Metadata.Author == OFFICIAL_AUTHOR
		and self.Metadata.Repository == SOURCE_ROOT
		and self.Metadata.License == "ZenUI Source-Available License v1.0"
		and self.Metadata.ProvenanceId == PROVENANCE_ID
end
function Library:FetchOfficialManifest()
	local ok, raw = pcall(function() return game:HttpGet(MANIFEST) end)
	if not ok or type(raw) ~= "string" then return nil, "Unable to fetch official provenance manifest." end
	local decodedOk, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not decodedOk or type(data) ~= "table" then return nil, "Official provenance manifest is invalid." end
	return data
end
function Library:VerifyOfficialBuild(fetchRemote)
	local result = {
		status = "unknown",
		official = false,
		repository = self.Metadata.Repository,
		build = self.Metadata.Build,
		version = self.Metadata.Version,
		provenance_id = self.Metadata.ProvenanceId,
		content_commit = CONTENT_COMMIT,
		manifest_url = MANIFEST,
		reasons = {},
	}
	if self.Metadata.Repository ~= SOURCE_ROOT then
		result.status = "unofficial"
		table.insert(result.reasons, "Repository is not canonical.")
		return result
	end
	if self.Metadata.ProvenanceId ~= PROVENANCE_ID then
		result.status = "unverified"
		table.insert(result.reasons, "Provenance identifier is not the official ZenUI identifier.")
		return result
	end
	if fetchRemote == false then
		result.status = "claimed-official"
		return result
	end
	local manifest, err = self:FetchOfficialManifest()
	if not manifest then
		table.insert(result.reasons, err)
		return result
	end
	result.manifest = manifest
	local matches = manifest.project == self.Metadata.Name
		and manifest.author == self.Metadata.Author
		and manifest.repository == self.Metadata.Repository
		and manifest.license == self.Metadata.License
		and manifest.official_source_file == self.Metadata.SourceFile
		and manifest.official_version == self.Metadata.Version
		and manifest.build_id == self.Metadata.Build
		and manifest.provenance_id == PROVENANCE_ID
		and manifest.content_commit == CONTENT_COMMIT
	if matches then
		result.status = "official"
		result.official = true
		result.reasons = { "Local provenance matches the canonical published manifest." }
	else
		result.status = "modified-or-unofficial"
		result.reasons = {
			"Local provenance does not match the canonical published manifest.",
			"Treat this distribution as modified or unofficial until manually verified.",
		}
	end
	return result
end
function Library:GetAuthenticityStatus(fetchRemote)
	local result = self:VerifyOfficialBuild(fetchRemote)
	return result.status, result
end

-- Apex visual skin: applied as a module over the constructed Library.
local okSkin, skinErr = pcall(function()
	return loadRemote(SKIN, "ZenUI.ApexVisuals", Library)
end)
Library.ApexSkinLoaded = okSkin
Library.ApexSkinError = okSkin and nil or tostring(skinErr)

-- Apex extensions.
local ok, err = pcall(function()
	return loadRemote(EXT, "ZenUI.Extensions", Library)
end)
Library.Apex = {
	Version = OFFICIAL_VERSION,
	ExtensionURL = EXT,
	ExtensionCommit = CONTENT_COMMIT,
	ExtensionLoaded = ok,
	ExtensionError = ok and nil or tostring(err),
	Features = {
		"CleanGlass",
		"StableMotion",
		"CommandCenter",
		"StatusBar",
		"ContextMenu",
		"StatGrid",
		"Segmented",
		"Stepper",
		"Progress",
		"InfoCard",
		"ActionGroup",
		"QuickToggle",
		"AIManifest",
		"Provenance",
		"AuthenticityVerification",
	},
}
function Library:LoadApexExtensions(force)
	if self.Apex.ExtensionLoaded and not force then return true end
	local success, reason = pcall(function()
		return loadRemote(EXT, "ZenUI.Extensions", self)
	end)
	self.Apex.ExtensionLoaded = success
	self.Apex.ExtensionError = success and nil or tostring(reason)
	return success, reason
end

ENV.Library = Library
return Library