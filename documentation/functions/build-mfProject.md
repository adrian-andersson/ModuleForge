---
external help file: ModuleForge-help.xml
Module Name: moduleforge
online version:
schema: 2.0.0
---

# build-mfProject

## SYNOPSIS
Grab all the files from source, compile them into a single PowerShell module file, create a new module manifest.

## SYNTAX

```
build-mfProject [-version] <SemanticVersion> [[-modulePath] <String>] [[-configFile] <String>] [-exportClasses]
 [-exportEnums] [-noExternalFiles] [-ProgressAction <ActionPreference>] [<CommonParameters>]
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
build-mfProject -version '0.12.2-prerelease.1'
```

#### DESCRIPTION
Make a PowerShell module from the current folder, and mark it as a pre-release version

## PARAMETERS

### -configFile
{{ Fill configFile Description }}

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

### -exportClasses
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

### -exportEnums
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

### -modulePath
Root path of the module.
Uses the current working directory by default

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: $(get-location).path
Accept pipeline input: False
Accept wildcard characters: False
```

### -noExternalFiles
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

### -version
What version are we building?

```yaml
Type: SemanticVersion
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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

    2024-07-26 - AA
        - Refactored from Bartender
        - Added necessary joining functions
        - Minimum Parameters
        - Test with no externals
    
    2024-07-29 - AA
        - Test with all classes,enums,validators as external
        - Revert to just Validators as external after testing
        - Expand parameters
        - Make Pre-release work
        - Decided that short-term, DSC modules are not supported

    2024-08-12 - AA
        - Change the way we handle prereleases, get it from the supplied semver
            - Will allow easier passing through of get-mfNextSemver output
        - Change the way we get script details

    2024-08-23 - AA
        - Change the build to use the folderItemDetails, should lead to a faster pass
        - Added informational output stream to the build, should make for nice Orchestration stream

## RELATED LINKS
