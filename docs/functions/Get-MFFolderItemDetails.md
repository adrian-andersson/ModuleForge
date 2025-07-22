---
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# Get-MFFolderItemDetails

## SYNOPSIS
This function analyses a PS1 file, returning its content, any functions, classes and dependencies, as well as a relative location

## SYNTAX

```
Get-MFFolderItemDetails [[-Path] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The \`get-mfFolderItemDetails\` function takes a path to source folder

It creates a job that generates a details about all found PS1 files,
including: The content of PS1 files, the names of any functions, the names of any classes, and any inter-related dependencies

This function uses a job to import all the ps1 items so that all types can be reflected correctly without having to load the module,
So it works without having to build the manifest etc

This function is primary used to build dependency trees and during build to get file contents

------------

## EXAMPLES

### EXAMPLE 1
```
get-mfFolderItemDetails .\source
```

## PARAMETERS

### -Path
Path to source folder.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: ((get-item 'source').fullname)
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

### [STRING] - Path to Source Folder is accepted as Pipeline Input or direct assignment
## OUTPUTS

### [Object[]] - Returns an array of objects with detailed file metadata, including:
###     - **Name** (`[String]`) - Name of the file.
###     - **Path** (`[String]`) - Full file path.
###     - **FileSize** (`[Int]`) - File size in kilobytes.
###     - **FunctionDetails** (`[Object[]]`) - Details of functions within the file.
###     - **ClassDetails** (`[Object[]]`) - Details of classes within the file.
###     - **Contents** (`[String]`) - Entire script content.
###     - **Group** (`[String]`) - Subfolder grouping.
###     - **Dependencies** (`[Object[]]`) - References to other files with name and full path.
### Child Object Details:
### #### FunctionDetails (`[Object]`)
###     - **functionName** (`[String]`) - Name of the function.
###     - **cmdLets** (`[Object]`) - Functions/cmdlets called, with name and usage count.
###     - **types** (`[Object]`) - Classes referenced, with name and usage count.
###     - **parameterTypes** (`[Object]`) - Enums used.
###     - **Validators** (`[Object]`) - Validator classes used.
###     - **Properties** (`[String[]]`) - Properties within the function.
### #### ClassDetails (`[Object]`)
###     - **ClassName** (`[String]`) - Name of the class.
###     - **Methods** (`[String]`) - Methods defined in the class.
###     - **Properties** (`[String[]]`) - Properties within the class.
## NOTES
Author: Adrian Andersson

## RELATED LINKS
