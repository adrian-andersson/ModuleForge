---
layout: default
title: Release Integrity and Checksums
parent: Concepts
nav_order: 9
---

# Release Integrity and Checksums

Every module built with the ModuleForge Github Actions workflows (Including ModuleForge itslef) publishes SHA256 checksums for the two files that make up the installed module; the manifest (`.psd1`) and the module script (`.psm1`). These checksums appear in the GitHub release notes alongside the `.nupkg` artifact for each Build and Release.

---

## What Is Published

At the end of each release workflow, before the package is pushed to GitHub Packages, the workflow computes SHA256 hashes of the built `.psd1` and `.psm1` files and appends them to the release notes:

```
### 🔐 SHA256 Checksums
ModuleName.psd1: a3f1...
ModuleName.psm1: 7c82...
```

The hashes are computed from the same files that were packed into the `.nupkg`.

---

## Why It Matters

When a user installs the module from GitHub Packages or PSGallery, the files on their machine should be identical to the files that were built and hashed at release time. Publishing the hashes in the release notes creates a verifiable chain:

```
Source commit
  → Build-MFProject produces .psm1 and .psd1
  → SHA256 hashes computed and published to release notes
  → Files packed into .nupkg and pushed to feed
  → User installs from feed
  → User can verify installed files match release hashes
```

This provides non-repudiation - if the hash of an installed file matches the hash in the release notes, the file is provably the one that was built from that release. If it does not match, something changed between the release and the install, or more likely, after the install from the feed.

---

## Verifying an Installed Module

To check an installed module against a release, find the module folder and compute the hashes locally:

```powershell
$modulePath = (Get-Module -Name 'ModuleName' -ListAvailable | Select-Object -First 1).ModuleBase
Get-FileHash -Path (Join-Path $modulePath 'ModuleName.psd1') -Algorithm SHA256
Get-FileHash -Path (Join-Path $modulePath 'ModuleName.psm1') -Algorithm SHA256
```

Compare the output against the checksums in the corresponding GitHub release. A match confirms the installed files are unmodified from what was built and released.
