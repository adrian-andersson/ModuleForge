---
layout: default
title: Why ModuleForge Exists
nav_order: 2
---
# Why ModuleForge Exists

Building a PowerShell module is easy. Building one *well*, and keeping it that way across months of changes and a team of contributors, is not. ModuleForge exists to close that gap.

## The problem

Most PowerShell modules start the same way: a single `.psm1`, a handful of functions, and good intentions. Then they grow, and the same problems surface in almost every project:

- **Structure drifts.** Every module invents its own layout, so no two look alike and onboarding starts from zero each time.
- **Versioning is manual.** Someone remembers to bump the manifest, or they don't. Prerelease conventions are ad hoc.
- **Changelogs rot.** Release notes get written by hand, late, from memory, if at all.
- **CI is bespoke and fragile.** The build works on one person's machine and nobody is quite sure why it breaks on the runner.
- **Conventions are unwritten.** How you write a function, where tests live, what a commit message should say: all folklore, none of it enforced.

None of these is hard on its own. Collectively they are why a promising module becomes hard to maintain, and they are exactly the kind of problem tooling should solve once so you never solve it again. For a head-to-head with the specific tools in this space, see [ModuleForge vs Alternatives](./Concepts/ModuleForgeVsAlternatives.md).

## The idea

ModuleForge is an opinionated build and release tool for PowerShell modules. It makes the boring decisions for you, scaffolds a project that already has CI/CD, versioning, and documentation wired in, and then gets out of your way so you can write functions.

Three convictions shape it:

- **Opinionated beats configurable.** The questions every project must answer (where do classes go? what is the prerelease format? what counts as a breaking change?) all have defensible answers most projects can live with. ModuleForge answers them so you do not have to. You can still override; you rarely need to.
- **Pure PowerShell.** No external build runner, no DSL to learn. If you know PowerShell, you can read, modify, and trust every part of the pipeline. More on that choice in [From Bartender to ModuleForge](./Concepts/Origin.md).
- **It builds itself.** Every release of ModuleForge is built and published by the previous release. If the tool cannot build and ship itself, the build is broken before it ever reaches you. See [ModuleForge Builds Itself](./Concepts/SelfBuild.md).

## The principles in practice

Those convictions show up as concrete defaults:

- **Convention over configuration.** A fixed source layout (`functions`, `private`, `classes`, `enums`, and so on) compiled in a known order. Learn it once, recognise it everywhere. Start in [Getting Started](./getting-started.md).
- **Versioning with discipline.** SemVer with PSGallery-compatible prerelease handling, derived from your git tags rather than hand-edited. See [Module Versioning with SemVer](./Concepts/ModuleVersioning_With_SemVer.md).
- **Changelogs from your commits.** Well-prefixed commits generate release notes automatically, so the changelog is a by-product of working, not a chore.
- **Tests and docs as first-class.** Pester runs as a hard gate, coverage is advisory, and a documentation site regenerates from your help text. See [Writing Pester Tests](./Concepts/Pester.md).
- **Cross-platform by default.** The scaffolded pipelines run on Linux runners, and the conventions assume your code might too.

ModuleForge also has opinions about the code inside your functions, though it does not enforce them. Those are gathered, take them or leave them, in [PowerShell Style Recommendations](./Concepts/PowerShellStyle.md).

## What it buys you

Consistency you do not have to maintain by hand. A brand-new ModuleForge project has, on day one, the same tested and documented release pipeline as a mature one. A contributor who has seen one ModuleForge module can find their way around any of them. And because the tool builds itself, the workflow you are handed is the workflow that ships ModuleForge, exercised on real code with every release.

## Where it is going

ModuleForge is deliberately scoped: it targets GitHub and Azure DevOps, it does not compile binaries, and it stays opinionated rather than growing endless configuration. Within that scope it keeps sharpening: better changelog tooling, more of its conventions surfaced from the command line, and broader platform support (additional CI platforms, DSC resources) where the community wants to build it.

## Your path through the docs

Depending on why you are here:

- **Just want to ship a module?** Start with [Getting Started](./getting-started.md), then the [GitHub tutorial](./tutorials/github/github-tutorial-01-getting-started.md).
- **Want to understand the design first?** Read [ModuleForge vs Alternatives](./Concepts/ModuleForgeVsAlternatives.md) and [From Bartender to ModuleForge](./Concepts/Origin.md).
- **Ready to go deep?** The [Concepts](./Concepts/) section covers versioning, testing, release integrity, and more.
- **Looking for a specific command?** The [function reference](./functions/) documents every exported function.

Welcome. Now go make something great.
