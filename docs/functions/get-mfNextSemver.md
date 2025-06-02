---
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# get-mfNextSemver

## SYNOPSIS
Increments the version of a Semantic Version (SemVer) object.

## SYNTAX

### default (Default)
```
get-mfNextSemver -version <SemanticVersion> [-increment <String>] [-stableRelease]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### preRelease
```
get-mfNextSemver -version <SemanticVersion> [-increment <String>] [-prerelease] [-preReleaseLabel <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Initial
```
get-mfNextSemver [-preReleaseLabel <String>] [-initialPreRelease] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The \`get-mfNextSemver\` function takes a Semantic Version (SemVer) object as input and increments the version based on the 'increment' parameter.
It can handle major, minor, and patch increments.
The function also handles pre-release versions and allows the user to optionally override the pre-release label.

## EXAMPLES

### EXAMPLE 1
```
$version = [SemVer]::new('1.0.0')
get-mfNextSemver -version $version -increment 'Minor' -prerelease
```

#### DESCRIPTION
This example takes a SemVer object with version '1.0.0', increments the minor version, and adds a pre-release tag.
The output will be '1.1.0-prerelease.1'.

#### OUTPUT
'1.1.0-prerelease.1'

### EXAMPLE 2
```
$version = [SemVer]::new('2.0.0-prerelease.1')
get-mfNextSemver -version $version -increment 'Major'
```

#### DESCRIPTION
This example takes a SemVer object with version '2.0.0-prerelease.1', increments the major version, and removes the pre-release tag because the 'prerelease' switch is not set.
The output will be '3.0.0'.

#### OUTPUT
'3.0.0'

## PARAMETERS

### -version
Semver Version

```yaml
Type: SemanticVersion
Parameter Sets: default, preRelease
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -increment
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

### -prerelease
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

### -stableRelease
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

### -preReleaseLabel
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

### -initialPreRelease
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

## NOTES
Author: Adrian Andersson

## RELATED LINKS
