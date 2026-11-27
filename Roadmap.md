# ModuleForge Roadmap

## v1.4.0

- [x] CLM compatibility check - an example rule set for the opt-in Project Rules workflow, using PSScriptAnalyzer's `PSUseConstrainedLanguageMode` rule. Soft-fail advisory in the PR pipeline
- [x] Add a local helper (`Get-MFGitPrefixHelp`) so users can list the recommended commit prefixes, examples and gotchas from the command line. Read-only reference, not an interactive commit builder
- [x] Dependency manifest - `BuildDependencies.psd1`, in the PSResourceGet `RequiredResourceFile` format, pins the modules the Pester, lint, docs and build pipelines install. The build pipeline can also take the latest, or latest prerelease, from PSGallery instead. Each module can name its repository, but a private feed or MAR must already be registered on the runner, with credentials; registering one is not handled yet
- [x] Allow custom PSScriptAnalyzer settings - an opt-in Project Rules workflow runs a `PSScriptAnalyzer` folder as an **additive** pass with its own PR comment, leaving the default lint untouched. Local files only for now. Rule packs from a gallery, such as InjectionHunter (security/injection), could now be pinned in `BuildDependencies.psd1`, but Project Rules does not load installed rule modules yet
- [x] Security hardening - the default lint can no longer be made to run PR code, PR comments are posted by jobs that never run PR code, build pipelines keep the git token off disk while repository code runs, and credentials in a git remote are no longer published as the project URI
- [x] Built manifests list exported aliases by name and no longer use a wildcard for aliases or variables
- [x] Packaging - a unique, cleaned-up repack folder for persistent runners, optional branch and commit metadata, a build summary with hashes (`Get-MFBuildSummary`), and reruns that finish the version an earlier attempt tagged
- [x] Move docs generation from the unmaintained platyPS 0.14 to Microsoft.PowerShell.PlatyPS 1.0. Drops the bogus `-ProgressAction` parameter and the front matter that changed on every run, and stops rather than publish an empty functions section when PlatyPS writes nothing. Not on MAR yet, so it installs from PSGallery
- [x] Minimum PowerShell 7.6 LTS and Pester 6. Tests find the project root and their dependencies with `Get-MFTestDependency`, run from any folder, and keep temp files out of the repo
- [x] `testDependencies` setting in `moduleForgeConfig.xml` decides what the Pester workflows install: `None`, `PesterAndScriptAnalyzer` (the default) or `All` (everything in `BuildDependencies.psd1` except ModuleForge). Set it with `New-MFProject` or `Update-MFProject`
- [x] Bring the PSGallery release workflow onto `BuildDependencies.psd1`. Its `moduleforge_release_toggle` input is replaced by the same `dependency_source` choice Build and Release has
- [x] Project Rules installs PSScriptAnalyzer through `Install-MFBuildDependencies`, so it uses the version pinned in `BuildDependencies.psd1`
- [x] Workflows import exactly the version they resolved, so a newer copy elsewhere on a runner can't replace a pinned one, and the Pester, PSScriptAnalyzer and Project Rules comments say where each module came from (pinned, latest from PSGallery and why, or the runner's own)
- [x] Aliases made with `Set-Alias` or `New-Alias` outside a function are exported by name too, as the docs tutorial uses them
- [x] `New-MFProject -Scaffold GitHub,AzureDevOps` adds the CI scaffold in the same step
- [x] `New-MFProject` fills in `LicenseUri` from a `LICENSE` file for GitHub and Azure DevOps projects, as its help always said it did
- [x] `Add-MFProjectRules` adds the example rule sets (CLM compatibility, help examples) and enables the Project Rules workflow
- [x] Build test in the scaffold, as an opt-in `.example` workflow or pipeline - after Build and Release, install the published package and check it exports every function in `source/functions` and every alias declared there, and nothing else. Catches packaging and export bugs unit tests can't see. GitHub reads the repository's own Packages feed with no secrets; Azure DevOps reads the project feed with the pipeline token

- [x] Azure DevOps pipelines find whether the feed is scoped to the project or the organization, and Build and Release checks before it builds, so a missing feed stops the run before it tags a version. Publishing code coverage warns rather than fails when the project's Test Plans service is off

## v1.4.1

- [x] Fix `Get-MFNextSemver` ignoring the increment for a stable release. With `-StableRelease` it worked from the version passed in, not the incremented one: from a prerelease, `minor` + stable gave `1.2.3-prev002 → 1.2.3` rather than `1.3.0`, and from a stable version any increment + stable threw `version supplied does not contain a prerelease`. It now uses the incremented version when there is one, and only needs a prerelease when there isn't, with a clearer error when there's nothing to promote. Tested for every increment and release type, from both a prerelease and a stable version
- [x] `Get-MFNextSemver` continues the counter for prerelease labels that contain a `v`, such as `devv003`, rather than losing it. A prerelease not in the `<label>v<number>` format, such as `beta.1`, starts again at `v001` with a warning. Supplying the same label no longer warns about casing, and changing only the casing now does
- [x] Build and Release form, on GitHub and Azure DevOps. `version_type` and `release_type` are replaced by one `release` choice that follows how a release goes: start a **New Prerelease Series** (minor or major) once, run **Next Prerelease** until it's ready, then **Promote to Stable**. Next Prerelease from a stable version starts a patch series. Releasing a stable version without a prerelease series first is commented out in the workflow, as **Stable Release** patch, minor and major, so it's a deliberate choice; promoting a version that's already stable stops with a message saying how to enable them. The other inputs are marked Advanced and moved to the end. Scaffolded projects only get the new form when they update their workflow
- [x] Build and Release dry run - an Advanced `dry_run` input works out the version and builds, then stops before anything is tagged, released or published. Build Test and Docs Update skip dry runs
- [x] Build and Release writes a release plan at the top of the run's summary page - the latest version, the release chosen and the next version. The GitHub run name shows the release chosen and the Azure DevOps run is named after the version, both marked when it's a dry run
- [x] `ArrayAddition` Project Rules template - a custom rule, added by `Add-MFProjectRules`, that flags `+=` on an array, as it copies the whole array each time, and recommends a generic list or collecting a loop's output. A Warning in a loop and Information elsewhere, so it brings bad practice to the surface without blocking. Only flags variables the same function or script sets up as an array, so `+=` on numbers and strings is left alone
- [x] Shorter pull request template, on GitHub and Azure DevOps. Notes for reviewers, as what changed belongs in the commits; the type of change as four boxes (breaking, feature, fix, non-module change), with examples of each and the matching commit prefixes in a hidden comment, kept as a record on the pull request; the Release choice that should follow the merge, in the Build and Release form's own words, with "No build yet" and a separate tick for the last pull request in a series; and a two-item checklist. Drops the checks CI already does (coverage, PSScriptAnalyzer) and the twenty change-type boxes. The previous template is still scaffolded, as `.example`, for projects that prefer it
- [x] `New-MFProject -ProjectRules` adds every Project Rules rule set as it creates the project, as `Add-MFProjectRules` does. With `-Scaffold`, the Project Rules workflow is enabled in the CI scaffold it adds, so `New-MFProject -Scaffold GitHub,AzureDevOps -ProjectRules` sets up everything in one command
- [x] `Get-MFGitPrefixHelp` speaks the 1.4.1 release form. The prefix table shows the type of change each prefix is (Feature, Fix, Non-module), as in the pull request template, rather than a version bump, and the Version Increment section is now Release, using the Build and Release choices. `-Section Increments` still works. The gotchas say `ci:` is dropped, so use `chore:`
- [x] `New-MFProject`'s welcome message points to `Get-MFGitPrefixHelp` for commit message guidance
- [x] Pull request template reordered after use: the checklist comes straight after the notes for reviewers, the type of change examples are shorter, and Promote to Stable is the last Release option rather than a separate tick
- [x] `NestedFunctions` Project Rules template - a custom rule, added by `Add-MFProjectRules`, that warns when a function is defined inside another function or a class method, as it can't be tested or reused, and suggests its own file in `source/private`. Functions inside a script block, such as one passed to `Start-Job`, are left alone, and it can be suppressed on the outer function
- [x] Fix `Get-MFDependencyTree` repeating itself, and never finishing when files depend on each other in a loop. Each file's dependencies are shown once, a file seen again is marked `(dependencies shown above)`, a loop is marked `(circular reference)`, and the tree starts from the files nothing else depends on. The Mermaid chart no longer repeats arrows
- [x] Link [Updating Your Workflows and Templates](https://adrian-andersson.github.io/ModuleForge/tutorials/updating-scaffold.html) in the 1.4.1 release notes, as the Build and Release form only changes for projects that update their workflows
- [x] Keep [Making the Most of Releases](https://adrian-andersson.github.io/ModuleForge/tutorials/releases.html), the Build and Release Guide and the Project Rules page in step with the above

## v1.4.2

- [ ] **Build can't silently drop a file.** A source file that can't be read (locked, mid-save) can leave its functions out of the `.psm1` and `FunctionsToExport`, and the build still succeeds. The Pester gate has already passed by then, so nothing stops it shipping. Found on review, not seen in the wild:
  - `Get-MFFolderItemDetails` reads files in a job and collects them with `Receive-Job`, without checking the job's state or its error stream
  - The scriptblock calls `Parser::ParseFile` with its errors discarded (`[ref]$null`)
  - `Build-MFProject` never compares the source files it found with what it wrote
  - Fix: fail the build on any job error or parse error, then check every source file was processed and every public function is in `FunctionsToExport` and the `.psm1`. Build Test only catches missing *public* functions, after publishing, and only where it's enabled
- [ ] **`CrossPlatform` Project Rules template** - flags code that works on Windows but not Linux or macOS: hard-coded `\` path separators (use `Join-Path` or `[IO.Path]::DirectorySeparatorChar`), Windows-only environment variables (`$env:USERPROFILE`, `$env:APPDATA`, `$env:TEMP`, `$env:COMPUTERNAME`, `$env:USERNAME`), Windows-only commands and modules (`Resolve-DnsName`, `Get-WmiObject`, `Get-CimInstance`, the registry provider, `Get-EventLog`, `*-Service`, `Get-Acl` and friends), `.exe` assumptions, and case-sensitive file name mismatches. Information severity where it might be guarded by an `$IsWindows` check, Warning otherwise
- [ ] **`New-MFProject -AddQuickstart`**, and `Add-MFQuickstart` for existing projects - adds `QUICKSTART.md` to the project root: the project's conventions in one place, for people and for AI-assisted development ("read QUICKSTART.md and follow its conventions"). It covers:
  - Folder layout and grouping files into subfolders, one function per file named after it, and the `functions` / `private` / `classes` / `enums` / `validationClasses` split
  - Every function has its own Pester suite, beside it or in `tests/`, or both, whichever suits the project
  - The test dependency loader (`Get-MFTestDependency` and the walk-up to the project root) as a ready-to-copy scriptblock
  - Mocking, so tests never depend on installed modules, and the `$mockPsScriptRoot` pattern for resources
  - Commit prefixes, types of change and the release cycle: start a series once, Next Prerelease while iterating, Promote to Stable when done
  - Aliases for functions, and keeping old parameter names as aliases so renames aren't breaking
  - Argument completers, and that a completer function must be public (in `source/functions`) or it won't be found when the completer runs
  - The Project Rules in use, that they're advisory, to check with the project owner, and to write custom rules where they help
  - Adding operating systems to the Pester matrix where the module is cross-platform
  - Also worth including: comment-based help with an `.EXAMPLE` (the docs are generated from it), streams (`Write-Verbose` and `Write-Information`, not `Write-Host`, and no accidental pipeline output), approved verbs and singular nouns, running Pester, the build and Project Rules locally, and never editing `build/`
  - Consider also writing `AGENTS.md` (or pointing `CLAUDE.md` / `.github/copilot-instructions.md` at it), so AI tools pick it up without being told
  - Stamp it with the ModuleForge version, as it will drift like the workflows (see Managed project workflows in 1.5.0)
  - How versions come from git tags: the latest `v*` tag is the current version, so a tag added or moved by hand changes the next version, and tags shouldn't be used for anything else
  - Build Test and how build dependencies work: `BuildDependencies.psd1` pins what CI installs, and `testDependencies` decides what the Pester workflows install
  - Add `build/` and `coverage.xml` to `.gitignore`
  - Running Build and Release: the Release choice, the Pester gate, dry runs and reading the release plan
  - Enabling optional workflows: rename the `.example` file for now, until managed workflows replace that in 1.5.0
- [x] **Stronger build provenance.** Add values that can be checked against the CI platform to the provenance block in the `.psm1` header and manifest `PrivateData`, beside the ModuleForge version, hashes and build date already there. ModuleForge's own builds first:
  - The commit SHA and branch. `include_source_metadata` already records these, but only in the package metadata, which is lost once the module is installed
  - The repository, and the run ID, attempt and URL (`GITHUB_RUN_ID` / `GITHUB_RUN_ATTEMPT`; Azure DevOps `Build.BuildId`). Unique per build like a GUID, and it leads to the run's logs and release plan
  - Passed into `Build-MFProject` by the workflows, so local builds just leave them out. Respects `-NoBuildProvenance`
  - These are traceable, not unforgeable: anyone can write values into a manifest. Proving where a package came from needs a signature, so consider GitHub artifact attestations (`actions/attest-build-provenance`) alongside code signing in 1.5.0
## v1.5.0

- [ ] Optional code-signing support in the pipeline - keep it simple: the workflow checks for a code-signing cert and, if present, signs the module **before** the local publish step. Opt-in (no cert = no-op), so it never gets in the way. Design note: signing is intentionally not used by MF's own pipeline; the hard part is testing it (would require handling a real private+public key pair), so the test story needs thought. Pairs with the docs signing tutorial below. Moved from 1.4.0: it needs to be done well, not quickly
- [ ] Support multi-line commit messages - parse subject line and body separately, include body in changelog output. Rethink `BREAKING CHANGE:` here: the docs say to add it to the commit body, but nothing reads the body yet
- [ ] Configurable changelog prefixes - let a project define its own prefix map in `moduleForgeConfig.xml`, so `Get-MFGitChangeLog`, `Write-MFModuleDocs` and `Get-MFGitPrefixHelp` all use it without pipeline edits. Editing the `Get-MFGitChangeLog` call in a pipeline is the only project-wide option today, it does not reach the docs changelog, and `Add-MF*Scaffold -Force` overwrites it. Keep the defaults in one place when doing this, as `Get-MFGitChangeLog` and `Get-MFGitPrefixHelp` each hold a copy (kept in step by a test). With the defaults in config, add `ci:` as a known prefix that's excluded by default, like `chore:` and `test:`, so it's one line to turn on. CI changes rarely belong in release notes, but `ci:` is common, and the prefix help currently tells people to use `chore:` instead for no difference in output
- [ ] Managed project workflows, replacing the manual update in [Updating Your Workflows and Templates](https://adrian-andersson.github.io/ModuleForge/tutorials/updating-scaffold.html):
  - `Add-MFProjectWorkflows -Workflow`, following the `Add-MFProjectRules -RuleSet` pattern. Templates stay in their platform folders, so no refactor of the resources. Optional workflows are enabled by name, replacing the `.example` rename, so every enabled workflow has a known file to update. The pull request template is one of the choices, and `Add-MFProjectRules` uses it to enable its workflow
  - `Add-MFGithubScaffold` and `Add-MFAzureDevOpsScaffold` become wrappers, keeping their parameters and `-Force` behaviour, so nothing breaks
  - `Test-MFProjectWorkflows` reports each file as current, outdated, customised or missing, without changing anything. ModuleForge ships the hashes of every template version it has released, generated from the history of `source/resource` (including old file names), with line endings normalised. No setup is needed in existing projects, including ones updated by hand for 1.4.1
  - Updating overwrites files that match a known template, and writes a `.new` file beside customised ones with a warning, so most updates need no review
  - Rewrite the tutorial around it
- [ ] Support commit scoping - `feat(FunctionName): description` with scope parsed and surfaced in changelog
- [ ] Add `skip-changelog: true` commit footer token - exclude individual commits from changelog without manual filtering
- [ ] Consider `ai-assisted: true` commit footer token - surface AI-assisted commits in changelog (under consideration)

## Docs Site

- [ ] Add document signing tutorial - working YAML example showing how to bolt signing onto the existing pipeline

## Discoverability / SEO

Improve SEO

- [ ] **Add `jekyll-sitemap` plugin** to docs `_config.yml` (already have `jekyll-seo-tag`; sitemap is on the GH Pages allowlist) so crawlers get a `sitemap.xml`.
- [ ] **Put the keyword in the title** - change docs `title` / add a `tagline` so page `<title>`s carry "PowerShell" (e.g. `ModuleForge - PowerShell Module Build Tool`).
- [ ] **Add an icon + OG/social image** - `iconUri` in the manifest is empty and links unfurl blank; a social card lifts click-through and backlinks.
- [ ] **Register with Google Search Console** - verify the site and submit the sitemap; lets us see actual indexing/ranking.
- [ ] **Build backlinks** - PR to `awesome-powershell`, a dev.to / r/PowerShell launch post.

## Considerations

- **GitHub Environments for releases** - an `environment:` on Build and Release and the PSGallery release workflow would allow a `main`-only branch restriction (nothing stops a release from a PR branch today), required reviewers, and environment-scoped secrets such as the PSGallery key. Small change; PSGallery is the strongest case, as a publish there can't be undone

- **Out of scope: integration testing, private or authenticated dependency feeds, and the secrets they need.** ModuleForge does unit testing; anything needing real or private dependencies is the user's to run, in a separate runner or repository if needed. `BuildDependencies.psd1` can name any feed already registered on the runner. Decided during 1.4.0-prev003, as an integration tier kept adding jobs, config files and secrets handling

- **Configurable Pester settings** via `pesterConfig.xml` - stay opinionated for now; the fixed defaults are a feature

## Community Contributions

The following areas are out of scope for the core maintainers but welcome as community contributions. If you'd like to collaborate and add support, please open an issue to request contributor access.

- **GitLab scaffold** - CI/CD pipeline and repo scaffold templates targeting GitLab
- **DSC resource support** - support for authoring and packaging DSC resources
