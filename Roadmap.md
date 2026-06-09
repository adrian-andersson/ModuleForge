# ModuleForge Roadmap

## v1.3.0

- [x] Add `Resolve-MFModuleCase` to fix NuGet package ID casing for GitHub Packages
- [x] Add PSGallery publish YAML — install dependencies, pull module from git, run `Resolve-MFModuleCase`, validate with `Get-Module`, publish to PSGallery
- [x] Add a function/method to invoke Pester locally
- [x] Clean up function documentation — fill missing parameter descriptions in `Build-MFProject`, `New-MFProject`, `Get-MFLatestSemverFromBuildManifest`, and `Get-MFDependencyTree`; consider stripping `ProgressAction` from generated docs
- [x] Update `Write-MFModuleDocs` to inject Just The Docs front matter (`parent:`, `title:`) for proper grouped sidebar navigation
- [x] Update `Write-MFModuleDocs` to use each page's H1 heading as link text in the index rather than the filename
- [x] Automated PR to update docs

## v1.4.0

- [ ] CLM compatibility check — scan for classes, `Add-Type`, COM objects and other CLM-incompatible constructs, surface as soft-fail advisory in PR pipeline
- [ ] Add CLM compatibility marker to build output / module tags

## v1.5.0

- [ ] Support multi-line commit messages — parse subject line and body separately, include body in changelog output
- [ ] Support commit scoping — `feat(FunctionName): description` with scope parsed and surfaced in changelog
- [ ] Add `skip-changelog: true` commit footer token — exclude individual commits from changelog without manual filtering
- [ ] Consider `ai-assisted: true` commit footer token — surface AI-assisted commits in changelog (under consideration)

## README

- [x] Add something to showcase the DependencyTree function

## Docs Site

- [x] Write "Why ModuleForge" background page — origin story, cross-pollination from Terraform/React patterns, pure PowerShell decision
- [x] Add commit prefix reference page — covered in `CommitStrategy_And_PRProcess.md`
- [ ] Add document signing tutorial — working YAML example showing how to bolt signing onto the existing pipeline
- [x] Add note on test-alongside-function convention and why it works — covered in `Pester.md`
- [x] Add `Get-MFDependencyTree` Mermaid output example to function page
- [x] Investigate GH Pages light/dark mode — implemented Just The Docs theme with dark colour scheme
- [x] Add a list of bugs, quirks, and behaviours that were worked around in the making of this project, including:
  - Upper-Case Azure-DevOps Packages + Nuget + PreRelease Tags
  - Unpacking the NUPKG to inject the source repository URL to ensure compatibility with NUGET v3 and GHPackages
  - Load order of non-exported items (Classes, Enums)
  - Pester-specific work-arounds

## Considerations

- **Configurable Pester settings** via `pesterConfig.xml` — stay opinionated for now; the fixed defaults are a feature

## Community Contributions

The following areas are out of scope for the core maintainers but welcome as community contributions. If you'd like to collaborate and add support, please open an issue to request contributor access.

- **GitLab scaffold** — CI/CD pipeline and repo scaffold templates targeting GitLab
- **DSC resource support** — support for authoring and packaging DSC resources
