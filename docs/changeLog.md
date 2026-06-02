---
layout: default
title: Change Log
nav_order: 2
---

# Change Log

## Version: v1.3.0-prev005

## Version: v1.3.0-prev004

## Version: v1.3.0-prev003


### New Features

- update Write-MFModuleDocs to better support jekyll and gh docs pages, adding JustTheDocs frontMatter, working out nav spacing, cleaning up casing
- add Invoke-MFPester to run pester in a similar configuration to the PR flow, enabling simpler testing before a push
- add MFBuildPreRelease function to build locally if required


## Version: v1.3.0-prev002


### Documentation Changes

- fix table spacing
- Spelling mistakes, some intro adjustments
- updated the Readme



### Bug Fixes

- fix error in Resolve-MFModuleCase that was introduced with code clean-up


## Version: v1.3.0-prev001


### New Features

- Add Resolve-MFModuleCase function to fix nuget case inconsistency,



### Bug Fixes

- Rebuild the path to get after a rename to better support case-sensitive OS's
- Add an erroraction command to try and skip unreadable module locations
- rewrite Resolve-MFModuleCase to not rely on Get-Module, rename the case-incorrect folder regardless of OS, and return something to the pipeline that states what happened
- change folder name to a 2 step process as that may cause issues on linux sometimes when renaming a folder to the same name but with different casing
- Add errorAction behaviour to Resolve-MFModuleCase when getting modules


## Version: v1.2.2

## Version: v1.2.2-prev002


### Bug Fixes

- Redo the folder select in Write-MFModuleDocs to improve edge-cases and to improve markdown results
- switch to case-insensitive replace in Write-MFModuleDocs


## Version: v1.2.2-prev001


### Documentation Changes

- updated README
- clean up readme. Move documentation to GH Pages and 'docs' branch
- update semver_interpretation with lower-case prerelease labelling concerns addressed



### New Features

- new prerelease to test out azure-devops scaffolding. Plus small tweaks to github pipeline, and an updated PR template
- update git buildAndRelease markdown to use fromLastTag when building change log
- added AZD PR Template and Pipeline files
- added add-mfAzureDevOpsScaffold function and tests
- Add a way to pass through release notes and changelog to build-mfProject function
- Expanded get-mfGitChangeLog function to provide a way to get the commit messages to the HEAD point, as in changes from the last tag until now, so that we can generate change logs prior to tagging.
- add get-mfLatestSemverFromBuildManifest function which checks for a manifest in the build directory, and use the version within to get the current (latest) version. Useful for local builds
- add-mfGithubScaffold function to add a way to quickstart github
- New function, write-mfModuleDocs, that help to create function, changelog, and index to use with github pages
- Added function get-mfGitLatestVersion to help get the current  (latest) version from tags, return 1.0.0 if no tags
- create write-mfModuleDocs function to automate the use of platyps and online docs. Intended use case is in github pages
- create helper function to get the current/latest version from git tags
- non-breaking change to get-mfGitChangeLog to add a function to get all the changes, not just the ones between latest and last tag
- get-mfGitChangeLog created, to be used in workflow pipelines. Uses Tags



### Bug Fixes

- clean up get-mfGitChangeLog, better handling when no relevant commit messages have been created
- change the way write-mfModuleDocs groups objects to better capture subdirectories
- add more verbosity to add-mfGithubScaffold to track strange behaviour
- get-mfGitChangeLog. Added variable for change log types, adjusted defaults.  Adjusted heading output
- get-mfNextSemver - Make default prerelease label lowercase
- get-mfNexSemver - made the prerelease label check case sensitive, added a warning that the label will be updated but that this may cause ordering problems
- Error in copyright in build-mfProject
- Error in the handling of ModuleAuthors in build-mfProject.ps1


## Version: v1.2.1-prev001


### Documentation Changes

- updated README


## Version: v1.2.0


### Documentation Changes

- clean up readme. Move documentation to GH Pages and 'docs' branch
- update semver_interpretation with lower-case prerelease labelling concerns addressed



### New Features

- new prerelease to test out azure-devops scaffolding. Plus small tweaks to github pipeline, and an updated PR template
- update git buildAndRelease markdown to use fromLastTag when building change log
- added AZD PR Template and Pipeline files
- added add-mfAzureDevOpsScaffold function and tests
- Add a way to pass through release notes and changelog to build-mfProject function
- Expanded get-mfGitChangeLog function to provide a way to get the commit messages to the HEAD point, as in changes from the last tag until now, so that we can generate change logs prior to tagging.
- add get-mfLatestSemverFromBuildManifest function which checks for a manifest in the build directory, and use the version within to get the current (latest) version. Useful for local builds
- add-mfGithubScaffold function to add a way to quickstart github
- New function, write-mfModuleDocs, that help to create function, changelog, and index to use with github pages
- Added function get-mfGitLatestVersion to help get the current  (latest) version from tags, return 1.0.0 if no tags
- create write-mfModuleDocs function to automate the use of platyps and online docs. Intended use case is in github pages
- create helper function to get the current/latest version from git tags
- non-breaking change to get-mfGitChangeLog to add a function to get all the changes, not just the ones between latest and last tag
- get-mfGitChangeLog created, to be used in workflow pipelines. Uses Tags



### Bug Fixes

- clean up get-mfGitChangeLog, better handling when no relevant commit messages have been created
- change the way write-mfModuleDocs groups objects to better capture subdirectories
- add more verbosity to add-mfGithubScaffold to track strange behaviour
- get-mfGitChangeLog. Added variable for change log types, adjusted defaults.  Adjusted heading output
- get-mfNextSemver - Make default prerelease label lowercase
- get-mfNexSemver - made the prerelease label check case sensitive, added a warning that the label will be updated but that this may cause ordering problems
- Error in copyright in build-mfProject
- Error in the handling of ModuleAuthors in build-mfProject.ps1


