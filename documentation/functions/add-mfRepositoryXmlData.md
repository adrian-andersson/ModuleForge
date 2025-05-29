---
external help file: ModuleForge-help.xml
Module Name: moduleforge
online version:
schema: 2.0.0
---

# add-mfRepositoryXmlData

## SYNOPSIS
Uncompress a nuspec (Which is just a zip with a different extension), parse the XML, add the URL element for the repository, recreate the ZIP file.

## SYNTAX

```
add-mfRepositoryXmlData [-repositoryUri] <String> [-NugetPackagePath] <String> [[-ExtractionPath] <Object>]
 [-force] [[-branch] <String>] [[-commit] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Some Nuget Package Providers (such as Github Package Manager) require a repository element with a URL attribute in order to be published correctly,
For Githup Packages, this is so it can tie the package back to the actual repository.

At present (March 2024), new-moduleManifest and publish-psresource do not have parameter options that works for this.
This function provides a work-around

------------

## EXAMPLES

### EXAMPLE 1
```
add-repositoryXmlData -RepositoryUri 'https://github.com/gituser/example' -NugetPackagePath = 'c:\example\module.1.2.3-beta.4.nupkg -branch 'main' -commit '1234123412341234Y'
```

#### DESCRIPTION
Unpack module.1.2.3-beta.4.nupkg to a temp location, open the NUSPEC xml and append a repository element with URL, Type, Branch and Commit attributes, repack the nupkg

## PARAMETERS

### -branch
What branch to add to NUSPEC (Optional)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -commit
What commit to add to NUSPEC (Optional)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExtractionPath
TempExtractionPath

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: $(join-path -path ([System.IO.Path]::GetTempPath()) -childpath 'tempUnzip')
Accept pipeline input: False
Accept wildcard characters: False
```

### -force
Use force to ignore remove prompt

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

### -NugetPackagePath
Path to the actual file in the repository, should be something like C:\Users\{UserName}\AppData\Local\Temp\LocalTestRepository\{ModuleName}.{ModuleVersion}.nupkg

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
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

### -repositoryUri
RepositoryUri

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Author: Adrian Andersson


Changelog:

    2024-08-08 - AA
        - Initial Attempt

    2024-08-28 - AA
        - Need to fix the xml space, I put in type but it should be repository

## RELATED LINKS
