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

The CI/CD pipeline for ModuleForge installs the current stable release from PSGallery at the start of each build run. That published version is then used to compile the source, run Pester tests, generate the build manifest, and publish the result back to PSGallery. The version doing the building is always the last stable release; the version being built is whatever is in the current source.

This means the release cycle is a closed loop:

```
Source changes
  → Pester tests pass
  → Build-MFProject compiles the module
  → Published to PSGallery
  → That release installs itself to build the next release
```

---

## Why This Matters

If ModuleForge cannot build and release itself, something in the workflow it scaffolds for other modules is broken. A successful release is implicit end-to-end validation of the full pipeline: test execution, code coverage reporting, module compilation, NuGet packaging, and PSGallery publication all have to work correctly for the release to land.

This is commonly known as dogfooding -> every function in the build chain is exercised on real source code with every release, not just in a test fixture.

---

## The Bootstrapping Constraint

Because the builder is always the *previous* release, changes to the build functions themselves are not self-tested (outside of Pester) until after they ship. During active development on core pipeline functions, the running version of ModuleForge may not yet have the capability being tested.

This is a known trade-off, not a gap in the design -> it is the same constraint any self-hosting tool faces. To try and reduce the risks, ModuleForge has ~150 Pester tests and 90% Code Coverage, this provides a baseline quality assurance.

See [From Bartender to ModuleForge](./Origin.md) for more background on why self-building was a deliberate design goal from the start.
