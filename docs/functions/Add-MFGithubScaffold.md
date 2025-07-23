---
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# Add-MFGithubScaffold

## SYNOPSIS
Initialises a \`.GitHub\` scaffold in a PowerShell module, including GH Actions workflows for pester testing and build and release

## SYNTAX

```
Add-MFGithubScaffold [[-ModulePath] <String>] [[-ConfigFile] <String>] [[-GithubFolder] <String>] [-Force]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function will create a '.github' folder in the moduleforge root (if one does not exist).
It will create 2 github actions workflows, 1 for Pester testing, 1 for buildAndRelease
It will create 1 Pull Request template.

The buildAndRelease template will use Git Tags to mark versions.
If you stick with this template you should refrain from
using tags for other purposes.

The purpose of these workflows and templates is to get you started, creating a quick and easy workflow scaffold. 
Please feel free to change the workflows and template to your own needs and preferences.

## EXAMPLES

### EXAMPLE 1
```
Add-MFGithubScaffold
```

#### DESCRIPTION
Copies the \`.GitHub\` folder from the module's \`resource\` directory to the current module, skipping existing files.

#### OUTPUT
Should have a .github folder, with workflows and a PR template

### EXAMPLE 2
```
Add-MFGithubScaffold -Force
```

#### DESCRIPTION
Copies the \`.GitHub\` scaffold and overwrites existing files in \`.github\` directory

#### OUTPUT
Should have a .github folder, with workflows and a PR template

## PARAMETERS

### -ModulePath
Root path of the module.
Uses the current working directory by default.
Aliased path, but use modulePath as paramname to avoid confusion

```yaml
Type: String
Parameter Sets: (All)
Aliases: Path

Required: False
Position: 1
Default value: $(get-location).path
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigFile
Module Config reference

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: ModuleForgeConfig.xml
Accept pipeline input: False
Accept wildcard characters: False
```

### -GithubFolder
githubFolder

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: .github
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Should we overwrite if files exist?

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

## OUTPUTS

## NOTES
Author: Adrian Andersson

## RELATED LINKS
