---
layout: default
title: Remove-MFLocalPsResourceRepository
parent: Functions
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# Remove-MFLocalPsResourceRepository

## SYNOPSIS
Remove the local test repository that was created with register-mfLocalPsResourceRepository

## SYNTAX

```
Remove-MFLocalPsResourceRepository [[-RepositoryName] <String>] [[-Path] <String>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
If a local test repository was created with the register-mfLocalPsResourceRepository, this command will remove it
It will also remove the directory that hosted the local repository

## EXAMPLES

### EXAMPLE 1
```
Remove-MFLocalPsResourceRepository
```

#### DESCRIPTION
Unregister the default 'LocalTestRepository' PSResource repository and delete its backing
directory from the temp path.
Uses the same default name and location as Register-MFLocalPsResourceRepository.

## PARAMETERS

### -RepositoryName
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

### -Path
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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

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

