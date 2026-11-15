---
layout: default
title: Add-MFProjectRules
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Add-MFProjectRules

## SYNOPSIS

Adds example Project Rules to a ModuleForge project, and enables the Project Rules workflow or pipeline.

## SYNTAX

### All parameter sets

```
Add-MFProjectRules [[-RuleSet] <string[]>] [[-ModulePath] <string>] [[-ConfigFile] <string>]
 [-Force]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Project Rules run a project's own PSScriptAnalyzer rules, from a PSScriptAnalyzer folder in the project root,
as an advisory pass with its own pull request comment.
This copies ready-made rule sets into that folder:

  - CLM           PSScriptAnalyzer settings that check for Constrained Language Mode compatibility,
                  with the PSUseConstrainedLanguageMode rule.
Needs PSScriptAnalyzer 1.25.0 or newer
  - HelpExamples  A custom rule that warns when a public function has no .EXAMPLE in its help,
                  as the docs are generated from it

It then enables the Project Rules workflow in .github and the pipeline in .azuredevops, whichever exist,
by renaming projectRules.yml.example to projectRules.yml, or adding it if it is missing.
Azure DevOps
still needs a pipeline creating for the file.
It also adds any missing project scripts, as the workflow
calls scripts/Invoke-MFProjectRules.ps1, which you can also run locally.

Existing files are skipped unless -Force is used.

## EXAMPLES

### EXAMPLE 1

Add-MFProjectRules

#### DESCRIPTION
Adds both rule sets to the PSScriptAnalyzer folder, and enables Project Rules in the CI folders that exist.

#### OUTPUT
PSScriptAnalyzer/clm.psd1, PSScriptAnalyzer/rules/HelpExamples/HelpExamples.psm1, and an enabled
projectRules.yml in .github/workflows or .azuredevops/pipelines.

### EXAMPLE 2

Add-MFProjectRules -RuleSet CLM

#### DESCRIPTION
Adds only the Constrained Language Mode check.

### EXAMPLE 3

.\scripts\Invoke-MFProjectRules.ps1 -InstallPSScriptAnalyzer

#### DESCRIPTION
After adding rules, run them locally the same way the workflow does.

## PARAMETERS

### -ConfigFile

Module Config reference

```yaml
Type: System.String
DefaultValue: moduleForgeConfig.xml
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

### -Force

Overwrite rule files and enabled workflows that already exist

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

### -ModulePath

Root path of the module.
Uses the current working directory by default

```yaml
Type: System.String
DefaultValue: $(Get-Location).path
SupportsWildcards: false
Aliases:
- Path
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

### -RuleSet

Which rule sets to add.
Adds all of them by default

```yaml
Type: System.String[]
DefaultValue: "@('CLM','HelpExamples')"
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


