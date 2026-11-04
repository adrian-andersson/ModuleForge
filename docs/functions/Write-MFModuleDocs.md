---
layout: default
title: Write-MFModuleDocs
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Write-MFModuleDocs

## SYNOPSIS

Generates and updates function documentation using Microsoft.PowerShell.PlatyPS, and creates an index for module functions.

## SYNTAX

### All parameter sets

```
Write-MFModuleDocs [[-ModulePath] <string>] [-ModuleName] <string> [[-DocsFolder] <string>]
 [[-FunctionsFolder] <string>] [-IncludeChangeLog] [-SkipIndex] [-StampAllDocs]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Automates documentation generation based on module functions, leveraging Microsoft.PowerShell.PlatyPS
to create Markdown help files.
Injects Just The Docs front matter into every generated page so the
Jekyll sidebar renders a proper navigation hierarchy without manual editing.

Needs Microsoft.PowerShell.PlatyPS 1.0 or newer.
The older platyPS 0.14 module is no longer used.

PlatyPS front matter that changes with the machine or the day, ms.date and Locale, is dropped, so
regenerating the docs only changes pages whose help actually changed.

The -StampAllDocs switch extends that treatment to the entire docs folder: it scans every
subdirectory, creates parent index pages with child link lists, and non-destructively injects
front matter into any page that does not already carry a 'layout:' field.
Pages with existing
Just The Docs front matter are never modified.

## EXAMPLES

### EXAMPLE 1

Write-MFModuleDocs -ModuleName 'MyCustomModule' -IncludeChangeLog

#### DESCRIPTION
Builds documentation for MyCustomModule and includes a full Git-based changelog alongside
function help files.

### EXAMPLE 2

Write-MFModuleDocs -ModuleName 'MyCustomModule' -StampAllDocs -IncludeChangeLog

#### DESCRIPTION
Generates function docs, stamps all existing docs pages with Just The Docs front matter,
and produces a changelog.
Ideal for a CI pipeline docs update step.

### EXAMPLE 3

Write-MFModuleDocs -ModuleName 'MyCustomModule' -SkipIndex

#### DESCRIPTION
Generates function documentation without updating index.md.

## PARAMETERS

### -DocsFolder

Specify the docs folder.
All files and index.md will be created here and in subfolders.
Defaults to 'docs'.

```yaml
Type: System.String
DefaultValue: docs
SupportsWildcards: false
Aliases:
- docsPath
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

### -FunctionsFolder

Subfolder within DocsFolder where function documentation is stored.
Defaults to 'functions'.

```yaml
Type: System.String
DefaultValue: functions
SupportsWildcards: false
Aliases:
- functionsPath
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

### -IncludeChangeLog

If specified, retrieves and includes a Markdown changelog based on Git commit history.

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

### -ModuleName

The name of the PowerShell module for which documentation should be generated.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- module
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ModulePath

The root path where documentation should be stored.
Defaults to the current directory.

```yaml
Type: System.String
DefaultValue: $(get-item .).fullname
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

### -SkipIndex

If specified, skips creating or updating the index.md homepage.

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

### -StampAllDocs

If specified, scans all subdirectories of the docs folder and non-destructively injects
Just The Docs front matter into pages that do not already have a 'layout:' field.
Creates parent index pages with child link lists where none exist.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string] - ModulePath is accepted as pipeline input or via direct assignment.

{{ Fill in the Description }}

### System.String

{{ Fill in the Description }}

## OUTPUTS

## NOTES

Author: Adrian Andersson


## RELATED LINKS

{{ Fill in the related links here }}


