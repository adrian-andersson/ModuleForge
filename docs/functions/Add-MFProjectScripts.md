---
layout: default
title: Add-MFProjectScripts
parent: Functions
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# Add-MFProjectScripts

## SYNOPSIS
Adds a scripts scaffold to a ModuleForge project.

## SYNTAX

```
Add-MFProjectScripts [[-ModulePath] <String>] [[-ConfigFile] <String>] [[-ScriptsFolder] <String>] [-Force]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Copies script templates from ModuleForge's resource\scripts folder into a scripts
subfolder at the project root.
Skips existing files by default.

Includes Invoke-MFPester.ps1  - a standalone Pester runner that does not depend on
the ModuleForge module, safe for use in clean CI environments.

This function is also called automatically by Add-MFFilesAndFolders during project
creation, at which point moduleForgeConfig.xml may not yet exist.
A warning is
emitted in that case but the copy proceeds normally.

## EXAMPLES

### EXAMPLE 1
```
Add-MFProjectScripts
```

#### DESCRIPTION
Copies script templates into the scripts folder, skipping any that already exist.

### EXAMPLE 2
```
Add-MFProjectScripts -Force
```

#### DESCRIPTION
Copies script templates and overwrites any existing files in the scripts folder.

## PARAMETERS

### -ModulePath
Root path of the module.
Uses the current working directory by default

```yaml
Type: String
Parameter Sets: (All)
Aliases: Path

Required: False
Position: 1
Default value: $(Get-Location).path
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigFile
Module Config reference

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

### -ScriptsFolder
Scripts folder name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: Scripts
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Should we overwrite if files exist?

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

