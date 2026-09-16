# ZenUI Authenticity & Unofficial Build Policy

ZenUI is distributed through the canonical repository:

`https://github.com/PaveF/ZenUI`

## Official

An official build is a release published through the canonical repository and identified by the repository's `OFFICIAL_BUILD.json` provenance metadata.

## Modified / Unofficial

A build is unofficial when its source, behavior, branding, loader, or distribution has been modified outside an official ZenUI release.

Modified copies must not be represented as official ZenUI or as endorsed/maintained by PaveF.

## How users can verify a build

1. Check that the loader points to the canonical `PaveF/ZenUI` repository.
2. Inspect `Library:GetBuildInfo()` and `Library:GetAuthenticityStatus()`.
3. Compare the reported build ID, source blob, core commit, and extension provenance with `OFFICIAL_BUILD.json` in this repository.
4. Prefer commit-pinned raw URLs when reproducibility matters.

## Important limitation

The library runs on the client and cannot provide an unforgeable cryptographic proof that a locally modified copy is authentic. The verification API is a provenance and consistency signal, not a security boundary.

If a suspicious distribution claims to be official ZenUI, preserve its URL, repository, source, screenshots, and publication date before reporting it.
