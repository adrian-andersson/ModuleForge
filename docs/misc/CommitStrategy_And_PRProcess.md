---
layout: default
title: Commit Strategy and PR Process
parent: Misc
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

The specific branching model you adopt — GitFlow, GitHub Flow, trunk-based, or your own — is up to you and your team. Some useful references:

- [A Successful Git Branching Model (GitFlow)](https://nvie.com/posts/a-successful-git-branching-model/) — Vincent Driessen's original GitFlow post
- [GitHub Flow](https://docs.github.com/en/get-started/using-github/github-flow) — GitHub's lightweight, branch-per-feature approach
- [Comparing Workflows](https://www.atlassian.com/git/tutorials/comparing-workflows) — Atlassian's overview of common strategies and their trade-offs

### Type of Change

Each PR should be categorised by the highest-impact change it contains. This maps directly to the semantic version increment:

| Category | Version Impact | Examples |
| --- | --- | --- |
| 🔴 **Major** | Breaking — bump major | Mandatory parameter added, output type changed, parameter renamed without alias |
| 🟡 **Minor** | Feature — bump minor | New function, new optional parameter, non-breaking output change |
| 🟢 **Patch** | Fix — bump patch | Bug fix, stream output change, test or performance update |
| ⚪ **Non-release** | No version bump | Documentation, CI/CD, internal tooling |

> **Note the change type you select here — you will need it when triggering the build and release pipeline.** There is no automated way to carry this forward, so take note before closing the PR. See [Triggering a Release](#triggering-a-release) for details.

When ModuleForge scaffolds a new project, it includes a PR template that surfaces these categories as a checklist directly in the pull request form. Contributors are guided through the classification at PR time — no need to memorise the categories. The template also includes a quick review checklist covering Pester test coverage, PSScriptAnalyzer compliance, commit prefix usage, and release intent, keeping the full process visible at the point of review. When filling out the template, use the highest-impact ticked section as your guide for the overall type of change.

See [SemVer Interpretation](./SemVer_Interpretation.md) for a full breakdown of how version increments are applied.

### Release Intent

PRs are also tagged with their release intent:

- **PreRelease series** — the change is part of an ongoing set of changes building toward a stable release
- **Stable release** — this PR finalises a version for stable release
- **No release** — the change does not trigger a release (documentation, CI changes, etc.)

### How It Connects

The commit prefix convention and PR change type work together:

1. Commit prefixes feed `Get-MFGitChangeLog`, which generates the release notes automatically
2. The PR change type informs the version bump applied by the build pipeline
3. The release intent controls whether the build tags a prerelease or a stable version

This means a well-prefixed commit history produces accurate, zero-effort release notes on every tag.

## Triggering a Release

The build and release pipeline is triggered manually via GitHub Actions (`workflow_dispatch`). When triggered, a form is presented with two key inputs:

| Input | Options | Maps To |
| --- | --- | --- |
| **Version increment type** | `major`, `minor`, `patch`, `none` | The PR type of change category |
| **Release type** | `stable`, `prerelease` | The PR release intent |

These inputs directly reflect the decisions already made during the PR process — if the PR template was filled out correctly, the right values to enter here should already be known.

> **`none` for version type** does not skip versioning — it increments the prerelease counter without changing the major.minor.patch version. This is the default and is safe for iterative prerelease builds.

Before the build proceeds, the pipeline validates that the latest Pester test run passed and that its commit SHA matches the current branch. This acts as a safety gate — a build cannot be triggered against code that has not passed automated tests.

