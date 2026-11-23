---
layout: default
title: Add-MFGithubScaffold
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Add-MFGithubScaffold

## SYNOPSIS

Initialises a `.GitHub` scaffold in a PowerShell module, including GH Actions workflows for pester testing and build and release

## SYNTAX

### All parameter sets

```
Add-MFGithubScaffold [[-ModulePath] <string>] [[-ConfigFile] <string>] [[-GithubFolder] <string>]
 [-Force]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function will create a '.github' folder in the moduleforge root (if one does not exist).
It will create GitHub Actions workflows for Pester testing, linting and Build and Release, plus optional
workflows ending in .example, which you rename to enable.
One is Build Test, which installs the published module and checks it
exports what source/functions declares.
It will create 1 Pull Request template.
It will also add any missing project scripts, as some workflow templates call them, and the buildTest folder.

The buildAndRelease template will use Git Tags to mark versions.
If you stick with this template you should refrain from
using tags for other purposes.

The purpose of these workflows and templates is to get you started, creating a quick and easy workflow scaffold.

Please feel free to change the workflows and template to your own needs and preferences.

## EXAMPLES

### EXAMPLE 1

Add-MFGithubScaffold

#### DESCRIPTION
Copies the `.GitHub` folder from the module's `resource` directory to the current module, skipping existing files.

#### OUTPUT
Should have a .github folder, with workflows and a PR template

### EXAMPLE 2

Add-MFGithubScaffold -Force

#### DESCRIPTION
Copies the `.GitHub` scaffold and overwrites existing files in `.github` directory

#### OUTPUT
Should have a .github folder, with workflows and a PR template

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
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Force

Should we overwrite if files exist?

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

### -GithubFolder

githubFolder

```yaml
Type: System.String
DefaultValue: .github
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


