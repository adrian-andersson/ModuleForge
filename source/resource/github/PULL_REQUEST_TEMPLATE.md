## Notes for reviewers, related issues and change IDs

<!-- Anything the commits don't say: why, context, how you tested it, or where to look closely.
     "Fixes #123" closes the issue when this merges -->

## Checklist

- [ ] Commits use changelog prefixes (`feat:`, `fix:` ...). `Get-MFGitPrefixHelp` lists them
- [ ] New or changed behaviour has Pester tests

## Type of change

<!-- Tick the highest-impact one. Your commit prefixes should agree: run Get-MFGitPrefixHelp or read the docs for details.

- Breaking (rare): something changed that could break scripts or modules that depend on this one. E.g.:
  - A mandatory parameter added, a parameter renamed or removed without an alias, changes to pipeline input,
    changed default values, or other changed behaviour callers rely on
- Feature (common): you added or streamlined something. E.g.:
  - New functions, new optional parameters or ones renamed with an alias kept, additions to function output
- Fix (common): you fixed something that was broken, without breaking anything that depends on it. E.g.:
  - A bug fix, additions or changes to the Error, Warning, Information or Verbose streams, performance improvements
- Non-module change (common): tweaks that don't touch the module's code. E.g.:
  - Help, README or other documentation, CI/CD workflows, tests
-->

- [ ] 🔴 Breaking
- [ ] 🟡 Feature
- [ ] 🟢 Fix
- [ ] ⚪ Non-module change

## Release

<!-- Which Build and Release choice should follow this merge? Most pull requests are Next Prerelease.
     Start a new series on the first feature (minor) or breaking change (major) since the last stable release.
     Later ones in the same series are Next Prerelease -->

- [ ] **Next Prerelease**
- [ ] **New Prerelease Series: minor**
- [ ] **New Prerelease Series: major**
- [ ] **No build yet** - more pull requests to come first
- [ ] Last pull request in this series: **Promote to Stable** once its prerelease is tested

<!-- ModuleForge's pull request template. Adapt it to your project, or replace it -->
