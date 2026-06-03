---
layout: default
title: FAQ and Troubleshooting
nav_order: 8
---

# FAQ and Troubleshooting

---

## Versioning

### I need to manually set or increase a version

Add a git tag directly and push it. ModuleForge reads the latest tag to determine the next version, so the tag must be in the exact format `Get-MFGitLatestVersion` and `Get-MFNextSemver` expect:

```text
v{MAJOR}.{MINOR}.{PATCH}              ← stable
v{MAJOR}.{MINOR}.{PATCH}-{label}v{NNN} ← prerelease
```

Examples:

```powershell
# Stable
git tag v1.3.0
git push origin v1.3.0

# Prerelease
git tag v1.3.0-prev001
git push origin v1.3.0-prev001
```

Common reasons to do this: forked repositories without an existing tag history, hotfix branches where the normal workflow can't run, or recovering from a failed/missed release.

> Make sure the tag is on the correct commit before pushing. Once pushed to a public repository, deleting and re-creating tags is disruptive to anyone who has already fetched them.

See [Module Versioning with SemVer](./Concepts/ModuleVersioning_With_SemVer.md) for the full version format rules and the zero-padded counter requirement.

---

### My prereleases are sorting or resolving incorrectly

This is almost always a case-sensitivity issue. There is a known bug in PSResourceGet where **uppercase characters in prerelease labels** cause incorrect ordering and resolution behaviour on some feeds, including Azure DevOps Artifacts.

ModuleForge defaults to the lowercase label `prev` (producing `1.2.3-prev001`) specifically to avoid this. If you have customised the prerelease label, ensure it is entirely lowercase. See [I want to use a custom prerelease label](#i-want-to-use-a-custom-prerelease-label) below.

---

### I want to use a custom prerelease label

The prerelease label is passed to `Get-MFNextSemver` via the `-PrereleaseLabel` parameter. In the Build and Release workflow, find the `Get-MFNextSemver` call and add the parameter:

```powershell
Get-MFNextSemver -PrereleaseLabel 'beta' ...
```

Keep the label **lowercase** — the PSResourceGet bug with uppercase labels will cause silent failures on some feeds.

---

### The changelog is not generating correctly or is missing commits

Commits must follow the exact format `prefix: description` — the colon must immediately follow the prefix with no space before it.

```text
feat: add new function       ← recognised
feat : add new function      ← NOT recognised (space before colon)
Added new function           ← NOT recognised (no prefix)
```

`chore:` and `test:` are excluded from the default changelog. Pass a custom `-ChangeLogTypes` hashtable to `Get-MFGitChangeLog` if you need them included. See [Commit Prefixes](./commit-prefixes.md) for the full prefix reference.

---

## CI/CD and Runners

### My module is Windows-only and won't build on Ubuntu

The module does not need to *load* on Linux — the build step is a file compilation and manifest generation process that is platform-neutral. Most Windows-only modules build successfully on `ubuntu-latest` even if they cannot be imported there.

**If your tests use Windows-specific cmdlets**, wrap them with a Pester condition:

```powershell
It 'Does something Windows-specific' -Skip:($IsLinux -or $IsMacOS) {
    # test body
}
```

This lets the CI run on Linux while skipping tests that require Windows APIs, which keeps coverage reporting accurate and avoids false failures.

**If the build itself requires Windows** (rare — usually only if source files contain Windows-only syntax that PowerShell 7 on Linux rejects during parsing), update `runs-on` in all three workflow files:

```yaml
runs-on: windows-latest
```

The files to update are `pesterTest.yml`, `buildandrelease.yml`, and `scriptAnalyzerLintReport.yml` in your `.github/workflows/` folder.

For guidance on writing cross-platform PowerShell, see the [PowerShell cross-platform considerations](https://learn.microsoft.com/en-us/powershell/scripting/dev-cross-plat/writing-portable-modules) documentation.

---

### The Build and Release workflow is blocked — Pester tests failed or SHA mismatch

The workflow validates that:
1. The most recent Pester workflow run has a `success` conclusion
2. The commit SHA of that run matches the current HEAD (or the HEAD of the last PR merge)

If the workflow throws `❌ No match on PR or primary commit`, the most common causes are:

- The Pester workflow has not run yet since the last commit — wait for it to complete
- The last Pester run was against a different branch — trigger a Pester run against `main` first
- A merge commit shifted HEAD — this is handled automatically; if it still fails, re-run Pester manually via the Actions tab

---

### I want to add extra steps to the CI pipeline

Edit the relevant workflow YAML in `.github/workflows/` directly. The scaffolded files are a starting point — they are yours to modify. Add steps before or after the existing ones as needed.

If your addition would benefit other ModuleForge users, consider [contributing it](https://github.com/adrian-andersson/ModuleForge/blob/main/CONTRIBUTING.md).

---

### I want to use GitLab, Bitbucket, or another CI platform

Only GitHub Actions and Azure DevOps are currently supported. If you need another platform, that is a great candidate for a contribution — open an issue to discuss the approach before starting work.

---

## Local Development

### I need to build the module locally

Use `Invoke-MFBuildPreRelease` from your project root. It reads the latest version from the local build manifest, increments the prerelease counter, and calls `Build-MFProject` for you:

```powershell
Invoke-MFBuildPreRelease
```

**If this is your first build** (no prior build manifest exists), there is no version to increment from. In that case, call `Build-MFProject` directly with an explicit version:

```powershell
Build-MFProject -Version '0.0.1-prev001'
```

After that first build, `Invoke-MFBuildPreRelease` will work as expected for all subsequent local builds.

See [`Invoke-MFBuildPreRelease`](./functions/Invoke-MFBuildPreRelease.md) and [`Build-MFProject`](./functions/Build-MFProject.md) for full parameter references.

---

## Integration with Other Tools

### I want to use PSake, Invoke-Build, Plaster, Artifactory, or my own toolchain

There is no conflict. ModuleForge is designed to be composable — use it as a dependency within your existing build toolchain and call its functions directly:

| Task | ModuleForge function |
| --- | --- |
| Run Pester with coverage | `Invoke-MFPester` |
| Compile the module | `Build-MFProject` |
| Register a local or private NuGet feed | `Register-MFLocalPsResourceRepository` |
| Add NuGet v3 feed data to the config | `Add-MFRepositoryXmlData` |

For a private Artifactory or self-hosted NuGet feed: register it as a PSResource repository with `Register-PSResourceRepository` (or `Register-MFLocalPsResourceRepository` for convenience), then use `Publish-PSResource` to push to it. Use `Add-MFRepositoryXmlData` if your feed needs NuGet v3 metadata to be embedded in the manifest.

If you build a solid integration pattern, consider contributing it as an example or a pull request.

---

## Publishing and PSResourceGet

### PSResourceGet cannot find my module

PSResourceGet uses the NuGet v3 protocol, which **does not support wildcard searches**. You must specify the exact module name:

```powershell
Find-PSResource -Name 'ExactModuleName' -Repository 'MyRepo'
```

`Find-PSResource -Name '*'` or partial name patterns will not work against NuGet v3 feeds. This is a protocol limitation, not a ModuleForge issue.

---

### I installed a module but PowerShell cannot find or load it on Linux or macOS

This is probably a case mismatch between the module's name and the folder it was installed into. NuGet is case-insensitive, so a module named `MyModule` can end up installed into a folder called `mymodule`, which PowerShell on Linux (where the filesystem is case-sensitive) cannot match when resolving `Import-Module MyModule` or `Get-Module -ListAvailable`.

Run `Resolve-MFModuleCase` from your project root after installing:

```powershell
Resolve-MFModuleCase -ModuleName 'MyModule'
```

This detects the mismatch and renames the installed folder to match the manifest name exactly. The PSGallery publish workflow calls this automatically before publishing; for local installs you may need to call it manually.

See [`Resolve-MFModuleCase`](./functions/Resolve-MFModuleCase.md) for full details. The underlying PSResourceGet issue is tracked at [PSResourceGet #305](https://github.com/PowerShell/PSResourceGet/issues/305).

---

### I cannot update a prerelease using Install-PSResource — it skips the install

This is a known constraint of how PSResourceGet handles prerelease versioning. Prerelease versions share the same installation folder as their base version — `1.0.0-prev001` and `1.0.0-prev002` both install into a folder named `1.0.0`. When you attempt to install a newer prerelease of the same base version, PSResourceGet sees that folder already exists and skips the install entirely.

The fix is to unload the module from the current session first, then reinstall using the `-Reinstall` switch:

```powershell
Remove-Module <ModuleName> -Force -ErrorAction SilentlyContinue
Install-PSResource -Name <ModuleName> -Prerelease -Reinstall
```

The `Remove-Module` step is important — omitting it can make the install appear to succeed while the session continues running the old version from memory.

If you cannot use `-Reinstall` (older PSResourceGet versions), manually deleting the `1.0.0` folder from the module install path and reinstalling achieves the same result.

This is a consequence of the NuGet versioning model, not a PSResourceGet bug — prerelease qualifiers are part of the version identifier but are not reflected in the on-disk folder name.

---

### PSGallery already has that version — I published the wrong thing

PSGallery does not allow version deletion. You can **unlist** a version (it stops appearing in search results but remains installable by explicit version), but you cannot remove it entirely. Contact the [PowerShell Gallery support](https://www.powershellgallery.com/policies/Contact) if you need to take further action.

This is why the PSGallery workflow checks for a duplicate version before publishing. Verify your intended version carefully before triggering that workflow.

---

## Configuration

### I need to change my moduleForgeConfig settings

Use `Update-MFProject` to update any parameter that was originally set with `New-MFProject`:

```powershell
# Update the description and add a tag
Update-MFProject -Description 'Updated description' -ModuleTags 'powershell', 'automation'

# Update required module dependencies
Update-MFProject -RequiredModules @('Pester', 'PSScriptAnalyzer')
```

Any parameter you don't pass is left unchanged. If you need to make a change that `Update-MFProject` doesn't cover, you can edit `moduleForgeConfig.xml` directly — it is a standard PowerShell CLIXML file.

See [`Update-MFProject`](./functions/Update-MFProject.md) for the full parameter list.

---

### I want to add something to the runner environment in the scaffolded workflows

Edit the workflow YAML files in `.github/workflows/` directly and add whatever steps or environment setup you need. The scaffolded files are a starting point, not a locked-down configuration.

If your addition is generic enough to be useful to other ModuleForge users, consider [raising an issue](https://github.com/adrian-andersson/ModuleForge/issues) or opening a pull request.

---

## Getting Help

### I hit a bug, have an issue, or want to request a feature

[Open an issue on GitHub](https://github.com/adrian-andersson/ModuleForge/issues). Include the ModuleForge version (`(Get-Module ModuleForge).Version`), the PowerShell version (`$PSVersionTable`), and enough context to reproduce the problem.
