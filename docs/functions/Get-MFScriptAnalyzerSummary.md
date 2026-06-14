---
layout: default
title: Get-MFScriptAnalyzerSummary
parent: Functions
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# Get-MFScriptAnalyzerSummary

## SYNOPSIS
Runs, and then summarises the results of PSScriptAnalyzer across a set of PowerShell function files.

## SYNTAX

```
Get-MFScriptAnalyzerSummary [[-SourcePath] <String>] [[-Severity] <String[]>] [[-Weights] <Hashtable>]
 [-SuppressOutput] [[-ExcludeRules] <String[]>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function scans \`.ps1\` files using PSScriptAnalyzer and returns grouped summaries of errors, warnings, and informational findings.


------------

## EXAMPLES

### EXAMPLE 1
```
Get-MFScriptAnalyzerSummary -SourcePath '.\source\functions'
```

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

### -SourcePath
Source Path for function files

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $(join-path $(join-path '.' -childPath 'source') -childPath functions)
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Severity
What severities should we scan for

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: @('Error','Warning','Information')
Accept pipeline input: False
Accept wildcard characters: False
```

### -Weights
What weights to provide each severity

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: @{
            Error = 50
            Warning = 15
            Information = 1
        }
Accept pipeline input: False
Accept wildcard characters: False
```

### -SuppressOutput
Set this switch to only get the summary

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeRules
Set this for what rules to exclude.
Noisy rule.
Preference script readability over strict whitespace adherence

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: @(
            'PSAvoidTrailingWhitespace' #Noisy rule. Preference script readability over strict whitespace adherence
        )
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] - Returns a summary object containing Errors, Warnings, Informational counts, top-flagged rules, and top-flagged files
## NOTES
Author: Adrian Andersson

## RELATED LINKS

