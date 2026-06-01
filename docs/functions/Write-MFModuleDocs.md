---
layout: default
title: Write-MFModuleDocs
parent: Functions
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
 [[-FunctionsFolder] <String>] [-IncludeChangeLog] [-SkipIndex] [-StampAllDocs]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Automates documentation generation based on module functions, leveraging PlatyPS to create and
update Markdown help files.
Injects Just The Docs front matter into every generated page so the
Jekyll sidebar renders a proper navigation hierarchy without manual editing.

The -StampAllDocs switch extends that treatment to the entire docs folder: it scans every
subdirectory, creates parent index pages with child link lists, and non-destructively injects
front matter into any page that does not already carry a 'layout:' field.
Pages with existing
Just The Docs front matter are never modified.

## EXAMPLES

### EXAMPLE 1
```
Write-MFModuleDocs -ModuleName 'MyCustomModule' -IncludeChangeLog
```

#### DESCRIPTION
Builds documentation for MyCustomModule and includes a full Git-based changelog alongside
function help files.

### EXAMPLE 2
```
Write-MFModuleDocs -ModuleName 'MyCustomModule' -StampAllDocs -IncludeChangeLog
```

#### DESCRIPTION
Generates function docs, stamps all existing docs pages with Just The Docs front matter,
and produces a changelog.
Ideal for a CI pipeline docs update step.

### EXAMPLE 3
```
Write-MFModuleDocs -ModuleName 'MyCustomModule' -SkipIndex
```

#### DESCRIPTION
Generates function documentation without updating index.md.

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
Specify the docs folder.
All files and index.md will be created here and in subfolders.
Defaults to 'docs'.

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
Subfolder within DocsFolder where function documentation is stored.
Defaults to 'functions'.

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
If specified, skips creating or updating the index.md homepage.

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

### -StampAllDocs
If specified, scans all subdirectories of the docs folder and non-destructively injects
Just The Docs front matter into pages that do not already have a 'layout:' field.
Creates parent index pages with child link lists where none exist.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string] - ModulePath is accepted as pipeline input or via direct assignment.
## OUTPUTS

## NOTES
Author: Adrian Andersson

## RELATED LINKS

