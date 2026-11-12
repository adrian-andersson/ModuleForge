---
layout: default
title: Invoke-MFBuildPreRelease
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Invoke-MFBuildPreRelease

## SYNOPSIS

Build a pre-release version of the ModuleForge project.

## SYNTAX

### All parameter sets

```
Invoke-MFBuildPreRelease [[-ModulePath] <string>] [[-ConfigFile] <string>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Locates the ModuleForge project root by searching for moduleForgeConfig.xml,
reads the latest version from the build manifest, increments the pre-release
label, and calls Build-MFProject.

Combines Get-MFLatestSemverFromBuildManifest, Get-MFNextSemver, and Build-MFProject
into a single convenient command for local pre-release builds.

## EXAMPLES

### EXAMPLE 1

Invoke-MFBuildPreRelease

#### DESCRIPTION
Detect the project root from the current directory, calculate the next pre-release
version from the existing build manifest, and build the module.

### EXAMPLE 2

Invoke-MFBuildPreRelease -ModulePath 'C:\Projects\MyModule'

#### DESCRIPTION
Build a pre-release from an explicit project root path.

## PARAMETERS

### -ConfigFile

Name of the ModuleForge config file

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

### -ModulePath

Root path of the module.
Searches upward from the current working directory if not supplied

```yaml
Type: System.String
DefaultValue: ''
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

## NOTES

Author: Adrian Andersson


## RELATED LINKS

{{ Fill in the related links here }}


