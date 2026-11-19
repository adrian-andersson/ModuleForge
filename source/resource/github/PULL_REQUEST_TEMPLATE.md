## What and why

<!-- What changed, and why. "Fixes #123" closes the issue when this merges -->

## Type of change

<!-- Tick the highest-impact one. Your commit prefixes should agree: feat: for a feature, fix: for a fix
     Breaking: output changed in a way callers rely on, a mandatory parameter added, a parameter renamed or removed
     without an alias, validation tightened, or other behaviour existing scripts depend on changed
     Feature: a new function, a new optional parameter, a parameter renamed with an alias kept, or output added to -->

- [ ] 🔴 Breaking
- [ ] 🟡 Feature
- [ ] 🟢 Fix or maintenance
- [ ] ⚪ No change to the module (docs, CI, tooling)

## Release

<!-- Which Build and Release choice should follow this merge? Most pull requests are Next Prerelease.
     Start a new series on the first feature (minor) or breaking change (major) since the last stable release.
     Later ones in the same series are Next Prerelease -->

- [ ] **Next Prerelease**
- [ ] **New Prerelease Series: minor**
- [ ] **New Prerelease Series: major**
- [ ] **No build yet** - more pull requests to come first

<!-- And, separately -->
- [ ] Last pull request in this series: **Promote to Stable** once its prerelease is tested

## Checklist

- [ ] Commits use changelog prefixes (`feat:`, `fix:` ...). `Get-MFGitPrefixHelp` lists them
- [ ] New or changed behaviour has Pester tests

<!-- ModuleForge's pull request template. Adapt it to your project, or replace it -->
