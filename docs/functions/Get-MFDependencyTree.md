---
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# Get-MFDependencyTree

## SYNOPSIS
Generate a dependency tree of ModuleForge PowerShell scripts, either in terminal or a mermaid flowchart

## SYNTAX

```
Get-MFDependencyTree [[-ReferenceData] <Object[]>] [[-OutputType] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
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

### -ReferenceData
What Reference Data are we looking at.
See function example for how to retrieve

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (get-mfFolderItemDetails -path (get-item source).fullname)
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -OutputType
{{ Fill OutputType Description }}

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [OBJECT[]] - ReferenceData Object Array (Resulting from get-mfFolderItemDetails) accepted as pipeline input
## OUTPUTS

### [STRING] - Returns a formatted string representing the dependency tree, Output format can be:
###             - Multi-line string expected to print to terminal (Default Behaviour)
###             - A mermaid chart (If specified with Output Type 'Mermaid') 
###             - A mermaid chart encapsulated in a markdown code block ('MermaidMarkdown')
## NOTES
Author: Adrian Andersson

## RELATED LINKS
