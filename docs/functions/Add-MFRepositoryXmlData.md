---
layout: default
title: Add-MFRepositoryXmlData
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Add-MFRepositoryXmlData

## SYNOPSIS

Uncompress a nuspec (Which is just a zip with a different extension), parse the XML, add the URL element for the repository, recreate the ZIP file.

## SYNTAX

### All parameter sets

```
Add-MFRepositoryXmlData [-RepositoryUri] <string> [-NugetPackagePath] <string>
 [[-ExtractionPath] <string>] [[-Branch] <string>] [[-Commit] <string>] [-Force]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Some Nuget Package Providers (such as Github Package Manager) require a repository element with a URL attribute in order to be published correctly,
For Githup Packages, this is so it can tie the package back to the actual repository.

At present (March 2024), new-moduleManifest and publish-psresource do not have parameter options that works for this.
This function provides a work-around

------------

## EXAMPLES

### EXAMPLE 1

Add-MFRepositoryXmlData -RepositoryUri 'https://github.com/gituser/example' -NugetPackagePath 'c:\example\module.1.2.3-beta.4.nupkg' -Branch 'main' -Commit '1234123412341234'

#### DESCRIPTION
Unpack module.1.2.3-beta.4.nupkg to a temp location, open the NUSPEC xml and append a repository element with URL, Type, Branch and Commit attributes, repack the nupkg

## PARAMETERS

### -Branch

What branch to add to NUSPEC (Optional)

```yaml
Type: System.String
DefaultValue: ''
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

### -Commit

What commit to add to NUSPEC (Optional)

```yaml
Type: System.String
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

### -ExtractionPath

Temporary path the nupkg is unpacked to before repacking.
Defaults to a new, uniquely named folder in the system temp path, which is removed afterwards

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

### -Force

Use force to ignore remove prompt

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

### -NugetPackagePath

Path to the actual file in the repository, should be something like C:\Users\{UserName}\AppData\Local\Temp\LocalTestRepository\{ModuleName}.{ModuleVersion}.nupkg

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
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -RepositoryUri

RepositoryUri

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
  ValueFromPipelineByPropertyName: true
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

### [String] - This function accepts string values for `repositoryUri` and `NugetPackagePath` via pipeline input by property name.

{{ Fill in the Description }}

### System.String

{{ Fill in the Description }}

## OUTPUTS

## NOTES

Author: Adrian Andersson


## RELATED LINKS

{{ Fill in the related links here }}


