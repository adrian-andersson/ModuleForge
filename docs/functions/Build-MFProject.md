---
layout: default
title: Build-MFProject
parent: Functions
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# Build-MFProject

## SYNOPSIS
Grab all the files from source, compile them into a single PowerShell module file, create a new module manifest.

## SYNTAX

```
Build-MFProject [-Version] <SemanticVersion> [[-ModulePath] <String>] [[-ConfigFile] <String>] [-ExportClasses]
 [-ExportEnums] [-NoExternalFiles] [[-ReleaseNotes] <String>] [-IncludeReleaseNotesInDescription]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Grab the content, functions, classes, validators etc from the .\source\ directory
For all functions found in files in the .\source\functions directory, export them in the module manifest
Add the contents of all scripts to a PSM1 file
Add the contents of any Validators to a separate external ps1 file as a module dependency
Create a new module manifest from the parameters saved with new-mfProject
Tag as a pre-release if a semverPreRelease label is found

## EXAMPLES

### EXAMPLE 1
```
Build-MFProject -Version '0.12.2-prerelease.1'
```

#### DESCRIPTION
Make a PowerShell module from the current folder, and mark it as a pre-release version

## PARAMETERS

### -Version
What version are we building?

```yaml
Type: SemanticVersion
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ModulePath
Root path of the module.
Uses the current working directory by default

```yaml
Type: String
Parameter Sets: (All)
Aliases: Path

Required: False
Position: 2
Default value: $(get-location).path
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigFile
Path to the ModuleForge config file.
Defaults to 'moduleForgeConfig.xml' in the module root

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: ModuleForgeConfig.xml
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExportClasses
Use this flag to put any classes in ScriptsToProcess

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

### -ExportEnums
Use this flag to put any enums in ScriptsToProcess

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

### -NoExternalFiles
Use this to not put anything in nestedmodules, making everything a single file.
By default validators are put in a separate nestedmodule script to ensure they are loaded properly

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

### -ReleaseNotes
Release notes to include in the module manifest and GitHub release output

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeReleaseNotesInDescription
If set, appends the release notes to the module description in the manifest

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Author: Adrian Andersson

## RELATED LINKS

