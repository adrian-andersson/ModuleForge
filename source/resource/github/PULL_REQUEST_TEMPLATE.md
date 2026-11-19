## Notes for reviewers

<!-- Anything the commits don't say: why, context, how you tested it, or where to look closely.
     "Fixes #123" closes the issue when this merges -->

## Type of change

<!-- Tick the highest-impact one.

- Breaking (rare): something changed that could break scripts or modules that depend on this one. For example:
  - A mandatory parameter added
  - A parameter renamed or removed without an alias, including one that takes pipeline input
  - Validation that now rejects input that used to work
  - A changed default value, or other changed behaviour callers rely on
  - Function output changed in a way that's likely to break piping
- Feature (common): you added or streamlined something. For example:
  - New functions
  - New optional parameters, or a parameter renamed with an alias kept
  - Validation that now accepts more
  - Additions to function output
- Fix (common): you fixed something that was broken, without breaking anything that depends on it. For example:
  - A bug fix
  - Additions or changes to the Error, Warning, Information or Verbose streams
  - Performance improvements, or refactoring that doesn't change behaviour
- Non-module change (common): tweaks that don't touch the module's code. For example:
  - Help, README or other documentation
  - CI/CD workflows
  - Tests

Your commit prefixes should agree:
  - feat: for a feature
  - fix:, refactor: or perf: for a fix
  - docs:, chore: or test: for a non-module change
  Run Get-MFGitPrefixHelp for more guidance
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

<!-- And, separately -->
- [ ] Last pull request in this series: **Promote to Stable** once its prerelease is tested

## Checklist

- [ ] Commits use changelog prefixes (`feat:`, `fix:` ...). `Get-MFGitPrefixHelp` lists them
- [ ] New or changed behaviour has Pester tests

<!-- ModuleForge's pull request template. Adapt it to your project, or replace it -->
