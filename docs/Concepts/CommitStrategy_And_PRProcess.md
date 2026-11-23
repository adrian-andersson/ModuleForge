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

### Type of Change

Each PR records every type of change it contains. The highest-impact one decides the version:

| Type of change | Version impact | Examples |
| --- | --- | --- |
| 🔴 **Breaking** | Major | Mandatory parameter added, parameter renamed or removed without an alias, changed defaults or output |
| 🟡 **Feature** | Minor | New function, new optional parameter, more output |
| 🟢 **Fix** | Patch | Bug fix, stream message change, performance improvement |
| ⚪ **Non-module change** | None | Documentation, CI/CD, tests |

When ModuleForge scaffolds a new project, it includes a PR template that asks for these as checkboxes, with a short description beside each, so there's nothing to memorise. **Tick all that apply**: a PR with a feature and a bug fix ticks both. That keeps a record of what's in the PR, while the highest-impact tick guides the Release choice below. The template also has a two-item checklist, for commit prefixes and Pester tests.

See [Module Versioning with SemVer](./ModuleVersioning_With_SemVer.md) for a full breakdown of how version increments are applied.

### Release

The template also asks which Build and Release choice should follow the merge, in the form's own words:

- **Next Prerelease** - most pull requests: the change continues the current prerelease series, or starts a patch series after a stable release
- **New Prerelease Series: minor** or **major** - the first feature, or breaking change, since the last stable release
- **No build yet** - more pull requests to come before the next build
- **Promote to Stable** - the last pull request in the series, once its prerelease is tested

### How It Connects

The commit prefix convention and the PR template work together:

1. Commit prefixes feed `Get-MFGitChangeLog`, which generates the release notes automatically
2. The PR's types of change show what kind of release it is
3. The PR's Release choice is what to pick when you run Build and Release

This means a well-prefixed commit history produces accurate, zero-effort release notes on every tag.

## Triggering a Release

The build and release pipeline is triggered manually, via GitHub Actions (`workflow_dispatch`) or an Azure DevOps pipeline run. Its form has one key input, **Release**, with the same choices as the PR template:

| Release | Example |
| --- | --- |
| **Next Prerelease** *(default)* | `1.3.0-prev001 → 1.3.0-prev002`, or `1.3.0 → 1.3.1-prev001` |
| **New Prerelease Series: minor** | `1.2.3 → 1.3.0-prev001` |
| **New Prerelease Series: major** | `1.2.3 → 2.0.0-prev001` |
| **Promote to Stable** | `1.3.0-prev002 → 1.3.0` |

If the PR template was filled out, the right choice is already ticked on the pull request. There is no automated way to carry it forward, so check the merged pull request when you run it. The [Build and Release Guide](../build-and-release.md) covers every choice.

Before the build proceeds, the pipeline validates that the latest Pester test run passed and that its commit SHA matches the current branch. This acts as a safety gate - a build cannot be triggered against code that has not passed automated tests.

