---
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# get-mfFolderItems

## SYNOPSIS
Get a list of files from a folder - whilst processing the .mfignore and .mforder files

## SYNTAX

### Default (Default)
```
get-mfFolderItems -path <String> [-psScriptsOnly] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Copy
```
get-mfFolderItems -path <String> [-psScriptsOnly] [-destination <String>] [-copy]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get the files out of a folder.
Adds a bit of smarts to it such as:
- Ignore anything in the .mfignore file
- Filter out anything that isn't a PS1 file if, with a switch
- Ignore files with .test.ps1 - These are assumed to be pester files
- Ignore files with .tests.ps1 - These are assumed to be pester files
- Ignore files with .skip.ps1 - These are assumed to be skippable




 Will always return a full path name

------------

## EXAMPLES

### EXAMPLE 1
```
get-mfFolderItems '.\source\functions\example.ps1'
```

## PARAMETERS

### -path
Path to start in

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -psScriptsOnly
Flag to copy scripts only

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

### -destination
Flag to copy scripts only

```yaml
Type: String
Parameter Sets: Copy
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -copy
Flag to actually copy files and not just output like a fancy Get-ChildItem

```yaml
Type: SwitchParameter
Parameter Sets: Copy
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
