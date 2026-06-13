function Get-MFLatestSemverFromBuildManifest
{

    <#
        .SYNOPSIS
            Read the current module version from the compiled manifest in the build folder, returned as a semver object
            
        .DESCRIPTION
            Reads the compiled module manifest from the build folder and returns the current version as a semver object.
            Useful when building locally and needing to determine the current version before calculating the next one.
            Supports an optional module name override for cases where the config file is unavailable.
            
        ------------
        .EXAMPLE
            Get-MFLatestSemverFromBuildManifest
            
            #### DESCRIPTION
            Import build\module\modulemanifest.psd1
            Find the prerelease tag(if present) and module version. I.e. module version 1.1.0 prerelease tag prev003 = 1.1.0-prev003
            
            
            #### OUTPUT
            Major  Minor  Patch  PreReleaseLabel BuildLabel
            -----  -----  -----  --------------- ----------
            1      1      0      prev003
            
        .OUTPUTS
            [semver] - Returns a Semantic Version object
            
        .NOTES
            Author: Adrian Andersson
            
    #>

    [CmdletBinding()]
    [OutputType([semver])]
    PARAM(
        #Root path of the module. Uses the current working directory by default
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [alias('Path')]
        [string]$ModulePath  = $(get-location).path,
        #Name of the ModuleForge config file. Defaults to 'moduleForgeConfig.xml'
        [Parameter(DontShow)]
        [string]$ConfigFile = 'moduleForgeConfig.xml',
        #Override the module name from config. Useful when the config file is unavailable and the module name is already known
        [Parameter(DontShow)]
        [string]$ModuleNameOverride


    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }
    
    process{
        #Do some checks and parsing
        if(! $ModuleNameOverride)
        {
            #Read the config file
            write-verbose 'Importing config file'
            $configPath = join-path -path $ModulePath -ChildPath $ConfigFile

            if(!(test-path $configPath))
            {
                throw "Unable to find config file at: $configPath"
            }
            $config = import-clixml $configPath -erroraction stop
            $moduleName = $config.moduleName
        }else{
            $moduleName = $ModuleNameOverride
        }
        
        
        $buildFolder = Join-Path $ModulePath 'build'
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