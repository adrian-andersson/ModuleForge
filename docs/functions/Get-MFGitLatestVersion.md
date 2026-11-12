---
layout: default
title: Get-MFGitLatestVersion
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Get-MFGitLatestVersion

## SYNOPSIS

Retrieves the latest Git tag version in semantic version format.

## SYNTAX

### All parameter sets

```
Get-MFGitLatestVersion
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function queries Git for available tags and processes them as semantic versions.
If no tags are found, or if no tags match semver format, it initializes a new version starting from `1.0.0`.
If Git is unavailable or returns an error, a warning is displayed, and processing continues gracefully.

## EXAMPLES

### EXAMPLE 1

Get-MFGitLatestVersion

#### DESCRIPTION
Queries the current Git repository for version tags, identifies the latest version,
and returns it in `major.minor.patch` format.

#### OUTPUT
1.2.3
(Example: If Git tags include `v1.0.0`, `v1.2.3`, `v1.1.0`, the function returns `1.2.3` as the latest.)

### EXAMPLE 2

Get-MFGitLatestVersion -Verbose

#### DESCRIPTION
Runs the function with verbose output, providing detailed debugging information
about the Git command execution and version determination.

#### OUTPUT
```
===========Executing Get-MFGitLatestVersion===========
Got VersionTags: v1.0.0 v1.2.3 v1.1.0
Latest Tag Version: 1.2.3
```

## PARAMETERS

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [semver] - Returns a Semantic Version object

{{ Fill in the Description }}

### System.Management.Automation.SemanticVersion

{{ Fill in the Description }}

## NOTES

Author: Adrian Andersson


## RELATED LINKS

{{ Fill in the related links here }}


