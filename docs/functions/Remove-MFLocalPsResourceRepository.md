---
layout: default
title: Remove-MFLocalPsResourceRepository
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Remove-MFLocalPsResourceRepository

## SYNOPSIS

Remove the local test repository that was created with register-mfLocalPsResourceRepository

## SYNTAX

### All parameter sets

```
Remove-MFLocalPsResourceRepository [[-RepositoryName] <string>] [[-Path] <string>] [-WhatIf]
 [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

If a local test repository was created with the register-mfLocalPsResourceRepository, this command will remove it
It will also remove the directory that hosted the local repository

## EXAMPLES

### EXAMPLE 1

Remove-MFLocalPsResourceRepository

#### DESCRIPTION
Unregister the default 'LocalTestRepository' PSResource repository and delete its backing
directory from the temp path.
Uses the same default name and location as Register-MFLocalPsResourceRepository.

## PARAMETERS

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
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

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
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

## OUTPUTS

## NOTES

Author: Adrian Andersson


## RELATED LINKS

{{ Fill in the related links here }}


