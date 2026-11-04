---
layout: default
title: Register-MFLocalPsResourceRepository
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Register-MFLocalPsResourceRepository

## SYNOPSIS

Add a local file-based PowerShell repository into the systems temp location

## SYNTAX

### All parameter sets

```
Register-MFLocalPsResourceRepository [[-RepositoryName] <string>] [[-Path] <string>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Allows you to test psresourceGet, as well as directly manipulate the nuget package,
for example, to add git data to the nuspec

## EXAMPLES

### EXAMPLE 1

Register-MFLocalPsResourceRepository      
#### DESCRIPTION
Create a powershell file repository using default values.

Repository will be called: LocalTestRepository
Path will be where-ever [System.IO.Path]::GetTempPath() points

## PARAMETERS

### -Path

Root path of the module.
Uses Temp Path by default

```yaml
Type: System.String
DefaultValue: '[System.IO.Path]::GetTempPath()'
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

### -RepositoryName

Name of the repository

```yaml
Type: System.String
DefaultValue: LocalTestRepository
SupportsWildcards: false
Aliases: []
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


