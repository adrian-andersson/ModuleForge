---
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# Get-MFGitLatestVersion

## SYNOPSIS
Retrieves the latest Git tag version in semantic version format.

## SYNTAX

```
Get-MFGitLatestVersion [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function queries Git for available tags and processes them as semantic versions.
If no tags are found, it initializes a new version starting from \`1.0.0\`.
If Git is unavailable or returns an error, a warning is displayed, and processing continues gracefully.

------------

## EXAMPLES

### EXAMPLE 1
```
get-mfGitLatestVersion
```

#### DESCRIPTION
Queries the current Git repository for version tags, identifies the latest version,
and returns it in \`major.minor.patch\` format.

#### OUTPUT
1.2.3
(Example: If Git tags include \`v1.0.0\`, \`v1.2.3\`, \`v1.1.0\`, the function returns \`1.2.3\` as the latest.)

### EXAMPLE 2
```
get-mfGitLatestVersion -Verbose
```

#### DESCRIPTION
Runs the function with verbose output, providing detailed debugging information
about the Git command execution and version determination.

#### OUTPUT
\`\`\`
===========Executing get-mfGitLatestVersion===========
Got VersionTags: v1.0.0 v1.2.3 v1.1.0
Latest Tag Version: 1.2.3
\`\`\`

## PARAMETERS

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

## OUTPUTS

### [semver] - Returns a Semantec Version object
## NOTES
Author: Adrian Andersson

## RELATED LINKS
