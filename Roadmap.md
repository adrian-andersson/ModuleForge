# ModuleForge Roadmap

## v1.4.0

- [ ] CLM compatibility check — scan for classes, `Add-Type`, COM objects and other CLM-incompatible constructs, surface as soft-fail advisory in PR pipeline
- [ ] Add CLM compatibility marker to build output / module tags
- [ ] Add a local helper (e.g. `Get-MFCommitPrefix`) so users can list the recommended commit prefixes from the command line -> build it as a single source of truth: extract the default `ChangeLogTypes` map into one place that `Get-MFGitChangeLog`, the helper, and (ideally) the docs/PR template all consume, so the prefix list cannot drift. Keep it read-only reference, not an interactive commit builder
- [ ] Dependency manifest (e.g. `dependencies.json`) imported at **both** Pester-test and Build-and-Release time. Must support choosing a source — PSGallery, MAR (Microsoft Artifact Registry / private ACR), or a private feed — and version pinning. Non-trivial; needs a design pass before implementation. (Related Summit theme: secure supply chain / ACR is "the future of PowerShell modules".)
- [ ] Allow custom PSScriptAnalyzer settings — detect a `PSScriptAnalyzer` folder and run it as an **additive** pass on top of the built-in rules (don't replace the opinionated defaults). Candidate rule sources from Summit notes: cross-platform-compatibility rules, InjectionHunter (security/injection), and possibly powering the CLM compatibility check above.
- [ ] Optional code-signing support in the pipeline — keep it simple: the workflow checks for a code-signing cert and, if present, signs the module **before** the local publish step. Opt-in (no cert = no-op), so it never gets in the way. Design note: signing is intentionally not used by MF's own pipeline; the hard part is testing it (would require handling a real private+public key pair), so the test story needs thought. Pairs with the docs signing tutorial below.

## v1.5.0

- [ ] Support multi-line commit messages — parse subject line and body separately, include body in changelog output
- [ ] Support commit scoping — `feat(FunctionName): description` with scope parsed and surfaced in changelog
- [ ] Add `skip-changelog: true` commit footer token — exclude individual commits from changelog without manual filtering
- [ ] Consider `ai-assisted: true` commit footer token — surface AI-assisted commits in changelog (under consideration)

## Docs Site

- [ ] Add document signing tutorial — working YAML example showing how to bolt signing onto the existing pipeline

## Discoverability / SEO

Improve SEO

- [ ] **Add `jekyll-sitemap` plugin** to docs `_config.yml` (already have `jekyll-seo-tag`; sitemap is on the GH Pages allowlist) so crawlers get a `sitemap.xml`.
- [ ] **Put the keyword in the title** — change docs `title` / add a `tagline` so page `<title>`s carry "PowerShell" (e.g. `ModuleForge — PowerShell Module Build Tool`).
- [ ] **Add an icon + OG/social image** — `iconUri` in the manifest is empty and links unfurl blank; a social card lifts click-through and backlinks.
- [ ] **Register with Google Search Console** — verify the site and submit the sitemap; lets us see actual indexing/ranking.
- [ ] **Build backlinks** — PR to `awesome-powershell`, a dev.to / r/PowerShell launch post; the 2027 Summit talk is itself a backlink driver.

## Considerations

- **Configurable Pester settings** via `pesterConfig.xml` — stay opinionated for now; the fixed defaults are a feature

## Community Contributions

The following areas are out of scope for the core maintainers but welcome as community contributions. If you'd like to collaborate and add support, please open an issue to request contributor access.

- **GitLab scaffold** — CI/CD pipeline and repo scaffold templates targeting GitLab
- **DSC resource support** — support for authoring and packaging DSC resources
