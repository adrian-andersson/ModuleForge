---
layout: default
title: Resolve-MFModuleCase
parent: Functions
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# Resolve-MFModuleCase

## SYNOPSIS
Nuget specs enforce all lowercase.
Pwsh specs recommend pascal case for module names.
This is fine until you install a module from Nuget 2+ on a *NIX platform
It will install fine, but the folder case will be lowercase, and the manifest will be whatever the module name is
This means discoverability (Get-Module, Import-Module) are effectively broken
This function attempts to fix that discrepency by renaming the module folder to the same as the manifest

## SYNTAX

```
Resolve-MFModuleCase [-ModuleName] <String> [[-ModuleFolder] <String[]>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Try and find a module folder based on a module name
If module folders are found, for each one, try and find the latest Semver version
If Semvers are identified, choose the latest
If the latest version folder (As identified above) has a manifest, get the manifest name
Case-Compare the manifest name with the folder name. 
If the name does not match, try and rename the folder
On rename, sleep for 4 seconds, then proceed to other found locations and repeat if necessary

------------

## EXAMPLES

### EXAMPLE 1
```
Resolve-MFModuleCase -ModuleName moduleforgecasetest -Verbose
```

#### DESCRIPTION
VERBOSE: ===========Executing Resolve-MFModuleCase===========
VERBOSE: Found 1 locations.
Getting latest manifest
VERBOSE: Checking folder C:\Users\example\Documents\PowerShell\Modulesmmoduleforgecasetest
VERBOSE: Found latest version of: 1.0.1
VERBOSE: Found Manifest name with: ModuleForgeCaseTest
WARNING: Case mismatch between module folder moduleforgecasetest and ModuleForgeCaseTest
VERBOSE: Attempt to rename folder to manifest basename to correct for casing
VERBOSE: Folder Rename attempted

## PARAMETERS

### -ModuleName
Name of the Module to resolve

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

### -ModuleFolder
ModuleFolder to use.
If you want to override the module locations manually, use this

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] - Returns a result object per module location found, containing FolderFullName, FolderBaseName, ManifestName, RenameAttempt, and ManifestAndFolderMatch
## NOTES
Author: Adrian Andersson

## RELATED LINKS

