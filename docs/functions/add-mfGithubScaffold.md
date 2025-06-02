---
external help file: ModuleForge-help.xml
Module Name: ModuleForge
online version:
schema: 2.0.0
---

# add-mfGithubScaffold

## SYNOPSIS
Initialises a \`.GitHub\` scaffold in a PowerShell module.

## SYNTAX

```
add-mfGithubScaffold [[-modulePath] <String>] [[-configFile] <String>] [[-githubFolder] <String>] [-force]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function copies the \`.GitHub\` folder from a module's resource directory to a target module path.
It maintains the directory structure and only overwrites existing files if the \`-Force\` switch is provided.
This is useful for setting up GitHub workflows, PR templates, and other repository configurations.

## EXAMPLES

### EXAMPLE 1
```
Add-mfGithubScaffold
```

#### DESCRIPTION
Copies the \`.GitHub\` folder from the module's \`resource\` directory to the current module, skipping existing files.

#### OUTPUT
Should have a .github folder, with workflows and a PR template

### EXAMPLE 2
```
Add-mfGithubScaffold -Force
```

#### DESCRIPTION
Copies the \`.GitHub\` scaffold and overwrites existing files in \`.github\` directory

#### OUTPUT
Should have a .github folder, with workflows and a PR template

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

### -githubFolder
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
