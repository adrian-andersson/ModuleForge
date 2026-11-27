# ModuleForge Roadmap

## v1.5.0

Built out over a series of prereleases. At a confidence point, review what's left, move it to 1.6, then release 1.5.0 as stable.

- [x] **Stronger build provenance** (1.5.0-prev001). Builds in GitHub Actions or Azure Pipelines add values that can be checked against the CI platform to the `.psm1` header and the manifest `PrivateData` (`ModuleForgeBuildSource*`), beside the ModuleForge version, hashes and build date:
  - The commit SHA and branch. `include_source_metadata` already records these, but only in the package metadata, which is lost once the module is installed
  - The repository, and the run ID, attempt and URL (`GITHUB_RUN_ID` / `GITHUB_RUN_ATTEMPT`; Azure DevOps `Build.BuildId`). Unique per build like a GUID, and it leads to the run's logs and release plan
  - Detected from the platform's own environment variables, so no workflow changes are needed. Local builds leave them out, and `-NoBuildProvenance` turns all of it off
  - These are traceable, not unforgeable: anyone can write values into a manifest. Proving where a package came from needs a signature, so consider GitHub artifact attestations (`actions/attest-build-provenance`) alongside code signing, below
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
  - A change is only breaking if it breaks something released as stable. Changing something that has only existed in the current prerelease series is not breaking, as prereleases make no compatibility promise
  - Aliases for functions, and keeping old parameter names as aliases so renames aren't breaking
  - Argument completers, and that a completer function must be public (in `source/functions`) or it won't be found when the completer runs
  - The Project Rules in use, that they're advisory, to check with the project owner, and to write custom rules where they help
  - Adding operating systems to the Pester matrix where the module is cross-platform
  - Also worth including: comment-based help with an `.EXAMPLE` (the docs are generated from it), streams (`Write-Verbose` and `Write-Information`, not `Write-Host`, and no accidental pipeline output), approved verbs and singular nouns, running Pester, the build and Project Rules locally, and never editing `build/`
  - Consider also writing `AGENTS.md` (or pointing `CLAUDE.md` / `.github/copilot-instructions.md` at it), so AI tools pick it up without being told
  - Stamp it with the ModuleForge version, as it will drift like the workflows (see Managed project workflows, below)
  - How versions come from git tags: the latest `v*` tag is the current version, so a tag added or moved by hand changes the next version, and tags shouldn't be used for anything else
  - Build Test and how build dependencies work: `BuildDependencies.psd1` pins what CI installs, and `testDependencies` decides what the Pester workflows install
  - Add `build/` and `coverage.xml` to `.gitignore`
  - Running Build and Release: the Release choice, the Pester gate, dry runs and reading the release plan
  - Enabling optional workflows: rename the `.example` file for now, until managed workflows replace that
  - Exactly where each kind of file goes: public functions, private helpers, classes, enums, validators, resources, tests, and `buildTest/`
  - Testing and building locally when needed, with the exact commands to paste: `scripts/Invoke-MFPester.ps1`, `Build-MFProject` or `Invoke-MFBuildPreRelease`, `scripts/Invoke-MFProjectRules.ps1` and PSScriptAnalyzer, and importing the built module from `build/` to check it
  - Prefer PowerShell 7.6+ and PSResourceGet (`Install-PSResource`) over Windows PowerShell and PowerShellGet (`Install-Module`), plus a note on PowerShell 7.6 (content to confirm)
  - Links to the ModuleForge docs, repository and PowerShell Gallery page
  - For AI agents especially:
    - Recommended samples, not rules: a function (help block with `.EXAMPLE`, `CmdletBinding`, the verbose and debug lines) and its test (project root walk-up, `Get-MFTestDependency`, clean environment check), ready to copy. Agents copy what they're shown more reliably than they follow descriptions
    - A definition of done for a change: function, test, help example, lint and Project Rules clean, prefixed commit
    - What not to touch: `build/`, generated `docs/functions`, `.example` files unless enabling one, and the pins in `BuildDependencies.psd1`
    - Where project settings live: `moduleForgeConfig.xml` for manifest data, `RequiredModules` and `testDependencies`
    - Known gotchas: Pester's discovery and run phases, class load order and TypeNotFound noise, `$null =` for `.Add()`, `Write-Host`, and one PR before Build and Release because of the Pester gate
    - Rules first and explanations after, with stable headings, so an agent can find a section without reading it all
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
