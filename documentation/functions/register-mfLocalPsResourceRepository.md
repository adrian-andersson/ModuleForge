---
external help file: ModuleForge-help.xml
Module Name: moduleforge
online version:
schema: 2.0.0
---

# register-mfLocalPsResourceRepository

## SYNOPSIS
Add a local file-based PowerShell repository into the systems temp location

## SYNTAX

```
register-mfLocalPsResourceRepository [[-repositoryName] <String>] [[-path] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Allows you to test psresourceGet, as well as directly manipulate the nuget package,
for example, to add git data to the nuspec

## EXAMPLES

### EXAMPLE 1
```
register-mfLocalPsResourceRepository            
#### DESCRIPTION
Create a powershell file repository using default values.
```

Repository will be called: LocalTestRepository
Path will be where-ever \[System.IO.Path\]::GetTempPath() points

## PARAMETERS

### -path
Root path of the module.
Uses Temp Path by default

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: [System.IO.Path]::GetTempPath()
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

### -repositoryName
Name of the repository

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: LocalTestRepository
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
        - Created function to register repository

## RELATED LINKS
