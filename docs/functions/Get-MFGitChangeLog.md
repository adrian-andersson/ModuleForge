---
layout: default
title: Get-MFGitChangeLog
parent: Functions
document type: cmdlet
external help file: ModuleForge-Help.xml
HelpUri: ''
Module Name: ModuleForge
PlatyPS schema version: 2024-05-01
---

# Get-MFGitChangeLog

## SYNOPSIS

Generates a markdown changelog from Git commit messages between the latest and previous tags.

## SYNTAX

### Default (Default)

```
Get-MFGitChangeLog [-ChangeLogTypes <hashtable>]
```

### FromLastTag

```
Get-MFGitChangeLog -FromLastTag [-ChangeLogTypes <hashtable>]
```

### All

```
Get-MFGitChangeLog -All [-ChangeLogTypes <hashtable>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function retrieves Git commit messages between the latest and previous tags, categorizes them based on predefined types, and formats them into a markdown changelog.
It ensures the Git environment is correctly set up and handles errors if Git is not recognized or tags are not found.

## EXAMPLES

### EXAMPLE 1

Get-MFGitChangeLog

#### DESCRIPTION
Call the `Get-MFGitChangeLog` function with default change Log Types.
The function will generate a markdown changelog that can be sent to release or artifact notes.

#### OUTPUT
# Change Log
Version: v1.0.0 --> v1.1.0
## New Features
- Added new authentication module
## Bug Fixes
- Fixed issue with user login

### EXAMPLE 2

Get-MFGitChangeLog -ChangeLogTypes @{
'feat' = 'New Features'
'fix' = 'Bug Fixes'
'chore' = 'Chore and Pipeline work'
'test' = 'Test Changes'
}

#### DESCRIPTION
This example demonstrates how to call the `Get-MFGitChangeLog` function with a custom set of changelog types, in case you want to control your own

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

### EXAMPLE 3

Get-MFGitChangeLog -All

#### DESCRIPTION
Generates a full markdown changelog with all versions.

#### OUTPUT
# Change Log
## Version: v1.0.0 --> v1.1.0
### New Features
- Added new authentication module
### Bug Fixes
- Fixed issue with user login
### Chore and Pipeline work
- Updated GH Pipeline AutoBuildv3
### Test Changes
- Added test to user login function
## Version: v1.0.0-prev001 --> v1.1.0
### New Features
- Added function

### EXAMPLE 4

get-mfGitChangeLog -fromLastTag

#### DESCRIPTION
Generates markdown changelog from commit messages from the last tag until now (Head)

#### OUTPUT
# Change Log

### New Features
- Added new authentication module
### Bug Fixes
- Fixed issue with user login
### Chore and Pipeline work
- Updated GH Pipeline AutoBuildv3
### Test Changes
- Added test to user login function

## PARAMETERS

### -All

Switch to get a full changelog for ALL tags

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: All
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ChangeLogTypes

Change Logs Types and corresponding Heading.
Hashtable/Key Value Pair expected.
Key = git type; Value = Heading
'chore' = 'Chore and Pipeline work'
'test' = 'Testing'

```yaml
Type: System.Collections.Hashtable
DefaultValue: >-
  @{
              'feat' = 'New Features'
              'fix' = 'Bug Fixes'
              'docs' = 'Documentation Changes'
              'refactor' = 'Code Rewrite/Refactor'
              'perf' = 'Performance Improvements'
              #'chore' = 'Chore and Pipeline work'
              #'test' = 'Testing'
          }
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: FromLastTag
  Position: Named
  IsRequired: false
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: All
  Position: Named
  IsRequired: false
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Default
  Position: Named
  IsRequired: false
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -FromLastTag

Switch to get the changelog from the last tag until this point.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: FromLastTag
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [hashtable] - Accepts changeLogTypes hashtable via parameter or pipeline

{{ Fill in the Description }}

### System.Collections.Hashtable

{{ Fill in the Description }}

## OUTPUTS

### [STRING] - Returns a Markdown Compatible string output that can be redirected to a file

{{ Fill in the Description }}

### System.String

{{ Fill in the Description }}

## NOTES

Author: Adrian Andersson


## RELATED LINKS

{{ Fill in the related links here }}


