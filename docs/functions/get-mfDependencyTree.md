---
external help file: ModuleForge-help.xml
Module Name: moduleforge
online version:
schema: 2.0.0
---

# get-mfDependencyTree

## SYNOPSIS
Generate a dependency tree of ModuleForge PowerShell scripts, either in terminal or a mermaid flowchart

## SYNTAX

```
get-mfDependencyTree [-referenceData] <Object[]> [[-outputType] <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The \`get-mfDependencyTree\` function processes an array of objects representing PowerShell scripts and their dependencies.
It generates a visual representation of the dependency tree, either as a text-based tree in the terminal or as a Mermaid diagram.
This function helps in understanding the relationships and dependencies between different scripts and modules in a project.

------------

## EXAMPLES

### EXAMPLE 1
```
$folderItemDetails = get-mfFolderItemDetails -path (get-item .\source).fullname
get-mfDependencyTree ($folderItemDetails|Select-Object relativePath,dependencies)
```

#### DESCRIPTION
Show files and any dependencies

## PARAMETERS

### -outputType
{{ Fill outputType Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Terminal
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

### -referenceData
What Reference Data are we looking at.
See function example for how to retrieve

```yaml
Type: Object[]
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

2024-08-11 - AA
    - Initial script
    - Bit of an experimental function this one

## RELATED LINKS
