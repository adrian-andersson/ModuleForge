---
layout: default
title: Commit Prefixes
nav_order: 7
---

# Commit Prefixes

Commit messages in ModuleForge follow a prefix convention that drives two things automatically: changelog generation via `Get-MFGitChangeLog` and the choice of semantic version increment at release time.

A well-prefixed commit history produces accurate, zero-effort release notes on every tag - no manual changelog writing required.

> **Quick reference in your terminal:** run `Get-MFGitPrefixHelp` for the prefixes, an example of each, and the common gotchas. `Get-MFGitPrefixHelp -Section Gotchas` shows just the gotchas.

---

## Prefix Reference

| Prefix | Changelog Section | Default Changelog | Type of change |
| --- | --- | --- | --- |
| `feat:` | New Features | Yes | Feature |
| `fix:` | Bug Fixes | Yes | Fix |
| `docs:` | Documentation Changes | Yes | Non-module |
| `refactor:` | Code Rewrite/Refactor | Yes | Fix |
| `perf:` | Performance Improvements | Yes | Fix |
| `chore:` | *(excluded)* | No | Non-module |
| `test:` | *(excluded)* | No | Non-module |

`chore` and `test` are excluded from the default changelog output. This keeps release notes focused on user-facing changes. They can be included by passing a custom `ChangeLogTypes` hashtable to `Get-MFGitChangeLog` - see [Including chore and test](#including-chore-and-test) below.

The **Type of change** column matches the pull request template. Any other prefix, such as `ci:`, `feature:` or `bugfix:`, is dropped from the changelog without a warning, so use `chore:` for CI changes. `Get-MFGitPrefixHelp` shows this table, and the other gotchas, from the command line.

---

## Commit Format

```
<prefix>: <short description in imperative mood>
```

The description should complete the sentence "If applied, this commit will…". Keep it under 72 characters.

---

## Examples

### `feat:` - New function or capability

```
feat: add Get-MFDependencyTree to map function call chains
feat: add -IncludeChangeLog switch to Write-MFModuleDocs
```

Appears under **New Features** in the changelog. Signals a minor version bump.

---

### `fix:` - Bug fix

```
fix: resolve incorrect version bump when patch increment is selected
fix: handle empty commit history in Get-MFGitChangeLog
```

Appears under **Bug Fixes** in the changelog. Signals a patch version bump.

---

### `docs:` - Documentation only

```
docs: update tutorial to use PSResourceGet syntax
docs: add BeforeAll pattern to Pester testing guide
```

Appears under **Documentation Changes** in the changelog. No version bump - documentation changes do not trigger a release on their own.

---

### `refactor:` - Code change with no behaviour change

```
refactor: extract version parsing into private function
refactor: simplify dependency resolution logic
```

Appears under **Code Rewrite/Refactor** in the changelog. Signals a patch version bump.

---

### `perf:` - Performance improvement

```
perf: cache dependency tree results for large source folders
perf: reduce redundant git calls in Get-MFGitLatestVersion
```

Appears under **Performance Improvements** in the changelog. Signals a patch version bump.

---

### `chore:` - Pipeline, tooling, or housekeeping

```
chore: update GitHub Actions runner to ubuntu-24.04
chore: bump required PSScriptAnalyzer version to 1.24.0
```

Excluded from the default changelog. No version bump.

---

### `test:` - Adding or updating tests only

```
test: add coverage for empty parameter set in New-MFProject
test: fix BeforeAll dependency order for class-dependent functions
```

Excluded from the default changelog. No version bump.

---

## How Prefixes Connect to the Build Pipeline

Each prefix is a type of change, as in the pull request template, and the highest-impact type since the last stable release decides the Release choice in Build and Release:

- The first `feat:` commit since the last stable release → **New Prerelease Series: minor**
- The first breaking change since the last stable release → **New Prerelease Series: major** (add a `BREAKING CHANGE:` note in the commit body)
- Anything else, including `fix:`, `refactor:` and `perf:` commits, or a series that's already started → **Next Prerelease**
- `docs:`, `chore:` and `test:` commits don't change the module, so they don't need a release on their own

When the prerelease is tested, **Promote to Stable**. See [Making the Most of Releases](./tutorials/releases.md) for the full rhythm.

See [Commit Strategy and PR Process](./Concepts/CommitStrategy_And_PRProcess.md) for how this fits into the full PR workflow.

---

## Including chore and test

To include `chore` and `test` in the changelog, pass a custom `ChangeLogTypes` hashtable:

```powershell
Get-MFGitChangeLog -ChangeLogTypes @{
    'feat'     = 'New Features'
    'fix'      = 'Bug Fixes'
    'docs'     = 'Documentation Changes'
    'refactor' = 'Code Rewrite/Refactor'
    'perf'     = 'Performance Improvements'
    'chore'    = 'Chore and Pipeline Work'
    'test'     = 'Test Changes'
}
```

This overrides the default type map entirely, so include all prefixes you want in the output. To use this automatically in the pipeline, update the `Get-MFGitChangeLog` call in your `buildAndRelease.yml`.
