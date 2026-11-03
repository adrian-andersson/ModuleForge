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
- [ ] Bring the PSGallery release workflow onto `BuildDependencies.psd1`; it still has its own ModuleForge stable or prerelease toggle
- [ ] Project Rules installs the latest PSScriptAnalyzer itself, rather than the version pinned in `BuildDependencies.psd1`
- [ ] Optional code-signing support in the pipeline - keep it simple: the workflow checks for a code-signing cert and, if present, signs the module **before** the local publish step. Opt-in (no cert = no-op), so it never gets in the way. Design note: signing is intentionally not used by MF's own pipeline; the hard part is testing it (would require handling a real private+public key pair), so the test story needs thought. Pairs with the docs signing tutorial below.

## v1.5.0

- [ ] Support multi-line commit messages - parse subject line and body separately, include body in changelog output. Rethink `BREAKING CHANGE:` here: the docs say to add it to the commit body, but nothing reads the body yet
- [ ] Configurable changelog prefixes - let a project define its own prefix map in `moduleForgeConfig.xml`, so `Get-MFGitChangeLog`, `Write-MFModuleDocs` and `Get-MFGitPrefixHelp` all use it without pipeline edits. Editing the `Get-MFGitChangeLog` call in a pipeline is the only project-wide option today, it does not reach the docs changelog, and `Add-MF*Scaffold -Force` overwrites it. Keep the defaults in one place when doing this, as `Get-MFGitChangeLog` and `Get-MFGitPrefixHelp` each hold a copy (kept in step by a test)
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
