# ModuleForge Roadmap

## v1.4.0

- [x] CLM compatibility check - an example rule set for the opt-in Project Rules workflow, using PSScriptAnalyzer's `PSUseConstrainedLanguageMode` rule. Soft-fail advisory in the PR pipeline
- [ ] Add CLM compatibility marker to build output / module tags. Needs a rethink: Project Rules is opt-in, so the build has no result to stamp, and a clean static check is not proof of compatibility
- [x] Add a local helper (`Get-MFGitPrefixHelp`) so users can list the recommended commit prefixes, examples and gotchas from the command line. Read-only reference, not an interactive commit builder
- [ ] Dependency manifest (e.g. `dependencies.json`) imported at **both** Pester-test and Build-and-Release time. Must support choosing a source - PSGallery, MAR (Microsoft Artifact Registry / private ACR), or a private feed - and version pinning. Non-trivial; needs a design pass before implementation.
- [x] Allow custom PSScriptAnalyzer settings - an opt-in Project Rules workflow runs a `PSScriptAnalyzer` folder as an **additive** pass with its own PR comment, leaving the default lint untouched. Local files only for now. Rule packs from a gallery, such as InjectionHunter (security/injection), need installing, so they wait on the dependency manifest above.
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

- **Configurable Pester settings** via `pesterConfig.xml` - stay opinionated for now; the fixed defaults are a feature

## Community Contributions

The following areas are out of scope for the core maintainers but welcome as community contributions. If you'd like to collaborate and add support, please open an issue to request contributor access.

- **GitLab scaffold** - CI/CD pipeline and repo scaffold templates targeting GitLab
- **DSC resource support** - support for authoring and packaging DSC resources
