function get-mfNextSemver
{

    <#
    .SYNOPSIS
        Increments the version of a Semantic Version (SemVer) object.

    .DESCRIPTION
        The `get-mfNextSemver` function takes a Semantic Version (SemVer) object as input and increments the version based on the 'increment' parameter. It can handle major, minor, and patch increments. The function also handles pre-release versions and allows the user to optionally override the pre-release label.

    .EXAMPLE
        $version = [SemVer]::new('1.0.0')
        get-mfNextSemver -version $version -increment 'Minor' -prerelease

        #### DESCRIPTION
        This example takes a SemVer object with version '1.0.0', increments the minor version, and adds a pre-release tag. The output will be '1.1.0-prerelease.1'.

        #### OUTPUT
        '1.1.0-prerelease.1'

    .EXAMPLE
        $version = [SemVer]::new('2.0.0-prerelease.1')
        get-mfNextSemver -version $version -increment 'Major'

        #### DESCRIPTION
        This example takes a SemVer object with version '2.0.0-prerelease.1', increments the major version, and removes the pre-release tag because the 'prerelease' switch is not set. The output will be '3.0.0'.

        #### OUTPUT
        '3.0.0'

    .NOTES
        Author: Adrian Andersson

        Changelog:

            2024-08-10 - AA
                - First attempt at incrementing the Semver
                   
    #>

    [CmdletBinding()]
    PARAM(
        #Semver Version
        [Parameter(Mandatory)]
        [SemVer]$version,

        #What are we incrementing
        [Parameter()]
        [ValidateSet('Major','Minor','Patch')]
        [string]$increment,

        #Is this a prerelease
        [Parameter()]
        [switch]$prerelease,

        #Optional override the prerelease label. If not supplied will use 'prerelease'
        [Parameter()]
        [string]$preReleaseLabel
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $defaultPrereleaseLabel = 'prerelease'

        if (-not $increment -and -not $prerelease) {
            throw 'At least one of "increment" parameter or "prerelease" switch should be supplied.'
        }
    }
    
    process{
        # Increment the version based on the 'increment' parameter
        switch ($increment) {
            'Major' { 
                #$nextVersion = $version.IncrementMajor()
                $nextVersion = [semver]::new($version.Major+1,0,0)
                write-verbose "Incrementing Major Version to: $($nextVersion.tostring())"
             }
            'Minor' { 
                $nextVersion = [semver]::new($version.Major,$version.minor+1,0)
                write-verbose "Incrementing Minor Version to: $($nextVersion.tostring())"
            }
            'Patch' { 
                $nextVersion = [semver]::new($version.Major,$version.minor,$version.Patch+1)
                write-verbose "Incrementing Patch Version to: $($nextVersion.tostring())"
            }
        }

        # Handle pre-release versions
        if($prerelease -and !$nextVersion -and $version.PreReleaseLabel)
        {
            #This scenario indicates version supplied is already a prerelease, and what we want to do is increment the prerelease version
            write-verbose 'Incrementing Prerelease Version'
            $currentPreReleaseSplit = $version.PreReleaseLabel.Split('.')
            $currentpreReleaseLabel = $currentPreReleaseSplit[0]
            if(!$preReleaseLabel -or ($currentpreReleaseLabel -eq $preReleaseLabel)){
                write-verbose 'No change to prerelease label'
                $nextPreReleaseLabel = $currentpreReleaseLabel
                $currentPreReleaseInt = [int]$currentPreReleaseSplit[1]
                $nextPrerelease = $currentPreReleaseInt+1
                

            }else{
                write-verbose 'Prerelease label changed. Resetting prerelease version to 1'
                $nextPreReleaseLabel = $preReleaseLabel
                $nextPreRelease = 1
            }
            
            $nextVersionString = "$($version.major).$($version.minor).$($version.patch)-$($nextPreReleaseLabel).$($nextPrerelease)"
            $nextVersion = [semver]::New($nextVersionString)
            write-verbose "Next Prerelease will be: $($nextVersion.ToString())"
            
        }elseIf($prerelease -and $nextVersion)
        {
            write-verbose 'Need to tag incremented version as PreRelease'
            #This scenario indicates we have incremented a major,minor or patch, and need to start a fresh prerelease
            if(!$preReleaseLabel){
                $nextPreReleaseLabel = $defaultPrereleaseLabel
            }else{
                $nextPreReleaseLabel = $preReleaseLabel
            }

            $nextVersionString = "$($nextVersion.major).$($nextVersion.minor).$($nextVersion.patch)-$($nextPreReleaseLabel).1"
            $nextVersion = [semver]::New($nextVersionString)
            write-verbose "Next Prerelease will be: $($nextVersion.ToString())"
        }

        return $nextVersion


    }
    
}