---
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# add-mfAzureDevOpsScaffold

## SYNOPSIS
Initialises a \`.azuredevops\` scaffold in a PowerShell module, including YAML Azure DevOps Pipelines for pester testing and build and release

## SYNTAX

```
add-mfAzureDevOpsScaffold [[-modulePath] <String>] [[-configFile] <String>] [[-azdFolder] <String>] [-force]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function will create a '.azuredevops' folder in the moduleforge root (if one does not exist).
It will create 2 Azure DevOps Pipelines files, 1 for Pester testing, 1 for buildAndRelease
It will create 1 Pull Request template.

The buildAndRelease pipeline will use Git Tags to mark versions.
If you stick with this template you should refrain from
using tags for other purposes.

The purpose of these workflows and templates is to get you started, creating a quick and easy workflow scaffold. 
Please feel free to change the workflows and template to your own needs and preferences.

## EXAMPLES

### EXAMPLE 1
```
add-mfAzureDevOpsScaffold
```

#### DESCRIPTION
Copies the \`.azuredevops\` folder from the module's \`resource\` directory to the current module, skipping existing files.

#### OUTPUT
Should have a .azuredevops folder, with pipelines and a PR template

### EXAMPLE 2
```
add-mfAzureDevOpsScaffold -Force
```

#### DESCRIPTION
Copies the \`.azuredevops\` scaffold and overwrites existing files in \`.azuredevops\` directory

#### OUTPUT
Should have a .azuredevops folder, with workflows and a PR template

## PARAMETERS

### -modulePath
Root path of the module.
Uses the current working directory by default.
Aliased path, but use modulePath as paramname to avoid confusion

```yaml
Type: String
Parameter Sets: (All)
Aliases: path

Required: False
Position: 1
Default value: $(get-location).path
Accept pipeline input: False
Accept wildcard characters: False
```

### -configFile
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

### -azdFolder
Azure DevOps folder

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: .azuredevops
Accept pipeline input: False
Accept wildcard characters: False
```

### -force
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
