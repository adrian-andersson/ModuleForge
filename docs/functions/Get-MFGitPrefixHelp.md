---
layout: default
title: Get-MFGitPrefixHelp
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Get-MFGitPrefixHelp

## SYNOPSIS

Displays a terminal friendly quick reference for ModuleForge commit prefixes.

## SYNTAX

### All parameter sets

```
Get-MFGitPrefixHelp [[-Section] <string>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Returns a short plain text summary of the commit prefix convention used by Get-MFGitChangeLog, including the commit format, the prefix list, examples, how to pick a version increment, and common gotchas.
Output is limited to ASCII and 80 columns so it reads well in any terminal.
The full guide is at https://adrian-andersson.github.io/ModuleForge/commit-prefixes.html

## EXAMPLES

### EXAMPLE 1

Get-MFGitPrefixHelp

#### DESCRIPTION
Show the full quick reference.

#### OUTPUT
ModuleForge commit prefixes
Full guide: https://adrian-andersson.github.io/ModuleForge/commit-prefixes.html

FORMAT
  <prefix>: <short description in imperative mood>
...

### EXAMPLE 2

Get-MFGitPrefixHelp -Section Gotchas

#### DESCRIPTION
Show only the gotchas section.

#### OUTPUT
ModuleForge commit prefixes
Full guide: https://adrian-andersson.github.io/ModuleForge/commit-prefixes.html

GOTCHAS
  Unknown prefixes are dropped without warning: feature:, bugfix:, feat!:
...

## PARAMETERS

### -Section

Section to display.
Displays every section by default

```yaml
Type: System.String
DefaultValue: All
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

### [STRING] - Returns plain text that can be displayed or redirected to a file

{{ Fill in the Description }}

### System.String

{{ Fill in the Description }}

## NOTES

Author: Adrian Andersson


## RELATED LINKS

{{ Fill in the related links here }}


