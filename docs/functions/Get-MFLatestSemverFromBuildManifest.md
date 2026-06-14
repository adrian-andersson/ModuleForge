---
layout: default
title: Get-MFLatestSemverFromBuildManifest
parent: Functions
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# Get-MFLatestSemverFromBuildManifest

## SYNOPSIS
Read the current module version from the compiled manifest in the build folder, returned as a semver object

## SYNTAX

```
Get-MFLatestSemverFromBuildManifest [[-ModulePath] <String>] [[-ConfigFile] <String>]
 [[-ModuleNameOverride] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Reads the compiled module manifest from the build folder and returns the current version as a semver object.
Useful when building locally and needing to determine the current version before calculating the next one.
Supports an optional module name override for cases where the config file is unavailable.

------------

## EXAMPLES

### EXAMPLE 1
```
Get-MFLatestSemverFromBuildManifest
```

#### DESCRIPTION
Import build\module\modulemanifest.psd1
Find the prerelease tag(if present) and module version.
I.e.
module version 1.1.0 prerelease tag prev003 = 1.1.0-prev003


#### OUTPUT
Major  Minor  Patch  PreReleaseLabel BuildLabel
-----  -----  -----  --------------- ----------
1      1      0      prev003

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
Default value: $(get-location).path
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ConfigFile
Name of the ModuleForge config file.
Defaults to 'moduleForgeConfig.xml'

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

### -ModuleNameOverride
Override the module name from config.
Useful when the config file is unavailable and the module name is already known

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [semver] - Returns a Semantic Version object
## NOTES
Author: Adrian Andersson

## RELATED LINKS

