---
layout: default
title: ModuleForge vs Alternatives
parent: Concepts
nav_order: 1
---
# ModuleForge vs Alternatives

ModuleForge is opinionated by design. That is its strength in many situations, and a real limitation in others. This page is honest about both.

---

## The Problem It Solves

Setting up a PowerShell module with a consistent structure, meaningful versioning, automated tests, and a working CI/CD pipeline involves a lot of decisions and a lot of plumbing:

- Where do functions, classes, and private helpers live?
- How does the compiled `.psm1` get generated?
- What constitutes a breaking change, and what increments which version component?
- How do PRs surface test results without manual intervention?
- What format does PSGallery actually accept for prerelease version strings?

Most teams answer these questions inconsistently across projects, or copy-paste pipelines from a previous repo and hope they still work. ModuleForge makes those decisions once and encodes them into a scaffold that just works from day one.

---

## How It Compares to Adjacent Tools

### Plaster

Plaster is a scaffolding template engine for PowerShell. It creates a project structure from a manifest file. That is where it stops.

ModuleForge replaces Plaster's scaffolding function and adds module compilation, semantic versioning, changelog automation, and CI/CD pipelines. If you are already using Plaster templates, ModuleForge offers a higher level of abstraction at the cost of less flexibility in the scaffold shape.

### PSake / Invoke-Build

These are task runners. You define tasks (test, build, publish) and wire them together. They are extremely flexible — and require you to write everything yourself.

ModuleForge and PSake/Invoke-Build are not mutually exclusive. You can call ModuleForge functions (`Invoke-MFPester`, `Build-MFProject`, `Resolve-MFModuleCase`) from within a PSake task file or Invoke-Build script, using ModuleForge as a library rather than as the orchestrator. This is a natural pattern if you already have an established build toolchain.

### Sampler

Sampler is a more comprehensive module build framework, popular in the larger PowerShell community (and used in projects like DSC Community modules). It offers deep configurability, multiple resolvers, and a rich ecosystem of build tasks.

ModuleForge trades that configurability for simplicity. Where Sampler asks you to configure it, ModuleForge makes the decision for you. If you need the flexibility Sampler provides — multiple source paths, complex dependency resolution, pluggable task pipelines — Sampler is the better choice. If you want something running in minutes with no configuration, ModuleForge is.

### Manual (copy-paste from a previous project)

The status quo for many teams. It works until it doesn't — workflow drift between projects, version format inconsistencies, changelogs that require manual maintenance, pipelines that only work on one person's machine.

---

## What ModuleForge Gives You

| Capability | Detail |
| --- | --- |
| **One-command scaffold** | `New-MFProject` + `Add-MFGithubScaffold` or `Add-MFAzureDevOpsScaffold` |
| **Module compilation** | Source folder → single `.psm1` with correct export list |
| **SemVer with PSGallery V1 compatibility** | Zero-padded counters, lowercase prerelease labels, correct ordering |
| **Automated changelog** | Commit prefixes feed `Get-MFGitChangeLog` — no manual release notes |
| **CI/CD with hard-fail tests** | Pester blocks the build; PSScriptAnalyzer and coverage are advisory |
| **Dual CI platform** | GitHub Actions and Azure DevOps with feature parity |
| **Prerelease workflow** | Build → validate in feed → promote to stable, all via workflow triggers |
| **PSGallery publish** | One workflow, version duplicate guard, case resolution included |

---

## What ModuleForge Does Not Do

**It is opinionated about structure.** Functions live in `source/functions/`, private helpers in `source/private/`, and so on. If you have an existing project with a different layout, ModuleForge's build step won't adapt to it — you would need to reorganise.

**It targets GitHub and Azure DevOps.** GitLab, Bitbucket, Bamboo, and TeamCity are not currently supported. Contributions are welcome.

**It does not compile binaries.** C# projects, binary modules, or anything requiring `dotnet build` or `msbuild` are outside scope.

**It won't suit deeply customised pipelines.** If your CI/CD has ten stages, matrix builds across three operating systems, and custom deployment gates, the scaffolded workflows will feel too simple to build on. They are a starting point, not an enterprise pipeline framework.

**It makes the test scope decision for you.** Pester runs against exported functions only. Private functions are implicitly tested through their callers. If you need true unit tests at the private function level, you can write them — but `Invoke-MFPester` won't pick them up automatically.

---

## The "Fixed Defaults Are a Feature" Philosophy

ModuleForge's opinionated defaults exist because the alternative — asking you to configure everything — is where most build toolchains lose people. The questions above (where do classes go? what is the prerelease format? what increments major vs minor?) all have defensible answers that most PowerShell projects can live with. ModuleForge just answers them for you.

If you hit a case where the defaults don't fit, you have two options:
1. Edit the scaffolded files directly — they are yours
2. Raise an issue or open a PR if you think the default should change for everyone

The goal is not a tool that fits every situation perfectly. It is a tool that fits most situations immediately, with minimal friction.
