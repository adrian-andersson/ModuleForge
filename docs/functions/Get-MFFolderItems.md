---
layout: default
title: Get-MFFolderItems
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Get-MFFolderItems

## SYNOPSIS

Retrieves a filtered list of files from a specified folder, processing '.mfignore' and '.mforder' rules.

## SYNTAX

### Default (Default)

```
Get-MFFolderItems -Path <string> [-PSScriptsOnly]
```

### Copy

```
Get-MFFolderItems -Path <string> [-PSScriptsOnly] [-Destination <string>] [-Copy]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The 'Get-MFFolderItems' function scans a folder and applies filtering rules to return a curated list of files.
It offers additional filtering logic, such as:
- Ignoring entries specified in `.mfignore`.
- Filtering out non-PS1 files using a switch (`-psScriptsOnly`).
- Excluding test-related files (`*.test.ps1`, `*.tests.ps1`, `*.skip.ps1`).
- Handling optional file copying (`-destination` and `-copy` parameters).

The function ensures all returned paths are fully qualified.
This function is primarily used to assist the get-mfFolderItemDetails as well as build-mfProject.
The -copy switch is added to cleanly copy resources and binaries with build-mfProject

## EXAMPLES

### EXAMPLE 1

Get-MFFolderItems -Path '.\source\functions' -PSScriptsOnly

#### DESCRIPTION
Scans `.\source\functions`, retrieves only `.ps1` files, and excludes files matching `.mfignore` rules.

### EXAMPLE 2

Get-MFFolderItems -Path '.\source\functions' -Destination '.\build\functions' -Copy

#### DESCRIPTION
Scans `.\source\functions`, retrieves filtered files, and copies them to `.\build\functions`.

## PARAMETERS

### -Copy

Flag to actually copy files and not just output

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Copy
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Destination

Destination path to copy files to.
Used in conjunction with the -Copy switch

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Copy
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Path

Path to get items from

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Copy
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: Default
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PSScriptsOnly

Flag to copy scripts only

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Copy
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Default
  Position: Named
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

### [String] - Accepts a folder path via parameter or pipeline (`ValueFromPipelineByPropertyName`).

{{ Fill in the Description }}

### System.String

{{ Fill in the Description }}

## OUTPUTS

### [Object[]] - Returns an array of objects containing:
    - **Name** (`[String]`) - Name of the file.
    - **Path** (`[String]`) - Full file path.
    - **RelativePath** (`[String]`) - Path relative to the source folder.
    - **Folder** (`[String]`) - Name of the source folder.
    - **(Optional) newPath** (`[String]`) - Destination path if copying.
    - **(Optional) newFolder** (`[String]`) - Destination folder name if copying.

{{ Fill in the Description }}

## NOTES

Author: Adrian Andersson


## RELATED LINKS

{{ Fill in the related links here }}


