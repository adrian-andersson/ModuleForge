---
layout: default
title: Get-MFDependencyTree
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Get-MFDependencyTree

## SYNOPSIS

Generate a dependency tree of ModuleForge PowerShell scripts, either in terminal or a mermaid flowchart

## SYNTAX

### All parameter sets

```
Get-MFDependencyTree [[-ReferenceData] <Object[]>] [[-OutputType] <string>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The `Get-MFDependencyTree` function processes an array of objects representing PowerShell scripts and their dependencies.
It generates a visual representation of the dependency tree, either as a text-based tree in the terminal or as a Mermaid diagram.
This function helps in understanding the relationships and dependencies between different scripts and modules in a project.

------------

## EXAMPLES

### EXAMPLE 1

$folderItemDetails = Get-MFFolderItemDetails -Path (get-item .\source).fullname
Get-MFDependencyTree ($folderItemDetails|Select-Object relativePath,dependencies)

#### DESCRIPTION
Show files and any dependencies

## PARAMETERS

### -OutputType

Output format  - 'Terminal' prints a text-based dependency tree, 'Mermaid' outputs a flowchart, 'MermaidMarkdown' wraps the flowchart in a markdown code block for embedding in docs

```yaml
Type: System.String
DefaultValue: Terminal
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

### -ReferenceData

What Reference Data are we looking at.
See function example for how to retrieve

```yaml
Type: System.Object[]
DefaultValue: (get-mfFolderItemDetails -path (get-item source).fullname)
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: false
  ValueFromPipeline: true
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

### [OBJECT[]] - ReferenceData Object Array (Resulting from get-mfFolderItemDetails) accepted as pipeline input

{{ Fill in the Description }}

### System.Object[]

{{ Fill in the Description }}

## OUTPUTS

### [STRING] - Returns a formatted string representing the dependency tree

{{ Fill in the Description }}

### System.String

{{ Fill in the Description }}

## NOTES

Author: Adrian Andersson


## RELATED LINKS

{{ Fill in the related links here }}


