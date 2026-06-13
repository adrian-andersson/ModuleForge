function Get-MFNextSemver
{

    <#
    .SYNOPSIS
        Increments the version of a Semantic Version (SemVer) object.

    .DESCRIPTION
        The `Get-MFNextSemver` function takes a Semantic Version (SemVer) object as input and increments the version based on the 'increment' parameter. 
        It can handle major, minor, and patch increments. 
        The function also handles pre-release versions and allows the user to optionally override the pre-release label.

    .EXAMPLE
        $Version = [SemVer]::new('1.0.0')
        Get-MFNextSemver -Version $Version -Increment 'Minor' -PreRelease

        #### DESCRIPTION
        This example takes a SemVer object with version '1.0.0', increments the minor version, and adds a pre-release tag. The output will be '1.1.0-prerelease.1'.

        #### OUTPUT
        '1.1.0-prerelease.1'

    .EXAMPLE
        $Version = [SemVer]::new('2.0.0-prerelease.1')
        Get-MFNextSemver -Version $Version -Increment 'Major'

        #### DESCRIPTION
        This example takes a SemVer object with version '2.0.0-prerelease.1', increments the major version, and removes the pre-release tag because the 'prerelease' switch is not set. The output will be '3.0.0'.

        #### OUTPUT
        '3.0.0'

    .INPUTS
        [semver] - Will accept a Semver from pipeline or via direct assignment

    .OUTPUTS
        [semver] - Returns a Semantec Version object that should increment, based on the other parameters, the input semver

    .NOTES
        Author: Adrian Andersson
    #>

    [CmdletBinding(DefaultParameterSetName='default')]
    [OutputType([semver])]
    PARAM(
        #Semver Version
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName,ParameterSetName='default')]
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName,ParameterSetName='preRelease')]
        [SemVer]$Version,

        #What are we incrementing
        [Parameter(ParameterSetName='default')]
        [Parameter(ParameterSetName='preRelease')]
        [ValidateSet('Major','Minor','Patch')]
        [string]$Increment,

        #Is this a prerelease
        [Parameter(ParameterSetName='preRelease')]
        [switch]$PreRelease,

        #Is this a prerelease
        [Parameter(ParameterSetName='default')]
        [switch]$StableRelease,

        #Optional override the prerelease label. If not supplied will use 'prerelease'
        [Parameter(ParameterSetName='preRelease')]
        [Parameter(ParameterSetName='Initial')]
        [string]$PreReleaseLabel,

        #Is this the initial prerelease
        [Parameter(ParameterSetName='Initial')]
        [switch]$InitialPreRelease

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        #Making the default preReleaase label to be lower case. This addresses a problem with psResourceGet and AzureDevOps repositories specifically (Issue #1787)
        $defaultPrereleaseLabel = 'pre' 

        if (-not $Increment -and -not $PreRelease -and -not $InitialPreRelease -and -not $StableRelease) {
            throw 'At least one of "increment", parameter or "stableRelease", "prerelease", "initialPreRelease" switch should be supplied.'
        }
    }
    
    process{
        # Increment the version based on the 'increment' parameter
        switch ($Increment) {
            'Major' { 
                #$nextVersion = $Version.IncrementMajor()
                $nextVersion = [semver]::new($Version.Major+1,0,0)
                write-verbose "Incrementing Major Version to: $($nextVersion.tostring())"
             }
            'Minor' { 
                $nextVersion = [semver]::new($Version.Major,$Version.minor+1,0)
                write-verbose "Incrementing Minor Version to: $($nextVersion.tostring())"
            }
            'Patch' { 
                $nextVersion = [semver]::new($Version.Major,$Version.minor,$Version.Patch+1)
                write-verbose "Incrementing Patch Version to: $($nextVersion.tostring())"
            }
        }

        # Handle pre-release versions
        if($PreRelease -and !$nextVersion -and $Version.PreReleaseLabel)
        {
            #This scenario indicates version supplied is already a prerelease, and what we want to do is increment the prerelease version
            write-verbose 'Incrementing Prerelease Version'
            $currentPreReleaseSplit = $Version.PreReleaseLabel.Split('v')
            $currentpreReleaseLabel = $currentPreReleaseSplit[0]
            write-verbose "Current PreRelease Label: $currentpreReleaseLabel"
            if(!$PreReleaseLabel -or ($currentpreReleaseLabel -ceq $PreReleaseLabel)){
                if($currentpreReleaseLabel -eq $PreReleaseLabel)
                {
                    write-warning 'It appears the prerelease casing has changed, but the label has not. This may cause unexpected ordering results.'
                }
                write-verbose 'No change to prerelease label'
                $nextPreReleaseLabel = $currentpreReleaseLabel
                $currentPreReleaseInt = [int]$currentPreReleaseSplit[1]
                $nextPrerelease = $currentPreReleaseInt+1
                

            }else{
                write-verbose 'Prerelease label changed. Resetting prerelease version to 1'
                $nextPreReleaseLabel = $PreReleaseLabel
                $nextPreRelease = 1
            }
            
            $nextVersionString = "$($Version.major).$($Version.minor).$($Version.patch)-$($nextPreReleaseLabel)v$('{0:d3}' -f $nextPrerelease)"
            $nextVersion = [semver]::New($nextVersionString)
            write-verbose "Next Prerelease will be: $($nextVersion.ToString())"
            
        }elseIf($PreRelease -and $nextVersion)
        {
            write-verbose 'Need to tag incremented version as PreRelease'
            #This scenario indicates we have incremented a major,minor or patch, and need to start a fresh prerelease
            if(!$PreReleaseLabel){
                $nextPreReleaseLabel = $defaultPrereleaseLabel
            }else{
                $nextPreReleaseLabel = $PreReleaseLabel
            }

            $nextVersionString = "$($nextVersion.major).$($nextVersion.minor).$($nextVersion.patch)-$($nextPreReleaseLabel)v001"
            $nextVersion = [semver]::New($nextVersionString)
            write-verbose "Next Prerelease will be: $($nextVersion.ToString())"
        }elseIf($PreRelease){
            #This is a strange scenario. Indicates that we have prerelease switch,but the version supplied wasn't a prerelease already. And we didn't increment anything.
            #Are we supposed to go backwards

            #throw 'Unsure on version scenario. Prerelease wanted but version provided was not a pre-release. Please provide a version with existing prerelease, or include an increment'
            
            #I think what we do, is we increment patch by 1 and then tag as pre-release
            write-warning 'Unspecified version increment. Will increment Patch. If this is not what you meant, please try again'

            if(!$PreReleaseLabel){
                $nextPreReleaseLabel = $defaultPrereleaseLabel
            }else{
                $nextPreReleaseLabel = $PreReleaseLabel
            }

            $nextVersionString = "$($Version.major).$($Version.minor).$($Version.patch+1)-$($nextPreReleaseLabel)v001"
            $nextVersion = [semver]::New($nextVersionString)
        }elseIf($InitialPreRelease){
            if(!$PreReleaseLabel){
                $nextPreReleaseLabel = $defaultPrereleaseLabel
            }else{
                $nextPreReleaseLabel = $PreReleaseLabel
            }
            write-verbose 'Start at v1 prerelease v001'
            $nextVersionString = "1.0.0-$($nextPreReleaseLabel)v001"
            $nextVersion = [semver]::New($nextVersionString)
        }elseIf($StableRelease)
        {
            write-verbose 'Mark release as stable'
            #This scenario is for when we have a pre-release tag and we want to drop it for a stable release version
            if(!($Version.PreReleaseLabel))
            {
                throw 'version supplied does not contain a prerelease'
            }

            $nextVersionString = "$($Version.major).$($Version.minor).$($Version.patch)"
            $nextVersion = [semver]::New($nextVersionString)
            write-verbose "Stable Release Version: $($nextVersion.tostring())"

        }

        return $nextVersion

    }
    
}