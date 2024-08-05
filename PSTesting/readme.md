# A test repository

## What is this
A test repository for AA to play and try and get PowerShell Modules, compiled and working  with PowerShellGet 3.0.12 and GitHub Packages
> PowerShellGet Source: https://github.com/PowerShell/PowerShellGet

> Github Packages Doc Source: https://docs.github.com/en/packages

There are some challenges with this, namely stuff like [this](https://stackoverflow.com/questions/60008539/use-github-package-registry-as-a-powershell-package-repository) stack-overflow concern


### The key points though:

 - `PowerShellGet < 3` does not support NuGet v3, but Github Packages _ONLY_ supports Nuget v3 API calls
 - The `PowerShellGet 3` Beta supports Nuget v3, but it has other problems and is still pretty beta-like
 - Github Packages _expects_ a Package Repository in the Nuget XML. This is not supported in Publish-Module, but _does seem_ to be supported in Publish-PSResource
 - Our PowerShell Framework module uses `PowerShellGet 2` and not the `PowerShellGet 3`.
 - The Commands for `PowerShellGet 2` are completely different to `PowerShellGet 3`


 For reference, here is a comparison of the commands


### PowerShellGet 3 Beta:
```PowerShell
Name                            Version
----                            -------
Find-PSResource                 3.0.12
Get-PSResource                  3.0.12
Get-PSResourceRepository        3.0.12
Install-PSResource              3.0.12
Publish-PSResource              3.0.12
Register-PSResourceRepository   3.0.12
Save-PSResource                 3.0.12
Set-PSResourceRepository        3.0.12
Uninstall-PSResource            3.0.12
Unregister-PSResourceRepository 3.0.12
Update-PSResource               3.0.12

 ```

### PowerShellGet 2:
```PowerShell
Name                            Version
----                            -------
Find-Command                    2.2.5
Find-DscResource                2.2.5
Find-Module                     2.2.5
Find-RoleCapability             2.2.5
Find-Script                     2.2.5
Get-CredsFromCredentialProvider 2.2.5
Get-InstalledModule             2.2.5
Get-InstalledScript             2.2.5
Get-PSRepository                2.2.5
Install-Module                  2.2.5
Install-Script                  2.2.5
New-ScriptFileInfo              2.2.5
Publish-Module                  2.2.5
Publish-Script                  2.2.5
Register-PSRepository           2.2.5
Save-Module                     2.2.5
Save-Script                     2.2.5
Set-PSRepository                2.2.5
Test-ScriptFileInfo             2.2.5
Uninstall-Module                2.2.5
Uninstall-Script                2.2.5
Unregister-PSRepository         2.2.5
Update-Module                   2.2.5
Update-ModuleManifest           2.2.5
Update-Script                   2.2.5
Update-ScriptFileInfo           2.2.5

 ```

## Summary and Objectives
 In short, there is a _HEAP_ of things we need to test out.

 - Can we publish a module to `Nuget Packages` with `PowerShellGet 3 Beta` command `Publish-PSResource`
 - How do we register a `Nuget Packages` feed with `Register-PSResourceRepository`
 - Are there any changes in the Dependency chain
 - Can we refactor `Bartender` to be a `Github Actions` pipeline
 - What other gotcha's do we have to deal with


## Adrian's ranting about PowerShellGet section

Gotta say, I've never seen anything this rubbish from Microsoft in the PowerShell Space.

This command lists the syntax

```PowerShell
get-help -Name Publish-PSResource


SYNTAX
    Publish-PSResource [-Path] <System.String> [-APIKey <System.String>] [-Credential <System.Management.Automation.PSCredential>] [-DestinationPath
    <System.String>] [-Exclude <System.String[]>] [-IconUrl <System.String>] [-LicenseUrl <System.String>] [-Nuspec <System.String>] [-ProjectUrl <System.String>]  
    [-ReleaseNotes <System.String>] [-Repository <System.String>] [-SkipDependenciesCheck] [-Tags <System.String[]>] [-Confirm] [-WhatIf] [<CommonParameters>]    

```

However, _THE ONLY PARAMETERS ACTUALLY DEFINED IN THE DOTNET CODE_ [here](https://github.com/PowerShell/PowerShellGet/blob/f22c1319106fdf45a38f691bfc45dcbba4080bf6/src/code/PublishPSResource.cs#L30) Are:

- ApiKey 
- Repository 
- Path
- DestinationPath
- Credential 
- SkipDependenciesCheck 
- Proxy
- ProxyCredential 


This is validated with tab autocompletion as well (Excluding Common Params).

This means that the following params aren't _actually_ parameters as per the documentation:

 - Exclude
 - IconUrl
 - LicenseUrl
 - Nuspec
 - ProjectURl
 - ReleaseNotes


 At the very least, the NuSpec Param would be useful so I could manually write a nuspec, and include the GH repository

 As a result, I only can get a zipped up nuspec without any way to directly inject the repository XML

 The workaround would be to:

  - Make the nuspec
  - Unzip it
  - Add the Github repository to the XML
  - Zip it back up


Also pretty frustrated that publish-psresource cannot run in a proper folder version

So many little crapy things I need to code around just to get this working


I cannot believe this has been going on for 2 1/2 years at this point.


## Adrian's ranting about Nuget Packages





UPDATE: 

As per [this](https://github.com/PowerShell/PowerShellGet/issues/163)  issue on github, its possible to get this to sort of work
First you need to put the URI as `https://nuget.pkg.github.com/ORG/index.json`. Since I ommited the index.json it wasnt working, but with that there it works, sort of:

 - Find module works, provided that you know the exact name of your module.
    - Wildcards don't work.
    - If you dont provide a name you get a metadata error `FindHelper SearchAsync: error receiving package: Failed to retrieve metadata from source 'https://nuget.pkg.github.com/domain-platform-engineering/query?q=*&skip=0&take=6000&prerelease=false&semVerLevel=2.0.0'`
    - Need to make sure all dependencies are also in the same org
    - 
 - Doesn't solve the problem of publishing
    - I guess I can try and code around this
    - Pretty freakin stupid though that this is a problem...

You can get search to work with a RestMethod, maybe I should write a wrapper function or something, seems doable


### Previously on _Adrian Rants_

So turns out we are dead in the water for using the PowerShellGet module and the standard command line for managing PowerShell modules
PowerShellGet 3 does not use Nuget 3 to find packages, instead uses the legacy v2 syntax and paths. Since these don't exist in Github Packages, the only way would be to write my own PowerShell module for using v3 at this time. Means I have to handle the whole updating, pathing etc.... what a mess

It's not really Githubs fault, but it was a real rabbit hole for investigating what works and what doesn't.


At this time I think it might be easier to find a stand-alone private repo or something...

So, even _IF_ I automated the package creation, cannot easily manage the install part.... so sad and frustrating


```
Find-PSResource -Repository DomainPlatformEngineering -Name aa-powershell-test -Credential $cred
VERBOSE: FindHelper MetadataAsync: error receiving package: Failed to fetch results from V2 feed at 'https://nuget.pkg.github.com/domain-platform-engineering/FindPackagesById()?id='aa-powershell-test'&semVerLevel=2.0.0' with following message : Response status code does not indicate success: 404 (Not Found).
```

## Updates and Log

### 2022-02-02:




Got a custom find function working well. Seems to be much better than the built in version

![Better Find](./img/itsWorking.png "tada")

 Found another github issue though. This time with the PowerShellGet `save-psresource` and `install-psresource` functions. They don't take pipeline data... I dont know why. I'll have to circle back and raise these oversights as issues on the github repo.

I can easily enough code around that, but its one more thing I shouldn't have to.

![Future PowerShelf](./img/whynopipeline.png "Why MS, Why!")

I've also put some loose planning ideas [here](./powershelf.md)

Finally, I've started fleshing out a public module. I'll be testing most of my code in that Repo is [here](https://github.com/DomainGroupOSS/githubpwshmodules)

It's currently private, but after we get this further along, I think I want this in PSGallery and the git repo public. So that I can easily pull the module down anywhere (including in GH Actions) and just execute the functions.



## Github Packages Nuget Resources Reference:

```PowerShell

@id                                                               @type                           comment
---                                                               -----                           -------
https://nuget.pkg.github.com/domain-platform-engineering/download PackageBaseAddress/3.0.0        Get package content (.nupkg).
https://nuget.pkg.github.com/domain-platform-engineering/query    SearchQueryService              Filter and search for packages by keyword.
https://nuget.pkg.github.com/domain-platform-engineering/query    SearchQueryService/3.0.0-beta   Filter and search for packages by keyword.
https://nuget.pkg.github.com/domain-platform-engineering/query    SearchQueryService/3.0.0-rc     Filter and search for packages by keyword.
https://nuget.pkg.github.com/domain-platform-engineering          PackagePublish/2.0.0            Push and delete (or unlist) packages.
https://nuget.pkg.github.com/domain-platform-engineering          RegistrationsBaseUrl            Get package metadata.
https://nuget.pkg.github.com/domain-platform-engineering          RegistrationsBaseUrl/3.0.0-beta Get package metadata.
https://nuget.pkg.github.com/domain-platform-engineering          RegistrationsBaseUrl/3.0.0-rc   Get package metadata.
```
