function Invoke-MFBuildPreRelease
{

    <#
        .SYNOPSIS
            Build a pre-release version of the ModuleForge project.

        .DESCRIPTION
            Locates the ModuleForge project root by searching for moduleForgeConfig.xml,
            reads the latest version from the build manifest, increments the pre-release
            label, and calls Build-MFProject.

            Combines Get-MFLatestSemverFromBuildManifest, Get-MFNextSemver, and Build-MFProject
            into a single convenient command for local pre-release builds.

        .EXAMPLE
            Invoke-MFBuildPreRelease

            #### DESCRIPTION
            Detect the project root from the current directory, calculate the next pre-release
            version from the existing build manifest, and build the module.

        .EXAMPLE
            Invoke-MFBuildPreRelease -ModulePath 'C:\Projects\MyModule'

            #### DESCRIPTION
            Build a pre-release from an explicit project root path.

        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding()]
    PARAM(
        #Root path of the module. Searches upward from the current working directory if not supplied
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [alias('Path')]
        [string]$ModulePath,
        #Name of the ModuleForge config file
        [Parameter(DontShow)]
        [string]$ConfigFile = 'moduleForgeConfig.xml'
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }
    process{
        $getRootSplat = @{ConfigFile = $ConfigFile}
        if($ModulePath){$getRootSplat.ModulePath = $ModulePath}
        $root = Get-MFProjectRoot @getRootSplat

        write-verbose "Project root: $root"
        $currentVersion = Get-MFLatestSemverFromBuildManifest -ModulePath $root -ConfigFile $ConfigFile
        write-verbose "Current version: $($currentVersion.ToString())"
        $nextVersion = Get-MFNextSemver -Version $currentVersion -PreRelease
        write-verbose "Next version: $($nextVersion.ToString())"
        Build-MFProject -Version $nextVersion -ModulePath $root -ConfigFile $ConfigFile
    }
}