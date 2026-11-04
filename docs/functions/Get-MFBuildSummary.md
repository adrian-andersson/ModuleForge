---
layout: default
title: Get-MFBuildSummary
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Get-MFBuildSummary

## SYNOPSIS

Summarise a build: its version, exports, size and file hashes, with a markdown version for CI.

## SYNTAX

### All parameter sets

```
Get-MFBuildSummary [[-ModulePath] <string>] [[-ConfigFile] <string>] [[-NugetPackagePath] <string>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Reads the compiled module in the build folder and reports what was built.
The SHA256 hashes let anyone
check that a published module matches this build, which matters most on platforms such as Azure DevOps,
where a build has no release page to publish them on.

The Markdown property suits a GitHub job summary ($env:GITHUB_STEP_SUMMARY) or an Azure DevOps build
summary (##vso[task.uploadsummary]).

------------

## EXAMPLES

### EXAMPLE 1

Get-MFBuildSummary

#### DESCRIPTION
Summarise the module in the build folder.

### EXAMPLE 2

(Get-MFBuildSummary -NugetPackagePath $nuRef).Markdown | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append

#### DESCRIPTION
Add the summary, including the package's size and hash, to a GitHub Actions job summary.

## PARAMETERS

### -ConfigFile

Name of the ModuleForge config file.
Defaults to 'moduleForgeConfig.xml'

```yaml
Type: System.String
DefaultValue: moduleForgeConfig.xml
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

### -ModulePath

Root path of the module.
Uses the current working directory by default

```yaml
Type: System.String
DefaultValue: $(get-location).path
SupportsWildcards: false
Aliases:
- Path
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

### -NugetPackagePath

Path to the nupkg made from this build, to include its size and hash

```yaml
Type: System.String
DefaultValue: ''
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

### [PSCustomObject] - ModuleName

{{ Fill in the Description }}

### System.Management.Automation.PSObject

{{ Fill in the Description }}

## NOTES

Author: Adrian Andersson


## RELATED LINKS

{{ Fill in the related links here }}


