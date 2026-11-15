---
layout: default
title: New-MFProject
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# New-MFProject

## SYNOPSIS

Capture some basic parameters, and create the scaffold file structure

## SYNTAX

### All parameter sets

```
New-MFProject [-ModuleName] <string> [-Description] <string> [[-MinimumPsVersion] <version>]
 [[-TestDependencies] <string>] [[-ModuleAuthors] <string[]>] [[-CompanyName] <string>]
 [[-ModuleTags] <string[]>] [[-ModulePath] <string>] [[-ProjectUri] <string>] [[-IconUri] <string>]
 [[-LicenseUri] <string>] [[-ConfigFile] <string>] [[-RequiredModules] <Object[]>]
 [[-ExternalModuleDependencies] <string[]>] [[-DefaultCommandPrefix] <string>]
 [[-PrivateData] <hashtable>] [[-Scaffold] <string[]>] [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The New-MFProject function streamlines the process of creating a scaffold (or basic structure) for a new PowerShell module.
Whether you're building a custom module for automation, administration, or any other purpose, this function sets up the initial directory structure, essential files, and variables and properties.
Think of it as laying the foundation for your module project.

------------

## EXAMPLES

### EXAMPLE 1

New-MFProject -ModuleName "MyModule" -Description "A module for automating tasks" -ModuleAuthors "John Doe" -CompanyName "MyCompany" -ModuleTags "automation", "tasks" -ProjectUri "https://github.com/username/repo" -IconUri "https://example.com/icon.png" -LicenseUri "https://example.com/license" -RequiredModules @("Module1", "Module2") -ExternalModuleDependencies @("Dependency1", "Dependency2") -DefaultCommandPrefix "MyMod" -PrivateData @{}

#### DESCRIPTION
This example demonstrates how to use the 'new-mfProject' function to create a scaffold for a new PowerShell module named "MyModule".

It includes a description, authors, company name, tags, project URI, icon URI, license URI, required modules, external module dependencies, default command prefix, and private data.

#### OUTPUT
The function will create the directory structure and essential files for the new module "MyModule" in the current working directory.

It will also set up the specified metadata and dependencies.

### EXAMPLE 2

New-MFProject -ModuleName "MyModule" -Description "A module for automating tasks" -Scaffold GitHub

#### DESCRIPTION
Creates the project, then adds the GitHub Actions workflows and pull request template in the same step,
as Add-MFGithubScaffold does.
Use AzureDevOps for Azure DevOps pipelines, or both.

#### OUTPUT
The project scaffold, plus a .github folder with workflows and a pull request template.

## PARAMETERS

### -CompanyName

Company Name.
If you are building this module for your organisation, this is where it goes

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 5
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

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
  Position: 11
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

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

### -DefaultCommandPrefix

Default command prefix applied to all exported function names in the module manifest

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 14
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Description

A description of your module.
Is used as the descriptor in the module repository

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
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

### -ExternalModuleDependencies

Modules that this module depends on but does not bundle - the consumer is expected to supply them

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 13
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IconUri

A URL to an icon representing this module

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 9
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -LicenseUri

URI to use for your project's license.
If not passed, and the project root has a LICENSE file and the project URI is a GitHub or Azure DevOps repository, links to that file

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 10
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -MinimumPsVersion

Minimum PowerShell version.
Defaults to 7.6 as this is the current LTS version

```yaml
Type: System.Version
DefaultValue: "[version]::new('7.6.0')"
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

### -ModuleAuthors

Who are the primary module authors.
Can be updated later with Update-MFProject

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 4
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ModuleName

The name of your module

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
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
  Position: 7
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ModuleTags

Module Tags.
Used to help discoverability and compatibility in package repositories

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 6
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PrivateData

Additional private data to include in the module manifest PrivateData section.
Must be a hashtable - it is forwarded directly to New-ModuleManifest, which requires a hashtable

```yaml
Type: System.Collections.Hashtable
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 15
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ProjectUri

Project URI.
Will try and read from Git if you are using a git repository.
Any credentials in it are removed

```yaml
Type: System.String
DefaultValue: $(try{git config remote.origin.url}catch{$null})
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 8
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -RequiredModules

Modules that must be imported into the global environment prior to importing this module

```yaml
Type: System.Object[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 12
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Scaffold

Add the CI scaffold too.
GitHub runs Add-MFGithubScaffold, AzureDevOps runs Add-MFAzureDevOpsScaffold.
Pass both for both

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 16
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -TestDependencies

What the Pester workflows install before running tests.
None relies on the modules the runner already has.
PesterAndScriptAnalyzer installs the versions pinned in BuildDependencies.psd1.
All installs everything in
BuildDependencies.psd1 except ModuleForge, which tests never need as they load from source

```yaml
Type: System.String
DefaultValue: PesterAndScriptAnalyzer
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


