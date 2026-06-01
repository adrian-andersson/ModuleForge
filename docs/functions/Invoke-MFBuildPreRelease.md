---
layout: default
title: Invoke-MFBuildPreRelease
parent: Functions
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# Invoke-MFBuildPreRelease

## SYNOPSIS
Build a pre-release version of the ModuleForge project.

## SYNTAX

```
Invoke-MFBuildPreRelease [[-ModulePath] <String>] [[-ConfigFile] <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Locates the ModuleForge project root by searching for moduleForgeConfig.xml,
reads the latest version from the build manifest, increments the pre-release
label, and calls Build-MFProject.

Combines Get-MFLatestSemverFromBuildManifest, Get-MFNextSemver, and Build-MFProject
into a single convenient command for local pre-release builds.

## EXAMPLES

### EXAMPLE 1
```
Invoke-MFBuildPreRelease
```

#### DESCRIPTION
Detect the project root from the current directory, calculate the next pre-release
version from the existing build manifest, and build the module.

### EXAMPLE 2
```
Invoke-MFBuildPreRelease -ModulePath 'C:\Projects\MyModule'
```

#### DESCRIPTION
Build a pre-release from an explicit project root path.

## PARAMETERS

### -ModulePath
Root path of the module.
Searches upward from the current working directory if not supplied

```yaml
Type: String
Parameter Sets: (All)
Aliases: Path

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ConfigFile
Name of the ModuleForge config file

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: ModuleForgeConfig.xml
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Author: Adrian Andersson

## RELATED LINKS

