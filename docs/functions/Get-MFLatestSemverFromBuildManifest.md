---
layout: default
title: Get-MFLatestSemverFromBuildManifest
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Get-MFLatestSemverFromBuildManifest

## SYNOPSIS

Read the current module version from the compiled manifest in the build folder, returned as a semver object

## SYNTAX

### All parameter sets

```
Get-MFLatestSemverFromBuildManifest [[-ModulePath] <string>] [[-ConfigFile] <string>]
 [[-ModuleNameOverride] <string>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Reads the compiled module manifest from the build folder and returns the current version as a semver object.
Useful when building locally and needing to determine the current version before calculating the next one.
Supports an optional module name override for cases where the config file is unavailable.

------------

## EXAMPLES

### EXAMPLE 1

Get-MFLatestSemverFromBuildManifest

#### DESCRIPTION
Import build\module\modulemanifest.psd1
Find the prerelease tag(if present) and module version.
I.e.
module version 1.1.0 prerelease tag prev003 = 1.1.0-prev003


#### OUTPUT
Major  Minor  Patch  PreReleaseLabel BuildLabel
-----  -----  -----  --------------- ----------
1      1      0      prev003

## PARAMETERS

### -ConfigFile

Name of the ModuleForge config file.
Defaults to 'moduleForgeConfig.xml'

```yaml
Type: System.String
DefaultValue: moduleForgeConfig.xml
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ModuleNameOverride

Override the module name from config.
Useful when the config file is unavailable and the module name is already known

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ModulePath

Root path of the module.
Uses the current working directory by default

```yaml
Type: System.String
DefaultValue: $(get-location).path
SupportsWildcards: false
Aliases:
- Path
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: false
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

### System.String

{{ Fill in the Description }}

## OUTPUTS

### [semver] - Returns a Semantic Version object

{{ Fill in the Description }}

### System.Management.Automation.SemanticVersion

{{ Fill in the Description }}

## NOTES

Author: Adrian Andersson


## RELATED LINKS

{{ Fill in the related links here }}


