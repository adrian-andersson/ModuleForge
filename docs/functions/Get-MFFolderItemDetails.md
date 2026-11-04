---
layout: default
title: Get-MFFolderItemDetails
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Get-MFFolderItemDetails

## SYNOPSIS

This function analyses a PS1 file, returning its content, any functions, classes and dependencies, as well as a relative location

## SYNTAX

### All parameter sets

```
Get-MFFolderItemDetails [[-Path] <string>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The `Get-MFFolderItemDetails` function takes a path to source folder

It creates a job that generates a details about all found PS1 files,
including: The content of PS1 files, the names of any functions, the names of any classes, and any inter-related dependencies

This function uses a job to import all the ps1 items so that all types can be reflected correctly without having to load the module,
So it works without having to build the manifest etc

This function is primary used to build dependency trees and during build to get file contents

------------

## EXAMPLES

### EXAMPLE 1

Get-MFFolderItemDetails .\source

## PARAMETERS

### -Path

Path to source folder.

```yaml
Type: System.String
DefaultValue: ((get-item 'source').fullname)
SupportsWildcards: false
Aliases: []
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

### [STRING] - Path to Source Folder is accepted as Pipeline Input or direct assignment

{{ Fill in the Description }}

### System.String

{{ Fill in the Description }}

## OUTPUTS

### [Object[]] - Returns an array of objects with detailed file metadata

{{ Fill in the Description }}

## NOTES

Author: Adrian Andersson


## RELATED LINKS

{{ Fill in the related links here }}


