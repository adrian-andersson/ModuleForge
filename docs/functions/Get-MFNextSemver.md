---
layout: default
title: Get-MFNextSemver
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Get-MFNextSemver

## SYNOPSIS

Increments the version of a Semantic Version (SemVer) object.

## SYNTAX

### default (Default)

```
Get-MFNextSemver -Version <semver> [-Increment <string>] [-StableRelease]
```

### preRelease

```
Get-MFNextSemver -Version <semver> [-Increment <string>] [-PreRelease] [-PreReleaseLabel <string>]
```

### Initial

```
Get-MFNextSemver [-PreReleaseLabel <string>] [-InitialPreRelease]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The `Get-MFNextSemver` function takes a Semantic Version (SemVer) object as input and increments the version based on the 'increment' parameter.

It can handle major, minor, and patch increments.

The function also handles pre-release versions and allows the user to optionally override the pre-release label.

## EXAMPLES

### EXAMPLE 1

$Version = [SemVer]::new('1.0.0')
Get-MFNextSemver -Version $Version -Increment 'Minor' -PreRelease

#### DESCRIPTION
This example takes a SemVer object with version '1.0.0', increments the minor version, and adds a pre-release tag.
With no -PreReleaseLabel supplied it uses the default 'pre' label and a zero-padded counter, so the output will be '1.1.0-prev001'.

#### OUTPUT
'1.1.0-prev001'

### EXAMPLE 2

$Version = [SemVer]::new('2.0.0-prerelease.1')
Get-MFNextSemver -Version $Version -Increment 'Major'

#### DESCRIPTION
This example takes a SemVer object with version '2.0.0-prerelease.1', increments the major version, and removes the pre-release tag because the 'prerelease' switch is not set.
The output will be '3.0.0'.

#### OUTPUT
'3.0.0'

## PARAMETERS

### -Increment

What are we incrementing

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: preRelease
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: default
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -InitialPreRelease

Is this the initial prerelease

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Initial
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PreRelease

Is this a prerelease

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: preRelease
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PreReleaseLabel

Optional override the prerelease label.
If not supplied will use 'prerelease'

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Initial
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: preRelease
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -StableRelease

Is this a stable release - drops the prerelease tag from a prerelease version

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: default
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Version

Semver Version

```yaml
Type: System.Management.Automation.SemanticVersion
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: preRelease
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: default
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [semver] - Will accept a Semver from pipeline or via direct assignment

{{ Fill in the Description }}

### System.Management.Automation.SemanticVersion

{{ Fill in the Description }}

## OUTPUTS

### [semver] - Returns a Semantic Version object incremented from the input semver

{{ Fill in the Description }}

### System.Management.Automation.SemanticVersion

{{ Fill in the Description }}

## NOTES

Author: Adrian Andersson


## RELATED LINKS

{{ Fill in the related links here }}


