---
external help file: ModuleForge-help.xml
Module Name: moduleforge
online version:
schema: 2.0.0
---

# update-mfProject

## SYNOPSIS
Update the parameters of a moduleForge project

## SYNTAX

```
update-mfProject [[-ModuleName] <String>] [[-description] <String>] [[-minimumPsVersion] <Version>]
 [[-moduleAuthors] <String[]>] [[-companyName] <String>] [[-moduleTags] <String[]>] [[-projectUri] <String>]
 [[-iconUri] <String>] [[-licenseUri] <String>] [[-RequiredModules] <Object[]>]
 [[-ExternalModuleDependencies] <String[]>] [[-DefaultCommandPrefix] <String[]>] [[-PrivateData] <Object[]>]
 [[-modulePath] <String>] [[-configFile] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This command allows you to update any of the parameters that were saved with the new-mfProject function without
having to recreate the whole project file from scratch.

------------

## EXAMPLES

### EXAMPLE 1
```
update-mfProject -ModuleName "UpdatedModule" -description "An updated description for the module" -moduleAuthors "Jane Doe" -companyName "UpdatedCompany" -moduleTags "updated", "module" -projectUri "https://github.com/username/updated-repo" -iconUri "https://example.com/updated-icon.png" -licenseUri "https://example.com/updated-license" -RequiredModules @("UpdatedModule1", "UpdatedModule2") -ExternalModuleDependencies @("UpdatedDependency1", "UpdatedDependency2") -DefaultCommandPrefix "UpdMod" -PrivateData @{}
```

#### DESCRIPTION
This example demonstrates how to use the \`update-mfProject\` function to update multiple parameters of an existing module project. 
It updates the module name, description, authors, company name, tags, project URI, icon URI, license URI, required modules, external module dependencies, default command prefix, and private data.

#### OUTPUT
The function will update the specified parameters in the module project configuration file.

### EXAMPLE 2
```
update-mfProject -ModuleName "UpdatedModule" -description "An updated description for the module"
```

#### DESCRIPTION
This example demonstrates how to use the \`update-mfProject\` function to update only the module name and description of an existing module project. 
It leaves all other parameters unchanged.

#### OUTPUT
The function will update the module name and description in the module project configuration file.

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
Position: 15
Default value: ModuleForgeConfig.xml
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefaultCommandPrefix
{{ Fill DefaultCommandPrefix Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 12
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

Required: False
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
Position: 11
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
Position: 8
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
Position: 9
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
Default value: None
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

Required: False
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
Position: 14
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
Position: 13
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
Root path of the module.
Uses the current working directory by default

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
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
Position: 10
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
