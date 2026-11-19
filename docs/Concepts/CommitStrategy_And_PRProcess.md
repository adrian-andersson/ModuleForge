---
layout: default
title: Commit Strategy and PR Process
parent: Concepts
nav_order: 2
---
# Commit Strategy and PR Process

This page describes the commit message conventions and pull request process used by ModuleForge, and how the two work together to drive automated changelog generation and semantic versioning.

## Commit Prefixes

Commit messages follow a prefix convention that categorises each change. The prefix is parsed by `Get-MFGitChangeLog` to automatically generate release notes.

| Prefix | Changelog Section | Notes |
| --- | --- | --- |
| `feat:` | New Features | A new function or capability |
| `fix:` | Bug Fixes | A bug fix |
| `docs:` | Documentation Changes | Documentation only changes |
| `refactor:` | Code Rewrite/Refactor | Code change that neither fixes a bug nor adds a feature |
| `perf:` | Performance Improvements | A code change that improves performance |
| `chore:` | *(not in default changelog)* | Pipeline, tooling, or housekeeping work |
| `test:` | *(not in default changelog)* | Adding or updating tests only |

`chore` and `test` are intentionally excluded from the default changelog output. They can be included by passing a custom `ChangeLogTypes` hashtable to `Get-MFGitChangeLog` if needed. This will require editing the BuildAndRelease YAML file.

### Format

```
<prefix>: <short description>
```

Example:

```
feat: add CLM compatibility check to build output
```

## PR Process

### Branch Strategy

A branch should be created for each change. This ensures the automation tests trigger appropriately and changes can be reviewed in isolation before merging.

The specific branching model you adopt - GitFlow, GitHub Flow, trunk-based, or your own - is up to you and your team. Some useful references:

- [A Successful Git Branching Model (GitFlow)](https://nvie.com/posts/a-successful-git-branching-model/) - Vincent Driessen's original GitFlow post
- [GitHub Flow](https://docs.github.com/en/get-started/using-github/github-flow) - GitHub's lightweight, branch-per-feature approach
- [Comparing Workflows](https://www.atlassian.com/git/tutorials/comparing-workflows) - Atlassian's overview of common strategies and their trade-offs

### The pull request template

When ModuleForge scaffolds a new project, it adds a short pull request template. It asks three things, so a pull request records what it is and what should happen when it merges:

1. **What and why** - a summary, and the issue or work item it relates to.
2. **Type of change** - the highest-impact change it contains.
3. **Release** - which Build and Release choice should follow the merge.

It ends with a two-item checklist: commits use [changelog prefixes](../commit-prefixes.md), and new or changed behaviour has Pester tests. Coverage and PSScriptAnalyzer aren't on it, as the Pester and lint workflows check those on every pull request.

### Type of Change

Each PR is labelled with the highest-impact change it contains:

| Type | Examples | Usually means |
| --- | --- | --- |
| 🔴 **Breaking** | Output changed in a way callers rely on, a mandatory parameter added, a parameter renamed or removed without an alias, validation tightened | **New Prerelease Series: major** |
| 🟡 **Feature** | A new function, a new optional parameter, a parameter renamed with an alias kept, output added to | **New Prerelease Series: minor** |
| 🟢 **Fix or maintenance** | Bug fixes, refactors, performance, verbose and error output | **Next Prerelease** |
| ⚪ **No change to the module** | Documentation, CI, tooling | **Next Prerelease**, or no build |

The type stays on the pull request as part of its history, and your commit prefixes should agree with it: `feat:` for a feature, `fix:` for a fix.

See [Module Versioning with SemVer](./ModuleVersioning_With_SemVer.md) for a full breakdown of how version increments are applied.

### Release

The Release section uses the same wording as the Build and Release form, so whoever runs the build can pick the matching choice:

- **Next Prerelease** - most pull requests: fixes, docs, CI, or more work on the current series
- **New Prerelease Series: minor** or **major** - only the *first* feature or breaking change since the last stable release. Later ones in the same series are Next Prerelease
- **No build yet** - more pull requests to come before the next build
- **Last pull request in this series** - a separate tick: once its prerelease is tested, run **Promote to Stable**

### Prefer the detailed template?

Projects scaffolded before ModuleForge 1.4.1 had a longer template, with a checkbox for each kind of change. It's still scaffolded, as `PULL_REQUEST_TEMPLATE.md.example` in `.github` (`pull_request_template.md.example` in `.azuredevops`). To use it, replace the template with it, renamed without `.example`.

### How It Connects

The commit prefix convention and the pull request template work together:

1. Commit prefixes feed `Get-MFGitChangeLog`, which generates the release notes automatically
2. The type of change and release choice on the pull request say which Build and Release choice to run

This means a well-prefixed commit history produces accurate, zero-effort release notes on every tag.

## Triggering a Release

The build and release pipeline is triggered manually via GitHub Actions (`workflow_dispatch`), or by running the pipeline in Azure DevOps. The form asks one key question, **Release**, and its choices are the ones in the pull request template:

| Choice | When |
| --- | --- |
| **Next Prerelease** | Most runs. Continues the current series (`1.3.0-prev001 → 1.3.0-prev002`), or after a stable release starts a patch series (`1.3.0 → 1.3.1-prev001`) |
| **New Prerelease Series: minor** / **major** | The first feature or breaking change since the last stable release |
| **Promote to Stable** | After the last pull request in the series, once its prerelease is tested |

If you merged several pull requests since the last build, use the highest-impact choice among them. See the [Build and Release Guide](../build-and-release.md) for every choice.

Before the build proceeds, the pipeline validates that the latest Pester test run passed and that its commit SHA matches the current branch. This acts as a safety gate - a build cannot be triggered against code that has not passed automated tests.

