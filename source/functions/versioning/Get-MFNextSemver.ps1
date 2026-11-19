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
        This example takes a SemVer object with version '1.0.0', increments the minor version, and adds a pre-release tag. With no -PreReleaseLabel supplied it uses the default 'pre' label and a zero-padded counter, so the output will be '1.1.0-prev001'.

        #### OUTPUT
        '1.1.0-prev001'

    .EXAMPLE
        $Version = [SemVer]::new('2.0.0-prerelease.1')
        Get-MFNextSemver -Version $Version -Increment 'Major'

        #### DESCRIPTION
        This example takes a SemVer object with version '2.0.0-prerelease.1', increments the major version, and removes the pre-release tag because the 'prerelease' switch is not set. The output will be '3.0.0'.

        #### OUTPUT
        '3.0.0'

    .EXAMPLE
        Get-MFNextSemver -Version '1.2.3' -Increment 'Minor' -StableRelease

        #### DESCRIPTION
        Releases a new stable version directly, without a prerelease series first. Without -Increment, -StableRelease only promotes a prerelease, so it throws for a version that is already stable.

        #### OUTPUT
        '1.3.0'

    .INPUTS
        [semver] - Will accept a Semver from pipeline or via direct assignment

    .OUTPUTS
        [semver] - Returns a Semantic Version object incremented from the input semver, based on the other parameters

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

        #Is this a stable release. With -Increment, returns the incremented stable version. Without, drops the prerelease tag from a prerelease version
        [Parameter(ParameterSetName='default')]
        [switch]$StableRelease,

        #Optional override the prerelease label. If not supplied will use 'pre', giving prev001, prev002 and so on
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
            #ModuleForge prereleases are <label>v<number>, e.g. prev003. The label can itself contain a v, e.g. devv003, so match the last v<number>
            if($Version.PreReleaseLabel -match '^(?<label>.+)v(?<counter>\d+)$')
            {
                $currentPreReleaseLabel = $Matches.label
                $currentPreReleaseCounter = [int]$Matches.counter
                write-verbose "Current PreRelease Label: $currentPreReleaseLabel, counter: $currentPreReleaseCounter"
                if(!$PreReleaseLabel -or ($currentPreReleaseLabel -ceq $PreReleaseLabel)){
                    write-verbose 'No change to prerelease label'
                    $nextPreReleaseLabel = $currentPreReleaseLabel
                    $nextPrerelease = $currentPreReleaseCounter+1
                }elseif($currentPreReleaseLabel -eq $PreReleaseLabel){
                    write-warning "The prerelease label casing has changed from '$currentPreReleaseLabel' to '$PreReleaseLabel'. Prerelease labels sort by case, so this may cause unexpected ordering results."
                    $nextPreReleaseLabel = $PreReleaseLabel
                    $nextPrerelease = $currentPreReleaseCounter+1
                }else{
                    write-verbose 'Prerelease label changed. Resetting prerelease version to 1'
                    $nextPreReleaseLabel = $PreReleaseLabel
                    $nextPreRelease = 1
                }
            }else{
                #Not a ModuleForge prerelease, e.g. beta.1, so there is no counter to continue
                $nextPreReleaseLabel = if($PreReleaseLabel){$PreReleaseLabel}else{$defaultPrereleaseLabel}
                $nextPreRelease = 1
                write-warning "Prerelease '$($Version.PreReleaseLabel)' is not in the <label>v<number> format, so starting again at $($nextPreReleaseLabel)v001"
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
            write-warning "Version $Version is not a prerelease and no increment was given, so starting a patch prerelease series. If this is not what you meant, supply -Increment"

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
            if($nextVersion)
            {
                #An increment was given, so the incremented version is already the stable release
                write-verbose "Stable Release Version: $($nextVersion.tostring())"
            }elseif($Version.PreReleaseLabel){
                #Promote the prerelease, dropping its tag
                $nextVersionString = "$($Version.major).$($Version.minor).$($Version.patch)"
                $nextVersion = [semver]::New($nextVersionString)
                write-verbose "Stable Release Version: $($nextVersion.tostring())"
            }else{
                throw "Version $Version is already stable, so there is no prerelease to promote. Supply -Increment to release a new stable version, or use -PreRelease to start a prerelease series"
            }

        }

        return $nextVersion

    }
    
}