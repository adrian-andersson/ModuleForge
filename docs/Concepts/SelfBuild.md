---
layout: default
title: ModuleForge Builds Itself
parent: Concepts
nav_order: 8
---

# ModuleForge Builds Itself

One of the original design goals for ModuleForge was that it should use itself to build, test, and release itself. Every release of ModuleForge (Except the very first one) is produced by a previous release of ModuleForge.

---

## How It Works

The version that does the building is always the **last stable release of ModuleForge, installed from PSGallery**. The version being built is whatever is in the current source. Every release walks through the same loop:

1. **Edit ModuleForge** - make source changes on a branch.
2. **Open a PR** - the Pester and PSScriptAnalyzer (lint) workflows run automatically: tests are a hard-fail gate, linting and coverage are advisory.
3. **Build a prerelease to the private repo** - once merged, ModuleForge builds a prerelease of itself and publishes it to a private PSResource feed.
4. **User acceptance testing** - install that prerelease from the private feed and confirm it actually does what the change intended.
5. **Promote the prerelease to PSGallery** - the validated prerelease is published to the public gallery.
6. **Build a new prerelease *from* the promoted prerelease** - ModuleForge now rebuilds itself using the just-promoted version as the builder. This is the real bootstrap check: if a newer ModuleForge can be built cleanly by the promoted one, the promoted version is sound.
7. **No build issues → cut a stable release to the private repo.**
8. **Push the stable release to PSGallery.**

The critical step is #6: a prerelease is never promoted to stable until a *later* version of ModuleForge has been successfully built by it. The tool has to prove itself as the builder before it is trusted as the stable release.

The loop in short:

```
Edit source
  → PR: Pester + lint
  → Build prerelease → private feed
  → User acceptance testing
  → Promote prerelease → PSGallery
  → Build next prerelease *using* the promoted version (bootstrap check)
  → No issues → stable release → private feed
  → Push stable → PSGallery
```

---

## Why This Matters

If ModuleForge cannot build and release itself, something in the workflow it scaffolds for other modules is broken. A successful release is implicit end-to-end validation of the full pipeline: test execution, code coverage reporting, module compilation, NuGet packaging, and PSGallery publication all have to work correctly for the release to land.

This is commonly known as dogfooding -> every function in the build chain is exercised on real source code with every release, not just in a test fixture.

---

## The Bootstrapping Constraint

Because the builder is always the *previous* release, changes to the build functions themselves are not self-tested (outside of Pester) until after they ship. During active development on core pipeline functions, the running version of ModuleForge may not yet have the capability being tested.

This is a known trade-off, not a gap in the design -> it is the same constraint any self-hosting tool faces. To try and reduce the risks, ModuleForge has a comprehensive Pester suite and around 90% code coverage across both its exported and private functions.

See [Writing Pester Tests](./Pester.md) for what that scope includes and excludes.

See [From Bartender to ModuleForge](./Origin.md) for more background on why self-building was a deliberate design goal from the start.
