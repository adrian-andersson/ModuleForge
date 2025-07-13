# Pull Request

## Description

<!-- Concise summary of changes + any relevant context or motivation -->

## Related Issues

<!-- Link related issues | Use "Fixes #123" or "AB#456" to auto-close -->

## Quick Review Checklist

- [ ] Pester Tests included targeting satisfactory code coverage (>75%)
- [ ] Followed Best-Practices and implemented Script Analyzer Suggestions
- [ ] Reviewed "Type of Change" section below, and considered if any additional version bumps are required
- [ ] Used appropriate Git commit prefixes (For automated changelog generation)

## Release Intent

<!-- Indicate the release strategy for this PR -->

- [ ] This Pull Request is part of a **PreRelease series**
- [ ] This Pull Request finalises a **Stable Release**
- [ ] No release planned for this Pull Request

## Type of Changes included in this PR

<!--  Select all that apply. Use the highest-impact change as guidance in determining version increment type -->

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

This PR template reflects a workflow used by ModuleForge's author. It’s designed to support semantic versioning, pre-release planning, and cross-platform issue linking. 
Feel free to adapt it to your own project needs, use it as is, or create your own entirely

-->