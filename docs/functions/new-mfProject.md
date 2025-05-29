---
external help file: ModuleForge-help.xml
Module Name: moduleforge
online version:
schema: 2.0.0
---

# new-mfProject

## SYNOPSIS
Capture some basic parameters, and create the scaffold file structure

## SYNTAX

```
new-mfProject [-ModuleName] <String> [-description] <String> [[-minimumPsVersion] <Version>]
 [[-moduleAuthors] <String[]>] [[-companyName] <String>] [[-moduleTags] <String[]>] [[-modulePath] <String>]
 [[-projectUri] <String>] [[-iconUri] <String>] [[-licenseUri] <String>] [[-configFile] <String>]
 [[-RequiredModules] <Object[]>] [[-ExternalModuleDependencies] <String[]>] [[-DefaultCommandPrefix] <String>]
 [[-PrivateData] <Object[]>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The new-mfProject function streamlines the process of creating a scaffold (or basic structure) for a new PowerShell module.
Whether you're building a custom module for automation, administration, or any other purpose, this function sets up the initial directory structure, essential files, and variables and properties.
Think of it as laying the foundation for your module project.

------------

## EXAMPLES

### EXAMPLE 1
```
new-mfProject -ModuleName "MyModule" -description "A module for automating tasks" -moduleAuthors "John Doe" -companyName "MyCompany" -moduleTags "automation", "tasks" -projectUri "https://github.com/username/repo" -iconUri "https://example.com/icon.png" -licenseUri "https://example.com/license" -RequiredModules @("Module1", "Module2") -ExternalModuleDependencies @("Dependency1", "Dependency2") -DefaultCommandPrefix "MyMod" -PrivateData @{}
```

#### DESCRIPTION
This example demonstrates how to use the \`new-mfProject\` function to create a scaffold for a new PowerShell module named "MyModule". 
It includes a description, authors, company name, tags, project URI, icon URI, license URI, required modules, external module dependencies, default command prefix, and private data.

#### OUTPUT
The function will create the directory structure and essential files for the new module "MyModule" in the current working directory. 
It will also set up the specified metadata and dependencies.

## PARAMETERS

### -companyName
Company Name.
If you are building this module for your organisation, this is where it goes

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -configFile
{{ Fill configFile Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: ModuleForgeConfig.xml
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefaultCommandPrefix
{{ Fill DefaultCommandPrefix Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 14
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -description
A description of your module.
Is used as the descriptor in the module repository

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExternalModuleDependencies
Modules that must be imported into the global environment prior to importing this module

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 13
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -iconUri
A URL to an icon representing this module.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -licenseUri
URI to use for your projects license.
Will try and use the license file if a projectUri is found

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -minimumPsVersion
Minimum PowerShell version.
Defaults to 7.2 as this is the current LTS version

```yaml
Type: Version
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: [version]::new('7.2.0')
Accept pipeline input: False
Accept wildcard characters: False
```

### -moduleAuthors
Who are the primary module authors.
Can expand later with add-mfmoduleAuthors command

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleName
The name of your module

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -modulePath
Root path of the module.
Uses the current working directory by default

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: $(get-location).path
Accept pipeline input: False
Accept wildcard characters: False
```

### -moduleTags
Module Tags.
Used to help discoverability and compatibility in package repositories

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PrivateData
{{ Fill PrivateData Description }}

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 15
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -projectUri
Project URI.
Will try and read from Git if your using a git repository.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: $(try{git config remote.origin.url}catch{$null})
Accept pipeline input: False
Accept wildcard characters: False
```

### -RequiredModules
Modules that must be imported into the global environment prior to importing this module

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 12
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Author: Adrian Andersson


Changelog:

    2024-07-22 - AA
        - Refactored from Bartender

## RELATED LINKS
