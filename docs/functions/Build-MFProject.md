---
layout: default
title: Build-MFProject
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Build-MFProject

## SYNOPSIS

Grab all the files from source, compile them into a single PowerShell module file, create a new module manifest.

## SYNTAX

### All parameter sets

```
Build-MFProject [-Version] <semver> [[-ModulePath] <string>] [[-ConfigFile] <string>]
 [[-ReleaseNotes] <string>] [-ExportClasses] [-ExportEnums] [-NoExternalFiles]
 [-IncludeReleaseNotesInDescription] [-NoBuildProvenance]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Grab the content, functions, classes, validators etc from the .\source\ directory
For all functions found in files in the .\source\functions directory, export them in the module manifest
Add the contents of all scripts to a PSM1 file
Add the contents of any Validators to a separate external ps1 file as a module dependency
Create a new module manifest from the parameters saved with new-mfProject
Tag as a pre-release if a semverPreRelease label is found

## EXAMPLES

### EXAMPLE 1

Build-MFProject -Version '0.12.2-prerelease.1'

#### DESCRIPTION
Make a PowerShell module from the current folder, and mark it as a pre-release version

## PARAMETERS

### -ConfigFile

Path to the ModuleForge config file.
Defaults to 'moduleForgeConfig.xml' in the module root

```yaml
Type: System.String
DefaultValue: moduleForgeConfig.xml
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

### -ExportClasses

Use this flag to put any classes in ScriptsToProcess

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ExportEnums

Use this flag to put any enums in ScriptsToProcess

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IncludeReleaseNotesInDescription

If set, appends the release notes to the module description in the manifest

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
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
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -NoBuildProvenance

If set, omits the ModuleForge build provenance (the psm1 header marker and the ModuleForgeBuild* keys in
the manifest PrivateData).
Provenance is on by default - the SHA256 hashes it records match the checksums
published on the ModuleForge release, so impacted builds can be traced if a vulnerability is found in the tooling

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -NoExternalFiles

Use this to keep everything in a single module file.
By default validators (and exported classes/enums) are written to separate scripts loaded via ScriptsToProcess so they resolve correctly; this switch inlines them into the module file instead

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ReleaseNotes

Release notes to include in the module manifest and GitHub release output

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Version

What version are we building?

```yaml
Type: System.Management.Automation.SemanticVersion
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
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

### System.Management.Automation.SemanticVersion

{{ Fill in the Description }}

## OUTPUTS

## NOTES

Author: Adrian Andersson


## RELATED LINKS

{{ Fill in the related links here }}


