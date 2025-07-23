---
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# Write-MFModuleDocs

## SYNOPSIS
Generates and updates function documentation using PlatyPS, and creates an index for module functions.

## SYNTAX

```
Write-MFModuleDocs [[-ModulePath] <String>] [-ModuleName] <String> [[-DocsFolder] <String>]
 [[-FunctionsFolder] <String>] [-IncludeChangeLog] [-SkipIndex] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
This function automates documentation generation based on module functions, leveraging PlatyPS to create and update Markdown help files.
It also builds an \`index.md\` file for organizing documentation, making it easier to integrate with GitHub Pages or other documentation platforms.
Additionally, if specified, it includes a changelog based on Git commits.

## EXAMPLES

### EXAMPLE 1
```
Write-MFModuleDocs -ModuleName 'MyCustomModule' -IncludeChangeLog
```

#### DESCRIPTION
Builds documentation for \`MyCustomModule\` and includes a full Git-based changelog (\`changeLog.md\`) alongside function help files.

### EXAMPLE 2
```
Write-MFModuleDocs -ModuleName 'MyCustomModule' -SkipIndex
```

#### DESCRIPTION
Generates function documentation without updating \`index.md\`.

## PARAMETERS

### -ModulePath
The root path where documentation should be stored.
Defaults to the current directory.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Path

Required: False
Position: 1
Default value: $(get-item .).fullname
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ModuleName
The name of the PowerShell module for which documentation should be generated.

```yaml
Type: String
Parameter Sets: (All)
Aliases: module

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DocsFolder
Specify the Document Folder.
All files and index.md will be created in this and subsequent subfolders.
Defaults to docs.
Do not us a full path

```yaml
Type: String
Parameter Sets: (All)
Aliases: docsPath

Required: False
Position: 3
Default value: Docs
Accept pipeline input: False
Accept wildcard characters: False
```

### -FunctionsFolder
Specifies the subfolder within \`docsFolder\` where function-specific documentation should be stored.
Defaults to \`functions\`.

```yaml
Type: String
Parameter Sets: (All)
Aliases: functionsPath

Required: False
Position: 4
Default value: Functions
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeChangeLog
If specified, retrieves and includes a Markdown changelog based on Git commit history.

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

### -SkipIndex
If specified, skips creating or updating the \`index.md\` file.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string] - Path is accepted as pipeline input or via direct assignment. It has a defaulf value and does not need to be set
## OUTPUTS

## NOTES
Author: Adrian Andersson

## RELATED LINKS
