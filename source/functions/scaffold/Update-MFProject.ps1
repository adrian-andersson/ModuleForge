function Update-MFProject
{

    <#
        .SYNOPSIS
            Update the parameters of a moduleForge project
            
        .DESCRIPTION
            This command allows you to update any of the parameters that were saved with the new-mfProject function without
            having to recreate the whole project file from scratch.
            
        ------------
        .EXAMPLE
            Update-MFProject -ModuleName "UpdatedModule" -Description "An updated description for the module" -ModuleAuthors "Jane Doe" -CompanyName "UpdatedCompany" -ModuleTags "updated", "module" -ProjectUri "https://github.com/username/updated-repo" -IconUri "https://example.com/updated-icon.png" -LicenseUri "https://example.com/updated-license" -RequiredModules @("UpdatedModule1", "UpdatedModule2") -ExternalModuleDependencies @("UpdatedDependency1", "UpdatedDependency2") -DefaultCommandPrefix "UpdMod" -PrivateData @{}

            #### DESCRIPTION
            This example demonstrates how to use the `Update-MFProject` function to update multiple parameters of an existing module project. 
            It updates the module name, description, authors, company name, tags, project URI, icon URI, license URI, required modules, external module dependencies, default command prefix, and private data.

            #### OUTPUT
            The function will update the specified parameters in the module project configuration file.
            
        .EXAMPLE
            Update-MFProject -ModuleName "UpdatedModule" -Description "An updated description for the module"

            #### DESCRIPTION
            This example demonstrates how to use the `Update-MFProject` function to update only the module name and description of an existing module project. 
            It leaves all other parameters unchanged.

            #### OUTPUT
            The function will update the module name and description in the module project configuration file.   
            
        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding(SupportsShouldProcess)]
    PARAM(
        #The name of your module
        [Parameter()]
        [string]$ModuleName,
        #A description of your module. Is used as the descriptor in the module repository
        [Parameter()]
        [string]$Description,
        #Minimum PowerShell version. Defaults to 7.2 as this is the current LTS version
        [Parameter()]
        [version]$MinimumPsVersion,
        #Who are the primary module authors. Can expand later with add-mfmoduleAuthors command
        [Parameter()]
        [string[]]$ModuleAuthors,
        #Company Name. If you are building this module for your organisation, this is where it goes
        [Parameter()]
        [string]$CompanyName,
        #Module Tags. Used to help discoverability and compatibility in package repositories
        [Parameter()]
        [String[]]$ModuleTags,
        #Source Code Repository to use, i.e. your repositories github/azure devops uri
        [Parameter()]
        [string]$ProjectUri,
        # A URL to an icon representing this module.
        [Parameter()]
        [string]$IconUri,
        #URI to use for your projects license. Will try and use the license file if a projectUri is found
        [Parameter()]
        [string]$LicenseUri,
        #Modules that must be imported into the global environment prior to importing this module
        [Parameter()]
        [Object[]]$RequiredModules,
        #Modules that this module depends on but does not bundle - the consumer is expected to supply them
        [Parameter()]
        [String[]]$ExternalModuleDependencies,
        #If you are specifying a Default Command Prefix via your manifest, this will update that prefix
        [Parameter()]
        [String]$DefaultCommandPrefix,
        #If you have any additional Private Data you want to add to your module manifest, add it here. Must be a hashtable - it is forwarded directly to New-ModuleManifest, which requires a hashtable
        [Parameter()]
        [hashtable]$PrivateData,
        #Root path of the module. Uses the current working directory by default
        [Parameter()]
        [Alias('path')]
        [string]$ModulePath = $(get-location).path,
        #Module Config File
        [Parameter(DontShow)]
        [string]$ConfigFile = 'moduleForgeConfig.xml'

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        write-verbose 'Testing module path'
        $moduleTest = get-item $ModulePath
        if(!$moduleTest){
            throw "Unable to read from $ModulePath"
        }

        $ModulePath = $moduleTest.FullName
        write-verbose "update module config in: $ModulePath"

        #Read the config file
        write-verbose 'Importing config file'
        $configPath = join-path -path $ModulePath -ChildPath $ConfigFile

        if(!(test-path $configPath))
        {
            throw "Unable to find config file at: $configPath"
        }

        $config = import-clixml $configPath -erroraction stop
        

    }
    
    process{

        if($ModuleName)
        {
            write-verbose "Updating Module name from: $($config.moduleName) -> $($moduleName)"
            $config.moduleName = $moduleName
        }

        if($Description)
        {
            write-verbose "Updating Module description from: $($config.description) -> $($Description)"
            $config.description = $Description
        }

        if($MinimumPsVersion)
        {
            write-verbose "Updating Module minimumPsVersion from: $($config.minimumPsVersion.tostring()) -> $($MinimumPsVersion.tostring())"
            $config.minimumPsVersion = $MinimumPsVersion
        }

        if($ModuleAuthors)
        {
            write-verbose "Updating Module moduleAuthors from: $($config.moduleAuthors) -> $($ModuleAuthors)"
            $config.moduleAuthors = $ModuleAuthors
        }

        if($CompanyName)
        {
            write-verbose "Updating Module companyName from: $($config.companyName) -> $($CompanyName)"
            $config.companyName = $CompanyName
        }

        if($ModuleTags)
        {
            write-verbose "Updating Module tags from: $($config.tags) -> $($ModuleTags)"
            $config.tags = $ModuleTags
        }

        if($ProjectUri)
        {
            write-verbose "Updating Module projectUri from: $($config.projectUri) -> $($ProjectUri)"
            $config.projectUri = $ProjectUri
        }

        if($IconUri)
        {
            write-verbose "Updating Module iconUri from: $($config.iconUri) -> $($IconUri)"
            $config.iconUri = $IconUri
        }

        if($LicenseUri)
        {
            write-verbose "Updating Module licenseUri from: $($config.licenseUri) -> $($LicenseUri)"
            $config.licenseUri = $LicenseUri
        }
        if($RequiredModules)
        {
            write-verbose "Updating Module RequiredModules from: $($config.RequiredModules|convertTo-json -depth 4)`n`n`t ->`n $($RequiredModules|convertTo-json -depth 4)"
            $config.RequiredModules = $RequiredModules
        }

        if($ExternalModuleDependencies)
        {
            write-verbose "Updating Module ExternalModuleDependencies from: $($config.ExternalModuleDependencies -join '; ') -> $($ExternalModuleDependencies -join '; ')"
            $config.ExternalModuleDependencies = $ExternalModuleDependencies
        }

        if($DefaultCommandPrefix)
        {
            write-verbose "Updating Module DefaultCommandPrefix from: $($config.DefaultCommandPrefix) -> $($DefaultCommandPrefix)"
            $config.DefaultCommandPrefix = $DefaultCommandPrefix
        }

        if($PrivateData)
        {
            write-verbose "Updating Module PrivateData from: $($config.PrivateData|convertTo-json -depth 4)`n`n`t ->`n $($PrivateData|convertTo-json -depth 4)"
            $config.PrivateData = $PrivateData
        }

        write-verbose "Exporting config to: $configPath"
        if($PSCmdlet.ShouldProcess($configPath, 'Update ModuleForge project configuration'))
        {
            try{
                $config|export-clixml $configPath
            }catch{
                throw 'Error exporting config'
            }
        }
    }
}