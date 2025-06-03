function get-mfLatestSemverFromBuildManifest
{

    <#
        .SYNOPSIS
            If you are manually building, and you have access to the \build folder, you can use this to get the next semver
            
        .DESCRIPTION
            Detailed Description
            
        ------------
        .EXAMPLE
            get-mfLatestSemverFromBuildManifest
            
            #### DESCRIPTION
            Import build\module\modulemanifest.psd1
            Find the prerelease tag(if present) and module version. I.e. module version 1.1.0 prerelease tag prev003 = 1.1.0-prrev003
            
            
            #### OUTPUT
            Major  Minor  Patch  PreReleaseLabel BuildLabel
            -----  -----  -----  --------------- ----------
            1      1      0      prev003
            
        .OUTPUTS
            [semver] - Returns a Semantec Version object    
            
        .NOTES
            Author: Adrian Andersson
            
    #>

    [CmdletBinding()]
    PARAM(
        #Root path of the module. Uses the current working directory by default
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [alias('modulePath')]
        [string]$path  = $(get-location).path,
        [Parameter(DontShow)]
        [string]$configFile = 'moduleForgeConfig.xml',
        [Parameter(DontShow)]
        [string]$moduleNameOverride


    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }
    
    process{
        #Do some checks and parsing
        if(! $moduleNameOverride)
        {
            #Read the config file
            write-verbose 'Importing config file'
            $configPath = join-path -path $path -ChildPath $configFile

            if(!(test-path $configPath))
            {
                throw "Unable to find config file at: $configPath"
            }
            $config = import-clixml $configPath -erroraction stop
            $moduleName = $config.moduleName
        }else{
            $moduleName = $moduleNameOverride
        }
        
        
        $buildFolder = Join-Path $path 'build'
        write-verbose "build folder: $buildFolder"
        $moduleFolder = join-path $buildFolder $moduleName
        $manifestFile = get-childItem -Path $moduleFolder -Filter "$moduleName.psd1"
        if(!$manifestFile){
            throw 'Manifest file not found in build folder'
        }else{
            write-verbose "Found manifest at $($manifestFile.FullName)"
            $ManifestPath = $manifestFile.fullname
        }

        #Actual processing

        write-verbose 'Try and import manifest as datafile'
        try{
            $manifest = Import-PowerShellDataFile -Path $ManifestPath
        }catch{
            throw 'Manifest was found but unable to import as PSDataFile'
        }

        write-verbose 'Get Module Version'
        $moduleVersion = $manifest.ModuleVersion
        if(!$moduleVersion){
            throw 'Err: Unable to get moduleVersion'
        }else{
            write-verbose "Found Version: $moduleVersion"
        }

        write-verbose 'Check for PreRelease'
        $preRelease = $manifest.PrivateData.PSData.Prerelease
        if($preRelease)
        {
            write-verbose "Found Prerelease tag: $($preRelease)"
            $versionString = "$($moduleVersion)-$($preRelease)"
        }else{
            write-verbose 'No Prerelease was found'
            $versionString = $moduleVersion
        }

        write-verbose 'Attempt to make semver from string'
        try{
            [semver]::new($versionString)
        }catch{
            throw "Err: Could not convert $versionString to semver object"
        }
    }
    
}