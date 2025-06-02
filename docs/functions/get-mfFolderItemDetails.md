---
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# get-mfFolderItemDetails

## SYNOPSIS
This function analyses a PS1 file, returning its content, any functions, classes and dependencies, as well as a relative location

## SYNTAX

```
get-mfFolderItemDetails [-path] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The \`get-mfFolderItemDetails\` function takes a path to source folder

It creates a job that generates a details about all found PS1 files,
including: The content of PS1 files, the names of any functions, any dependencies

This function uses a job to import all the ps1 items so that all types can be reflected correctly without having to load the module

------------

## EXAMPLES

### EXAMPLE 1
```
get-mfFolderItemDetails .\source
```

## PARAMETERS

### -path
Path to source folder.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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
