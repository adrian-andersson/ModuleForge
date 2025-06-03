---
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# get-mfLatestSemverFromBuildManifest

## SYNOPSIS
If you are manually building, and you have access to the \build folder, you can use this to get the next semver

## SYNTAX

```
get-mfLatestSemverFromBuildManifest [[-path] <String>] [[-configFile] <String>]
 [[-moduleNameOverride] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Detailed Description

------------

## EXAMPLES

### EXAMPLE 1
```
get-mfLatestSemverFromBuildManifest
```

#### DESCRIPTION
Import build\module\modulemanifest.psd1
Find the prerelease tag(if present) and module version.
I.e.
module version 1.1.0 prerelease tag prev003 = 1.1.0-prrev003


#### OUTPUT
Major  Minor  Patch  PreReleaseLabel BuildLabel
-----  -----  -----  --------------- ----------
1      1      0      prev003

## PARAMETERS

### -path
Root path of the module.
Uses the current working directory by default

```yaml
Type: String
Parameter Sets: (All)
Aliases: modulePath

Required: False
Position: 1
Default value: $(get-location).path
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -configFile
{{ Fill configFile Description }}

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

### -moduleNameOverride
{{ Fill moduleNameOverride Description }}

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [semver] - Returns a Semantec Version object
## NOTES
Author: Adrian Andersson

## RELATED LINKS
