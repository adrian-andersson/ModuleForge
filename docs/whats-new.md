---
layout: default
title: What's New
nav_order: 9
---

# What's New

The headline features of each ModuleForge release. Every release, including prereleases, has full, automatically generated release notes on the **[GitHub releases page](https://github.com/adrian-andersson/ModuleForge/releases)**, built from its commit messages.

---

## 1.4.1 (November 2026)

A release about the everyday experience of the workflows, and fixes.

**One Release choice in Build and Release**
- `version_type` and `release_type` are replaced by one **Release** choice that follows how a release goes: start a **New Prerelease Series** (minor or major) once, run **Next Prerelease** until it's ready, then **Promote to Stable**. Most runs are Next Prerelease, the default. See [Making the Most of Releases](./tutorials/releases.md).
- Releasing stable without a prerelease series is commented out in the workflow, so it's always a deliberate choice. Promoting a version that's already stable stops and says why.
- A **dry run** option works out the version and builds, without tagging, releasing or publishing.
- Every run starts its summary with a **release plan**: the latest version, your choice, and the version it builds. See the [Build and Release Guide](./build-and-release.md).

**A shorter pull request template**
- Notes for reviewers, a two-item checklist, every type of change the pull request includes, and the Release choice to follow the merge, in the Build and Release form's own words. Each box says what it means beside it, so there's nothing to look up.
- The previous, detailed template is still scaffolded, as `.example`, for projects that prefer it.

**More Project Rules**
- **ArrayAddition** flags `+=` on arrays, which copies the whole array each time, and recommends a generic list.
- **NestedFunctions** flags functions defined inside other functions, which can't be tested or reused.
- **`New-MFProject -ProjectRules`** adds every rule set as it creates the project, so `New-MFProject -Scaffold GitHub,AzureDevOps -ProjectRules` sets up everything in one command. See [Project Rules](./Concepts/ProjectRules.md).

**Fixes**
- **`Get-MFNextSemver`** uses the incremented version for a stable release: from `1.2.3-prev002`, minor and stable now gives `1.3.0`, not `1.2.3`. Prerelease labels containing a `v`, such as `devv003`, keep their counter.
- **`Get-MFDependencyTree`** shows each file's dependencies once, and marks circular references, rather than repeating itself or never finishing.
- **`Add-MFGithubScaffold`** and **`Add-MFAzureDevOpsScaffold`** show their help again.
- **`Get-MFGitPrefixHelp`** uses the new Release choices and types of change, and `New-MFProject`'s welcome message points to it.

### Upgrading from 1.4

- **The new Build and Release form and pull request template only reach your project when you update your workflows.** [Updating Your Workflows and Templates](./tutorials/updating-scaffold.md) shows how to do it without losing your own changes.
- To add the new rule sets to a project that already uses Project Rules, run `Add-MFProjectRules -RuleSet ArrayAddition,NestedFunctions`.

---

## 1.4 (November 2026)

**Pinned, predictable builds**
- **`BuildDependencies.psd1`** pins the modules your pipelines install: ModuleForge, Pester, PSScriptAnalyzer and PlatyPS. Each pipeline installs and imports exactly the pinned version. See [Build Dependencies](./Concepts/BuildDependencies.md).
- **`testDependencies`** decides what the Pester pipelines install. Tests never install ModuleForge.
- Build and Release, and PSGallery Release, can install the pinned ModuleForge, or the latest from PSGallery, with `dependency_source`.

**Checking what you ship**
- **Build Test**, an optional workflow or pipeline, installs the module you just published and checks it exports exactly what your source declares. See [Testing the Published Module](./tutorials/build-test.md).
- **Project Rules** runs your own PSScriptAnalyzer rules as an advisory pass with its own pull request comment. **`Add-MFProjectRules`** adds ready-made rule sets: Constrained Language Mode compatibility, and help examples, with more in 1.4.1. See [Project Rules](./Concepts/ProjectRules.md).
- **`Get-MFBuildSummary`** reports a build's version, exports, size and SHA256 hashes, and Build and Release shows it on the run.

**Easier setup**
- **`New-MFProject -Scaffold GitHub,AzureDevOps`** adds the CI scaffold in the same step.
- **`New-MFProject`** fills in `LicenseUri` from your `LICENSE` file for GitHub and Azure DevOps projects.
- **`Get-MFGitPrefixHelp`** lists the commit prefixes from the command line.
- Azure DevOps pipelines work with **project- or organization-scoped feeds**, and warn rather than fail when a project can't publish code coverage.

**Under the hood**
- Manifests list exported **aliases by name**, never `*`. Aliases from `[Alias()]`, and from `Set-Alias` or `New-Alias` with a literal name, are included.
- **Hardened pipelines.** Pull request code runs without a write token, comments are posted by jobs that never run it, and tokens stay off disk. See [CI Security Model](./Concepts/CISecurityModel.md).
- Docs are generated with **Microsoft.PowerShell.PlatyPS 1.0**, replacing the unmaintained platyPS 0.14.
- **Minimum PowerShell 7.6 LTS and Pester 6.**

### Upgrading from 1.3

- **PowerShell 7.6 and Pester 6** are now required, for ModuleForge itself and for the pipelines.
- **Get the new templates** by running `Add-MFGithubScaffold` or `Add-MFAzureDevOpsScaffold` again. Without `-Force` it only adds files you don't have, such as `BuildDependencies.psd1`, the new scripts and the `.example` templates. **With `-Force` it overwrites your workflows, and resets `BuildDependencies.psd1` to its default pins.** See [the upgrade FAQ](./faq.md).
- **Aliases are now exported by name.** An alias whose name is a variable, such as `Set-Alias -Name $name ...`, can't be listed, and the build warns that it won't be exported. Use a literal name, or `[Alias()]` on the function.
- **PSGallery Release's input changed** from `moduleforge_release_toggle` to `dependency_source`. See [the PSGallery tutorial](./tutorials/github/psGallery-Release-Workflow.md).

---

## 1.3 (June 2026)

- **Build provenance.** Built modules record the ModuleForge version and hashes that produced them, in the `.psm1` header and manifest.
- **Private functions are linted and covered.** PSScriptAnalyzer and code coverage include `source/private`, and a root `tests` folder is supported.
- **`Invoke-MFPester.ps1`** runs Pester locally the same way the pull request pipeline does.
- **`Invoke-MFBuildPreRelease`** builds a prerelease locally.
- **`Resolve-MFModuleCase`** fixes the lowercase install folders NuGet feeds can cause on Linux and macOS.
- **`Write-MFModuleDocs`** generates a [Just the Docs](https://just-the-docs.com/) site, with navigation, from your help.

---

## 1.2 (July 2025)

- **Azure DevOps support**, with `Add-MFAzureDevOpsScaffold`, alongside **`Add-MFGithubScaffold`**.
- **Changelogs from commit messages**, with `Get-MFGitChangeLog`, added to each release and its manifest.
- **Versions from git tags**, with `Get-MFGitLatestVersion` and `Get-MFNextSemver`.
- **`Write-MFModuleDocs`** for function reference docs and a changelog on GitHub Pages.
