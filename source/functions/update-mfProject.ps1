function update-mfProject
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
            new-mfProject
            
            #### DESCRIPTION
            Line by line of what this example will do
            
            
            #### OUTPUT
            Copy of the output of this line
            
            
            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                2024-07-22 - AA
                    - Refactored from Bartender
                    
    #>

    [CmdletBinding()]
    PARAM(
        #The name of your module
        [Parameter()]
        [string]$ModuleName,
        #A description of your module. Is used as the descriptor in the module repository
        [Parameter()]
        [string]$description,
        #Minimum PowerShell version. Defaults to 7.2 as this is the current LTS version
        [Parameter()]
        [version]$minimumPsVersion,
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
        [Parameter()]
        [string]$projectUri,
        # A URL to an icon representing this module.
        [Parameter()]
        [string]$iconUri,
        #URI to use for your projects license. Will try and use the license file if a projectUri is found
        [Parameter()]
        [string]$licenseUri,
        #Modules that must be imported into the global environment prior to importing this module
        [Parameter]
        [Object[]]$RequiredModules,
        #Modules that must be imported into the global environment prior to importing this module
        [Parameter]
        [String[]]$ExternalModuleDependencies,
        [Parameter]
        [String[]]$DefaultCommandPrefix,
        [Parameter]
        [object[]]$PrivateData,
         #Root path of the module. Uses the current working directory by default
        [string]$modulePath = $(get-location).path,
        [Parameter(DontShow)]
        [string]$configFile = 'moduleForgeConfig.xml'

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        write-verbose 'Testing module path'
        $moduleTest = get-item $modulePath
        if(!$moduleTest){
            throw "Unable to read from $modulePath"
        }

        $modulePath = $moduleTest.FullName
        write-verbose "Building from: $modulePath"

        #Read the config file
        write-verbose 'Importing config file'
        $configPath = join-path -path $modulePath -ChildPath $configFile

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

        if($description)
        {
            write-verbose "Updating Module description from: $($config.description) -> $($description)"
            $config.description = $description
        }

        if($minimumPsVersion)
        {
            write-verbose "Updating Module minimumPsVersion from: $($config.minimumPsVersion.tostring()) -> $($minimumPsVersion.tostring())"
            $config.minimumPsVersion = $minimumPsVersion
        }

        if($moduleAuthors)
        {
            write-verbose "Updating Module moduleAuthors from: $($config.moduleAuthors) -> $($moduleAuthors)"
            $config.moduleAuthors = $moduleAuthors
        }

        if($companyName)
        {
            write-verbose "Updating Module companyName from: $($config.companyName) -> $($companyName)"
            $config.companyName = $companyName
        }

        if($moduleTags)
        {
            write-verbose "Updating Module tags from: $($config.moduleTags) -> $($moduleTags)"
            $config.moduleTags = $moduleTags
        }

        if($projectUri)
        {
            write-verbose "Updating Module projectUri from: $($config.projectUri) -> $($projectUri)"
            $config.projectUri = $projectUri
        }

        if($iconUri)
        {
            write-verbose "Updating Module iconUri from: $($config.iconUri) -> $($iconUri)"
            $config.iconUri = $iconUri
        }

        if($licenseUri)
        {
            write-verbose "Updating Module licenseUri from: $($config.licenseUri) -> $($licenseUri)"
            $config.licenseUri = $licenseUri
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
        try{
            $config|export-clixml $configPath
        }catch{
            throw 'Error exporting config'
        }
    }
}