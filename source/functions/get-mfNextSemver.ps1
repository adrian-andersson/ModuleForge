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

            2024-08-24 - AA
                - Have discovered that PSGallery only supports SemVer v1. So need to remove the prerelese Version
                - I think we need to change our default label to PRE, and have a 3 digit number afterwards to indicate the prerelease number
                    - I.e. 1.0.0-PREv001, 1.0.0-PREv002, 1.0.1-PREv001

            2024-08-26 - AA
                - Added functionality to be able to drop pre-release tag
    #>

    [CmdletBinding(DefaultParameterSetName='default')]
    PARAM(
        #Semver Version
        [Parameter(Mandatory,ParameterSetName='default')]
        [Parameter(Mandatory,ParameterSetName='preRelease')]
        [SemVer]$version,

        #What are we incrementing
        [Parameter(ParameterSetName='default')]
        [Parameter(ParameterSetName='preRelease')]
        [ValidateSet('Major','Minor','Patch')]
        [string]$increment,

        #Is this a prerelease
        [Parameter(ParameterSetName='preRelease')]
        [switch]$prerelease,

        #Is this a prerelease
        [Parameter(ParameterSetName='default')]
        [switch]$stableRelease,

        #Optional override the prerelease label. If not supplied will use 'prerelease'
        [Parameter(ParameterSetName='preRelease')]
        [Parameter(ParameterSetName='Initial')]
        [string]$preReleaseLabel,

        #Is this the initial prerelease
        [Parameter(ParameterSetName='Initial')]
        [switch]$initialPreRelease

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $defaultPrereleaseLabel = 'PRE'

        if (-not $increment -and -not $prerelease -and -not $initialPreRelease -and -not $stableRelease) {
            throw 'At least one of "increment", parameter or "stableRelease", "prerelease", "initialPreRelease" switch should be supplied.'
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
            $currentPreReleaseSplit = $version.PreReleaseLabel.Split('v')
            $currentpreReleaseLabel = $currentPreReleaseSplit[0]
            write-verbose "Current PreRelease Label: $currentpreReleaseLabel"
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
            
            $nextVersionString = "$($version.major).$($version.minor).$($version.patch)-$($nextPreReleaseLabel)v$('{0:d3}' -f $nextPrerelease)"
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

            $nextVersionString = "$($nextVersion.major).$($nextVersion.minor).$($nextVersion.patch)-$($nextPreReleaseLabel)v001"
            $nextVersion = [semver]::New($nextVersionString)
            write-verbose "Next Prerelease will be: $($nextVersion.ToString())"
        }elseIf($prerelease){
            #This is a strange scenario. Indicates that we have prerelease switch,but the version supplied wasn't a prerelease already. And we didn't increment anything.
            #Are we supposed to go backwards

            #throw 'Unsure on version scenario. Prerelease wanted but version provided was not a pre-release. Please provide a version with existing prerelease, or include an increment'
            
            #I think what we do, is we increment patch by 1 and then tag as pre-release
            write-warning 'Unspecified version increment. Will increment Patch. If this is not what you meant, please try again'

            if(!$preReleaseLabel){
                $nextPreReleaseLabel = $defaultPrereleaseLabel
            }else{
                $nextPreReleaseLabel = $preReleaseLabel
            }

            $nextVersionString = "$($version.major).$($version.minor).$($version.patch+1)-$($nextPreReleaseLabel)v001"
            $nextVersion = [semver]::New($nextVersionString)
        }elseIf($initialPreRelease){
            if(!$preReleaseLabel){
                $nextPreReleaseLabel = $defaultPrereleaseLabel
            }else{
                $nextPreReleaseLabel = $preReleaseLabel
            }
            write-verbose 'Start at v1 prerelease v001'
            $nextVersionString = "1.0.0-$($nextPreReleaseLabel)v001"
            $nextVersion = [semver]::New($nextVersionString)
        }elseIf($stableRelease)
        {
            write-verbose 'Mark release as stable'
            #This scenario is for when we have a pre-release tag and we want to drop it for a stable release version
            if(!($version.PreReleaseLabel))
            {
                throw 'version supplied does not contain a prerelease'
            }

            $nextVersionString = "$($version.major).$($version.minor).$($version.patch)"
            $nextVersion = [semver]::New($nextVersionString)
            write-verbose "Stable Release Version: $($nextVersion.tostring())"

        }

        return $nextVersion

    }
    
}