# Pull Request

## Description

<!-- Provide a concise summary of the changes and any relevant context or motivation -->

## Related Issues

<!-- Link or note any related issues or discussions.

For GitHub, BitBucket and GitLab, you can use keywords like "Fixes #123" to auto-close issues.

For Azure DevOps, you can use "AB#123" to link work items. 

For external systems, consider adding a link or reference here
-->

## Quick Review Checklist

- [ ] Pester Tests included with satisfactory code coverage (>75%)
- [ ] Reviewed "Type of Change" section below, and considered if any additional version bumps are required
- [ ] Used appropriate Git commit prefixes (For automated changelog generation)

## Release Intent

<!-- Indicate the release strategy for this PR -->

- [ ] This Pull Request is part of a **PreRelease series**
- [ ] This Pull Request sets the **Initial version bump intent** for a new **release series** (Major / Minor / Patch)
- [ ] This Pull Request finalises a **Stable Release**
- [ ] No release planned for this Pull Request

<!-- 
Note: PreReleases may accumulate features before a stable release. Use the version bump section below to help guide and indicate the intended impact._

Note 2: Aim to keep versioning simple and predictable. Pre-releases may evolve, and if scope changes, consider a version bump and a new prerelease series. Prioritise clarity over strict adherence_
-->

## Type of Changes included in this PR

<!--  Select all that apply. Use the highest-impact change as guidance in determining version bump -->

### 🔴 Major (Breaking)

- [ ] Breaking Change to function Output
- [ ] Mandatory Parameter added or changed
- [ ] Parameter renamed without alias Support
- [ ] Major rewrite or refactor
- [ ] Other breaking change

### 🟡 Minor (Features)

- [ ] New Function(s) added
- [ ] Non-breaking change to function output
- [ ] Parameter renamed with backwards-compatible alias
- [ ] New optional parameter
- [ ] Input validation changes
- [ ] Other minor enhancements

### 🟢 Patch (Fixes & Maintenance)

- [ ] Bug Fix(es)
- [ ] Stream Output Changes (Verbose, Error, etc)
- [ ] Performance or style improvements
- [ ] Test updates or additions
- [ ] Other patch-level change

### ⚪ Non-Release Change

- [ ] Documentation update or change
- [ ] CI/CD or workflow change
- [ ] Internal tooling or developer experience
- [ ] Other non-release change

<!-- To Repository Owners:

This Pull Request template reflects a workflow used by ModuleForge's author. It’s designed to support semantic versioning, pre-release planning, and cross-platform issue linking. Feel free to adapt it to your own project needs, use it as is, or create your own entirely

-->