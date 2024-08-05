
$localRepoPath = 'C:\nuget\publish\'
$localRepoPathAsUri = 
if(!(test-path $localRepoPath))
{
    New-Item -ItemType directory -Path $localRepoPath
}else{
    write-warning 'Folder already exists'
}

$repoName = 'nuget-local'

if(!(Get-PSResourceRepository $repoName))
{
    Register-PSResourceRepository -Name $repoName -URL $localRepoPath
}

<#
With this content:
> ls $localRepoPath
Directory: C:\nuget\publish

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d----           8/12/2021  5:17 PM                winops_tools.1.0.12
-a---           8/12/2021  5:03 PM          67736 winops_tools.1.0.12.nupkg

#This works: 

> Find-PSResource -Repository $repoName -Name winops_tools 

Name         Version  Prerelease Repository  Description
----         -------  ---------- ----------  -----------
winops_tools 1.0.12.0            nuget-local A place to store windows operations tools


#Note: Only the nupkg file is required in the file repo, since thats whats read here.
# The folder is me experimenting


#>


<#Publish PSResource Syntax - static ref

NAME
    Publish-PSResource

SYNOPSIS
    {{ Fill in the Synopsis }}


SYNTAX
    Publish-PSResource 
    [-Path] <System.String> 
    [-APIKey <System.String>] 
    [-Credential <System.Management.Automation.PSCredential>] 
    [-DestinationPath <System.String>] 
    [-Exclude <System.String[]>] 
    [-IconUrl <System.String>] 
    [-LicenseUrl <System.String>] 
    [-Nuspec <System.String>] 
    [-ProjectUrl <System.String>]  
    [-ReleaseNotes <System.String>] 
    [-Repository <System.String>] 
    [-SkipDependenciesCheck] 
    [-Tags <System.String[]>] 
    [-Confirm] 
    [-WhatIf] 
    [<CommonParameters>]      

    Publish-PSResource 
    [-APIKey <System.String>] 
    [-Credential <System.Management.Automation.PSCredential>] 
    [-DestinationPath <System.String>] 
    [-Exclude <System.String[]>] 
    [-IconUrl <System.String>] 
    [-LicenseUrl <System.String>] 
    -LiteralPath <System.String> [-Nuspec <System.String>] [-ProjectUrl
    <System.String>] [-ReleaseNotes <System.String>] [-Repository <System.String>] [-SkipDependenciesCheck] [-Tags <System.String[]>] [-Confirm] [-WhatIf]
    [<CommonParameters>]

    Publish-PSResource [-APIKey <System.String>] [-Credential <System.Management.Automation.PSCredential>] [-DestinationPath <System.String>] [-Exclude
    <System.String[]>] [-IconUrl <System.String>] [-LicenseUrl <System.String>] [-ProjectUrl <System.String>] [-ReleaseNotes <System.String>] [-Repository
    <System.String>] [-SkipDependenciesCheck] [-Tags <System.String[]>] [-Confirm] [-WhatIf] [<CommonParameters>]

    Publish-PSResource [-APIKey <System.String>] [-Credential <System.Management.Automation.PSCredential>] [-DestinationPath <System.String>] [-Exclude
    <System.String[]>] [-Nuspec <System.String>] [-Repository <System.String>] [-SkipDependenciesCheck] [-Confirm] [-WhatIf] [<CommonParameters>]


#>


$publishSplat = @{
    Path = 'C:\users\adrian.andersson\git\aa-powershell-test\aa-powershell-test'
    Repository = $repoName
    #ProjectUrl = 'https://github.com/domain-platform-engineering/aa-powershell-test'
    verbose = $true
    debug = $true
    #APIKey = '123'
    confirm = $false
    #ReleaseNotes = 'ReleaseNotes'

    
}

<#Notes on publish

Publishing still failes on folder version
Need to move the module files into the version folder

#ProjectUrl does not seem to do anything
#ReleaseNotes also not working


#There is an option to provide a NUSPEC.... _maybe_




Heres an example:

Would be useful if the params were even there
#>
$CustomNuspec = @'
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2012/06/nuspec.xsd">
  <metadata>
    <id>aa-powershell-test</id>
    <version>1.0.0</version>
    <authors>Adrian.Andersson</authors>
    <owners>Domain Group</owners>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <description>Testing PowerShellGet 3 and Github Packages</description>
    <copyright>2023 Domain Group</copyright>
    <tags>PSModule</tags>
    <repository url="https://github.com/domain-platform-engineering/aa-powershell-test" />
  </metadata>
</package>
'@


Publish-PSResource @publishSplat 




<#

-APIKey <System.String>
    {{ Fill APIKey Description }}

    Required?                    false
    Position?                    named
    Default value                None
    Accept pipeline input?       False
    Accept wildcard characters?  false


-Credential <System.Management.Automation.PSCredential>
    {{ Fill Credential Description }}

    Required?                    false
    Position?                    named
    Default value                None
    Accept pipeline input?       False
    Accept wildcard characters?  false


-DestinationPath <System.String>
    {{ Fill DestinationPath Description }}

    Required?                    false
    Position?                    named
    Default value                None
    Accept pipeline input?       False
    Accept wildcard characters?  false


-Exclude <System.String[]>
    {{ Fill Exclude Description }}

    Required?                    false
    Position?                    named
    Default value                None
    Accept pipeline input?       False
    Accept wildcard characters?  false


-IconUrl <System.String>
    {{ Fill IconUrl Description }}

    Required?                    false
    Position?                    named
    Default value                None
    Accept pipeline input?       False
    Accept wildcard characters?  false


-LicenseUrl <System.String>
    {{ Fill LicenseUrl Description }}

    Required?                    false
    Position?                    named
    Default value                None
    Accept pipeline input?       False
    Accept wildcard characters?  false


-LiteralPath <System.String>
    {{ Fill LiteralPath Description }}

    Required?                    true
    Position?                    named
    Default value                None
    Accept pipeline input?       True (ByPropertyName, ByValue)
    Accept wildcard characters?  false


-Nuspec <System.String>
    {{ Fill Nuspec Description }}

    Required?                    false
    Position?                    named
    Default value                None
    Accept pipeline input?       False
    Accept wildcard characters?  false


-Path <System.String>
    {{ Fill Path Description }}

    Required?                    true
    Position?                    0
    Default value                None
    Accept pipeline input?       True (ByPropertyName, ByValue)
    Accept wildcard characters?  false


-ProjectUrl <System.String>
    {{ Fill ProjectUrl Description }}

    Required?                    false
    Position?                    named
    Default value                None
    Accept pipeline input?       False
    Accept wildcard characters?  false


-ReleaseNotes <System.String>
    {{ Fill ReleaseNotes Description }}
    
    Required?                    false
    Position?                    named
    Default value                None
    Accept pipeline input?       False
    Accept wildcard characters?  false


-Repository <System.String>
    {{ Fill Repository Description }}

    Required?                    false
    Position?                    named
    Default value                None
    Accept pipeline input?       False
    Accept wildcard characters?  false


-SkipDependenciesCheck <System.Management.Automation.SwitchParameter>
    {{ Fill SkipDependenciesCheck Description }}

    Required?                    false
    Position?                    named
    Default value                False
    Accept pipeline input?       False
    Accept wildcard characters?  false


-Tags <System.String[]>
    {{ Fill Tags Description }}

    Required?                    false
    Position?                    named
    Default value                None
    Accept pipeline input?       False
    Accept wildcard characters?  false


-Confirm <System.Management.Automation.SwitchParameter>
    Prompts you for confirmation before running the cmdlet.

    Required?                    false
    Position?                    named
    Default value                False
    Accept pipeline input?       False
    Accept wildcard characters?  false


-WhatIf <System.Management.Automation.SwitchParameter>
    Shows what would happen if the cmdlet runs. The cmdlet is not run.

    Required?                    false
    Position?                    named
    Default value                False
    Accept pipeline input?       False
    Accept wildcard characters?  false

#>



