---
layout: default
title: Get-MFScriptAnalyzerSummary
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Get-MFScriptAnalyzerSummary

## SYNOPSIS

Runs, and then summarises the results of PSScriptAnalyzer across a set of PowerShell function files.

## SYNTAX

### All parameter sets

```
Get-MFScriptAnalyzerSummary [[-SourcePath] <string>] [[-Severity] <string[]>]
 [[-Weights] <hashtable>] [[-ExcludeRules] <string[]>] [-SuppressOutput]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function scans `.ps1` files using PSScriptAnalyzer and returns grouped summaries of errors, warnings, and informational findings.


------------

## EXAMPLES

### EXAMPLE 1

Get-MFScriptAnalyzerSummary -SourcePath '.\source\functions'

#### DESCRIPTION
Runs PSScriptAnalyzer over all function files in the specified path and returns a summary object.

#### OUTPUT
Errors           : 0
Warnings         : 3
Informational    : 12
TopErrors        :
TopWarnings      : {@{Name=PSUseShouldProcessForStateChangingFunctions; Count=2}, @{Name=PSAvoidUsingWriteHost; Count=1}}
TopInformational : {@{Name=PSAvoidUsingCmdletAliases; Count=12}}
TopFlaggedFiles  : {@{ScriptName=Build-MFProject.ps1; Counter=E:0 W:2 I:4; Weight=34}}

## PARAMETERS

### -ExcludeRules

Set this for what rules to exclude.
Noisy rule.
Preference script readability over strict whitespace adherence

```yaml
Type: System.String[]
DefaultValue: >-
  @(
              'PSAvoidTrailingWhitespace' #Noisy rule. Preference script readability over strict whitespace adherence
          )
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

### -Severity

What severities should we scan for

```yaml
Type: System.String[]
DefaultValue: "@('Error','Warning','Information')"
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

### -SourcePath

Source Path for function files

```yaml
Type: System.String
DefaultValue: $(join-path $(join-path '.' -childPath 'source') -childPath functions)
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -SuppressOutput

Set this switch to only get the summary

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

### -Weights

What weights to provide each severity

```yaml
Type: System.Collections.Hashtable
DefaultValue: >-
  @{
              Error = 50
              Warning = 15
              Information = 1
          }
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

### System.String

{{ Fill in the Description }}

## OUTPUTS

### [PSCustomObject] - Returns a summary object containing Errors

{{ Fill in the Description }}

### System.Management.Automation.PSObject

{{ Fill in the Description }}

## NOTES

Author: Adrian Andersson


## RELATED LINKS

{{ Fill in the related links here }}


