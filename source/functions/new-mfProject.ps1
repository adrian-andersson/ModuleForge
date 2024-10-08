function new-mfProject
{

    <#
        .SYNOPSIS
            Capture some basic parameters, and create the scaffold file structure
            
        .DESCRIPTION
            The new-mfProject function streamlines the process of creating a scaffold (or basic structure) for a new PowerShell module.
            Whether you’re building a custom module for automation, administration, or any other purpose, this function sets up the initial directory structure, essential files, and variables and properties.
            Think of it as laying the foundation for your module project.
            
        ------------
        .EXAMPLE
            new-mfProject -ModuleName "MyModule" -description "A module for automating tasks" -moduleAuthors "John Doe" -companyName "MyCompany" -moduleTags "automation", "tasks" -projectUri "https://github.com/username/repo" -iconUri "https://example.com/icon.png" -licenseUri "https://example.com/license" -RequiredModules @("Module1", "Module2") -ExternalModuleDependencies @("Dependency1", "Dependency2") -DefaultCommandPrefix "MyMod" -PrivateData @{}

            #### DESCRIPTION
            This example demonstrates how to use the `new-mfProject` function to create a scaffold for a new PowerShell module named "MyModule". 
            It includes a description, authors, company name, tags, project URI, icon URI, license URI, required modules, external module dependencies, default command prefix, and private data.

            #### OUTPUT
            The function will create the directory structure and essential files for the new module "MyModule" in the current working directory. 
            It will also set up the specified metadata and dependencies.
            
            
            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                2024-07-22 - AA
                    - Refactored from Bartender
                    
    #>

    [CmdletBinding()]
    PARAM(
        #The name of your module
        [Parameter(Mandatory)]
        [string]$ModuleName,
        #A description of your module. Is used as the descriptor in the module repository
        [Parameter(Mandatory)]
        [string]$description,
        #Minimum PowerShell version. Defaults to 7.2 as this is the current LTS version
        [Parameter()]
        [version]$minimumPsVersion = [version]::new('7.2.0'),
        #Who are the primary module authors. Can expand later with add-mfmoduleAuthors command
        [Parameter()]
        [string[]]$moduleAuthors,
        #Company Name. If you are building this module for your organisation, this is where it goes
        [Parameter()]
        [string]$companyName,
        #Module Tags. Used to help discoverability and compatibility in package repositories
        [Parameter()]
        [String[]]$moduleTags,
        #Root path of the module. Uses the current working directory by default
        [string]$modulePath = $(get-location).path,
        #Project URI. Will try and read from Git if your using a git repository.
        [Parameter()]
        [string]$projectUri = $(try{git config remote.origin.url}catch{$null}),
        # A URL to an icon representing this module.
        [Parameter()]
        [string]$iconUri,
        #URI to use for your projects license. Will try and use the license file if a projectUri is found
        [Parameter()]
        [string]$licenseUri,
        [Parameter(DontShow)]
        [string]$configFile = 'moduleForgeConfig.xml',
        #Modules that must be imported into the global environment prior to importing this module
        [Parameter()]
        [Object[]]$RequiredModules,
        #Modules that must be imported into the global environment prior to importing this module
        [Parameter()]
        [String[]]$ExternalModuleDependencies,
        [Parameter()]
        [String]$DefaultCommandPrefix,
        [Parameter()]
        [object[]]$PrivateData

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"


        #I'm not sure why I had this in here. Cannot remember.
        if($modulePath -like '*\' -or $modulePath -like '*/' )
        {
            Write-Verbose 'Superfluous \ or / character found at end of modulePath, removing'
            $modulePath = $modulePath.Substring(0,$($modulePath.Length-1))
            Write-Verbose "New path = $modulePath"
        }

        $configPath = join-path -path $modulePath -childpath $configFile

    }
    
    process{

        write-verbose 'Validating Module Path'
        if(!(test-path $modulePath))
        {
            throw "ModulePath: $modulePath not found"
        }

        write-verbose 'Checking for Existing Config'
        if(test-path $configPath)
        {
            throw "Config already found at: $configPath"
        }


        write-verbose 'Create Folder Scaffold'
        add-mfFilesAndFolders -moduleRoot $modulePath

       
        <#
        if($projectUri -and !$licenseUri)
        {
            write-verbose 'Auto-checking for license'
            if(test-path $(join-path -path $modulePath -childPath 'LICENSE'))
            {
                $licenseUri = "$projectUri\LICENSE"
            }
        }
        #>

        #Should we use JSON for this, or CLIXML.
        #The vote from the internet in July 2024 is stick to CLIXML for PowerShell centric projects. So we will do that
        $moduleForgeReference = get-module 'ModuleForge'|Sort-Object version -Descending|Select-Object -First 1
        if(! $moduleForgeReference)
        {
            $moduleForgeReference = get-module -listavailable 'ModuleForge'|Sort-Object version -Descending|Select-Object -First 1
        }

        write-verbose 'Create config file'
        $config = [psCustomObject]@{
            #The params set from this function
            moduleName = $ModuleName
            description = $description
            minimumPsVersion = $minimumPsVersion
            moduleAuthors = [array]$moduleAuthors
            companyName = $companyName
            tags = [array]$moduleTags
            #Some automatic variables
            projectUri = $projectUri
            licenseUri = $licenseUri
            guid = $(new-guid).guid
            moduleforgeVersion = $(if($moduleForgeReference){ $moduleForgeReference.Version.ToString()}else{'n/a'})
            iconUri = $iconUri
            requiredModules = $RequiredModules
            ExternalModuleDependencies = $ExternalModuleDependencies
            DefaultCommandPrefix = $DefaultCommandPrefix
            PrivateData = $PrivateData

        }

        

        write-verbose "Exporting config to: $configPath"
        try{
            $config|export-clixml $configPath
        }catch{
            throw 'Error exporting config'
        }
    }
}