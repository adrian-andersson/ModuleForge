---
layout: default
title: Invoke-MFPester
parent: Functions
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# Invoke-MFPester

## SYNOPSIS
Run Pester tests for a ModuleForge project with code coverage.

## SYNTAX

```
Invoke-MFPester [[-ModulePath] <String>] [[-ExcludeFromCoverage] <String[]>] [[-Verbosity] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Locates the ModuleForge project root, discovers all source\functions test files,
and runs Pester with code coverage enabled across all non-test function scripts.

.Tests.ps1 and .Skip.ps1 files are always excluded from coverage measurement.
Additional filenames can be excluded via the ExcludeFromCoverage parameter.

Sets the working directory to the project root before invoking Pester so that
test files using the existing get-location convention resolve paths correctly.

## EXAMPLES

### EXAMPLE 1
```
Invoke-MFPester
```

#### DESCRIPTION
Run all Pester tests with code coverage from the current project directory.

### EXAMPLE 2
```
Invoke-MFPester -ExcludeFromCoverage 'Get-MFFolderItemDetails.ps1'
```

#### DESCRIPTION
Run all tests, but exclude the named file from code coverage metrics.

### EXAMPLE 3
```
Invoke-MFPester -Verbosity Normal
```

#### DESCRIPTION
Run all tests with reduced output verbosity.

## PARAMETERS

### -ModulePath
Root path of the module.
Searches upward from the current working directory if not supplied

```yaml
Type: String
Parameter Sets: (All)
Aliases: Path

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ExcludeFromCoverage
Filenames (not full paths) to exclude from code coverage measurement

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -Verbosity
Pester output verbosity level

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: Detailed
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [Pester.Run] - Returns the Pester run result object
## NOTES
Author: Adrian Andersson

## RELATED LINKS

