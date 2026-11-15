---
layout: default
title: Add-MFProjectScripts
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Add-MFProjectScripts

## SYNOPSIS

Adds a scripts scaffold to a ModuleForge project.

## SYNTAX

### All parameter sets

```
Add-MFProjectScripts [[-ModulePath] <string>] [[-ConfigFile] <string>] [[-ScriptsFolder] <string>]
 [-Force]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Copies script templates from ModuleForge's resource\scripts folder into a scripts
subfolder at the project root.
Skips existing files by default.

Includes Invoke-MFPester.ps1  - a standalone Pester runner that does not depend on
the ModuleForge module, safe for use in clean CI environments.

Also adds BuildDependencies.psd1 to the project root if it is missing.
It pins the modules the CI
templates install, with ModuleForge pinned to the version running this command, so the templates
and the ModuleForge that runs them match.
-Force replaces it too, resetting any pins you changed.

This function is also called automatically by Add-MFFilesAndFolders during project
creation, at which point moduleForgeConfig.xml may not yet exist.
A warning is
emitted in that case but the copy proceeds normally.

## EXAMPLES

### EXAMPLE 1

Add-MFProjectScripts

#### DESCRIPTION
Copies script templates into the scripts folder, skipping any that already exist.

### EXAMPLE 2

Add-MFProjectScripts -Force

#### DESCRIPTION
Copies script templates and overwrites any existing files in the scripts folder.

## PARAMETERS

### -ConfigFile

Module Config reference

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

### -Force

Should we overwrite if files exist?

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
DefaultValue: $(Get-Location).path
SupportsWildcards: false
Aliases:
- Path
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ScriptsFolder

Scripts folder name

```yaml
Type: System.String
DefaultValue: scripts
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

Author: Adrian Andersson


## RELATED LINKS

{{ Fill in the related links here }}


