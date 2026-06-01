---
layout: default
title: Get-MFNextSemver
parent: Functions
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# Get-MFNextSemver

## SYNOPSIS
Increments the version of a Semantic Version (SemVer) object.

## SYNTAX

### default (Default)
```
Get-MFNextSemver -Version <SemanticVersion> [-Increment <String>] [-StableRelease]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### preRelease
```
Get-MFNextSemver -Version <SemanticVersion> [-Increment <String>] [-PreRelease] [-PreReleaseLabel <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Initial
```
Get-MFNextSemver [-PreReleaseLabel <String>] [-InitialPreRelease] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The \`Get-MFNextSemver\` function takes a Semantic Version (SemVer) object as input and increments the version based on the 'increment' parameter. 
It can handle major, minor, and patch increments. 
The function also handles pre-release versions and allows the user to optionally override the pre-release label.

## EXAMPLES

### EXAMPLE 1
```
$Version = [SemVer]::new('1.0.0')
Get-MFNextSemver -Version $Version -Increment 'Minor' -PreRelease
```

#### DESCRIPTION
This example takes a SemVer object with version '1.0.0', increments the minor version, and adds a pre-release tag.
The output will be '1.1.0-prerelease.1'.

#### OUTPUT
'1.1.0-prerelease.1'

### EXAMPLE 2
```
$Version = [SemVer]::new('2.0.0-prerelease.1')
Get-MFNextSemver -Version $Version -Increment 'Major'
```

#### DESCRIPTION
This example takes a SemVer object with version '2.0.0-prerelease.1', increments the major version, and removes the pre-release tag because the 'prerelease' switch is not set.
The output will be '3.0.0'.

#### OUTPUT
'3.0.0'

## PARAMETERS

### -Version
Semver Version

```yaml
Type: SemanticVersion
Parameter Sets: default, preRelease
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Increment
What are we incrementing

```yaml
Type: String
Parameter Sets: default, preRelease
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PreRelease
Is this a prerelease

```yaml
Type: SwitchParameter
Parameter Sets: preRelease
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -StableRelease
Is this a prerelease

```yaml
Type: SwitchParameter
Parameter Sets: default
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PreReleaseLabel
Optional override the prerelease label.
If not supplied will use 'prerelease'

```yaml
Type: String
Parameter Sets: preRelease, Initial
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InitialPreRelease
Is this the initial prerelease

```yaml
Type: SwitchParameter
Parameter Sets: Initial
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

### [semver] - Will accept a Semver from pipeline or via direct assignment
## OUTPUTS

### [semver] - Returns a Semantec Version object that should increment, based on the other parameters, the input semver
## NOTES
Author: Adrian Andersson

## RELATED LINKS

