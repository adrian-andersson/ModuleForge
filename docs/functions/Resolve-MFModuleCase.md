---
layout: default
title: Resolve-MFModuleCase
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Resolve-MFModuleCase

## SYNOPSIS

Fix module folder casing after a NuGet install so Get-Module and Import-Module can discover the module again

## SYNTAX

### All parameter sets

```
Resolve-MFModuleCase [-ModuleName] <string> [[-ModuleFolder] <string[]>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

NuGet package IDs are enforced as all-lowercase, but PowerShell convention is PascalCase module names.
When a module is installed from a NuGet v2+ feed on a case-sensitive (*NIX) filesystem, the folder is
created in lowercase while the manifest keeps its PascalCase name.
That folder/manifest mismatch
effectively breaks discoverability (Get-Module, Import-Module).
This function corrects it by renaming the
module folder to match the manifest name.

How it works:
Try and find a module folder based on a module name
If module folders are found, for each one, try and find the latest Semver version
If Semvers are identified, choose the latest
If the latest version folder (As identified above) has a manifest, get the manifest name
Case-Compare the manifest name with the folder name.
If the name does not match, try and rename the folder
On rename, sleep for 4 seconds, then proceed to other found locations and repeat if necessary

------------

## EXAMPLES

### EXAMPLE 1

Resolve-MFModuleCase -ModuleName moduleforgecasetest -Verbose

#### DESCRIPTION
VERBOSE: ===========Executing Resolve-MFModuleCase===========
VERBOSE: Found 1 locations.
Getting latest manifest
VERBOSE: Checking folder C:\Users\example\Documents\PowerShell\Modules\moduleforgecasetest
VERBOSE: Found latest version of: 1.0.1
VERBOSE: Found Manifest name with: ModuleForgeCaseTest
WARNING: Case mismatch between module folder moduleforgecasetest and ModuleForgeCaseTest
VERBOSE: Attempt to rename folder to manifest basename to correct for casing
VERBOSE: Folder Rename attempted

## PARAMETERS

### -ModuleFolder

ModuleFolder to use.
If you want to override the module locations manually, use this

```yaml
Type: System.String[]
DefaultValue: ''
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

### -ModuleName

Name of the Module to resolve

```yaml
Type: System.String
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

### System.String

{{ Fill in the Description }}

## OUTPUTS

### [PSCustomObject] - Returns a result object per module location found

{{ Fill in the Description }}

### System.Management.Automation.PSObject

{{ Fill in the Description }}

## NOTES

Author: Adrian Andersson


## RELATED LINKS

{{ Fill in the related links here }}


