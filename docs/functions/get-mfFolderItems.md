---
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# get-mfFolderItems

## SYNOPSIS
Retrieves a filtered list of files from a specified folder, processing \`.mfignore\` and \`.mforder\` rules.

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
The \`get-mfFolderItems\` function scans a folder and applies filtering rules to return a curated list of files.
It offers additional filtering logic, such as:
- Ignoring entries specified in \`.mfignore\`.
- Filtering out non-PS1 files using a switch (\`-psScriptsOnly\`).
- Excluding test-related files (\`*.test.ps1\`, \`*.tests.ps1\`, \`*.skip.ps1\`).
- Handling optional file copying (\`-destination\` and \`-copy\` parameters).

The function ensures all returned paths are fully qualified.
This function is primarily used to assist the get-mfFolderItemDetails as well as build-mfProject.
The -copy switch is added to cleanly copy resources and binaries with build-mfProject

## EXAMPLES

### EXAMPLE 1
```
get-mfFolderItems -path '.\source\functions' -psScriptsOnly
```

#### DESCRIPTION
Scans \`.\source\functions\`, retrieves only \`.ps1\` files, and excludes files matching \`.mfignore\` rules.

### EXAMPLE 2
```
get-mfFolderItems -path '.\source\functions' -destination '.\build\functions' -copy
```

#### DESCRIPTION
Scans \`.\source\functions\`, retrieves filtered files, and copies them to \`.\build\functions\`.

## PARAMETERS

### -path
Path to get items from

```yaml
Type: String
Parameter Sets: (All)
Aliases: s

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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
Flag to actually copy files and not just output

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

### [String] - Accepts a folder path via parameter or pipeline (`ValueFromPipelineByPropertyName`).
### OUTPUTS
### [Object[]] - Returns an array of objects containing:
###     - **Name** (`[String]`) - Name of the file.
###     - **Path** (`[String]`) - Full file path.
###     - **RelativePath** (`[String]`) - Path relative to the source folder.
###     - **Folder** (`[String]`) - Name of the source folder.
###     - **(Optional) newPath** (`[String]`) - Destination path if copying.
###     - **(Optional) newFolder** (`[String]`) - Destination folder name if copying.
## OUTPUTS

## NOTES
Author: Adrian Andersson

## RELATED LINKS
