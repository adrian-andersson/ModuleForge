---
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# get-mfGitChangeLog

## SYNOPSIS
Generates a markdown changelog from Git commit messages between the latest and previous tags.

## SYNTAX

```
get-mfGitChangeLog [[-changeLogTypes] <Hashtable>] [-all] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
This function retrieves Git commit messages between the latest and previous tags, categorizes them based on predefined types, and formats them into a markdown changelog.
It ensures the Git environment is correctly set up and handles errors if Git is not recognized or tags are not found.

## EXAMPLES

### EXAMPLE 1
```
get-mfGitChangeLog
        
DESCRIPTION
Call the `get-mfGitChangeLog` function with default change Log Types. The function will generate a markdown changelog that can be sent to release or artifact notes.
        
#### OUTPUT
# Change Log
Version: v1.0.0 --> v1.1.0
## New Features
- Added new authentication module
## Bug Fixes
- Fixed issue with user login
```

### EXAMPLE 2
```
get-mfGitChangeLog -changeLogTypes @{
    'feat' = 'New Features'
    'fix' = 'Bug Fixes'
    'chore' = 'Chore and Pipeline work'
    'test' = 'Test Changes'
}
        
DESCRIPTION
This example demonstrates how to call the `get-mfGitChangeLog` function with a custom set of changelog types, in case you want to control your own
        
#### OUTPUT
# Change Log
Version: v1.0.0 --> v1.1.0
## New Features
- Added new authentication module
## Bug Fixes
- Fixed issue with user login
## Chore and Pipeline work
- Updated GH Pipeline AutoBuildv3
## Test Changes
- Added test to user login function
```

### EXAMPLE 3
```
get-mfGitChangeLog -All
```

DESCRIPTION
Generates a full markdown changelog with all versions.

#### OUTPUT
# Change Log
## Version: v1.0.0 --\> v1.1.0
### New Features
- Added new authentication module
### Bug Fixes
- Fixed issue with user login
### Chore and Pipeline work
- Updated GH Pipeline AutoBuildv3
### Test Changes
- Added test to user login function
## Version: v1.0.0-prev001 --\> v1.1.0
### New Features
- Added function

## PARAMETERS

### -changeLogTypes
Change Logs Types and corresponding Heading.
Hashtable/Key Value Pair expected.
Key = git type; Value = Heading
'chore' = 'Chore and Pipeline work'
'test' = 'Testing'

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: @{
            'feat' = 'New Features'
            'fix' = 'Bug Fixes'
            'docs' = 'Documentation Changes'
            'refactor' = 'Code Rewrite/Refactor'
            'perf' = 'Performance Improvements'
            #'chore' = 'Chore and Pipeline work'
            #'test' = 'Testing'
        }
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -all
Switch to get a full changelog for ALL tags

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

### [hashtable] - Accepts changeLogTypes hashtable via parameter or pipeline
## OUTPUTS

### [STRING] - Returns a Markdown Compatible string output that can be redirected to a file
## NOTES
Author: Adrian Andersson

## RELATED LINKS
