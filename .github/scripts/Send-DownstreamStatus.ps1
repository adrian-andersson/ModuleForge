<#
    .SYNOPSIS
        Report a downstream test result to the ModuleForge release it tested, as a commit status.

    .DESCRIPTION
        Run by the test repositories (GitHub Actions or Azure Pipelines) when a check starts and when it ends.
        Posts a commit status to the commit tagged v<Version> in the ModuleForge repository, named
        'downstream/<Check> (<Version>)', so every release keeps its own results even when a stable release
        shares a commit with a prerelease. ModuleForge's downstream status workflow then redraws the table
        in that release's notes.

        Never fails the run it's called from: anything that goes wrong is a warning. Reporting is a
        convenience, and a test run's own result must not depend on it.

        Needs a token with only 'Commit statuses: write' on the ModuleForge repository, in
        DOWNSTREAM_STATUS_TOKEN.

    .EXAMPLE
        ./Send-DownstreamStatus.ps1 -Repository 'adrian-andersson/ModuleForge' -Version '1.5.0-prev003' -Check 'Test.Private / Build' -State pending -Trigger automatic

        Mark a check as started.

    .EXAMPLE
        ./Send-DownstreamStatus.ps1 -Repository 'adrian-andersson/ModuleForge' -Version '1.5.0-prev003' -Check 'Test.Private / Build' -State success -Trigger automatic -Description 'Built AstroCmdletsPrivate 1.0.1-prev014'

        Mark a check as passed.
#>
[CmdletBinding()]
PARAM(
    #The repository to report to, as owner/name
    [Parameter(Mandatory)]
    [string]$Repository,
    #The ModuleForge version that was tested, with or without a leading v
    [Parameter(Mandatory)]
    [string]$Version,
    #What was checked, as it should read in the release table, such as 'Test.Private / Build Test'
    [Parameter(Mandatory)]
    [ValidatePattern('^[^()]+$')]
    [string]$Check,
    #The result. pending when a check starts
    [Parameter(Mandatory)]
    [ValidateSet('pending','success','failure','error')]
    [string]$State,
    #automatic when ModuleForge started the run, manual when someone asked for this version by hand
    [Parameter(Mandatory)]
    [ValidateSet('automatic','manual')]
    [string]$Trigger,
    #A short note for the table, shown in public release notes. Keep it generic, such as '31 tests passed' or
    #'2 of 31 tests failed': never error messages, paths or private names. Kept to 140 characters, with the trigger in front
    [Parameter()]
    [string]$Description,
    #A link to the run. Leave it out for a private repository, as the release is public
    [Parameter()]
    [string]$TargetUrl,
    #The commit the release is on, when it's already known. Looking it up from the tag needs read access to the repository
    [Parameter()]
    [ValidatePattern('^[0-9a-f]{40}$')]
    [string]$Sha
)

try{
    $token = $env:DOWNSTREAM_STATUS_TOKEN
    if([string]::IsNullOrWhiteSpace($token))
    {
        Write-Warning 'No DOWNSTREAM_STATUS_TOKEN, so this result is not reported to ModuleForge'
        return
    }
    $headers = @{
        Authorization          = "Bearer $token"
        Accept                 = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
    }
    $version = $Version.Trim().TrimStart('v')
    $api = "https://api.github.com/repos/$Repository"

    #The commit the release tag points to, unless it was passed in. An annotated tag points to a tag object, which points to the commit.
    #$commit, not $sha: PowerShell names ignore case, so $sha is the -Sha parameter, and keeps its validation
    $commit = $Sha
    if(!$commit)
    {
        $ref = Invoke-RestMethod -Uri "$api/git/ref/tags/v$version" -Headers $headers -ErrorAction Stop
        $commit = $ref.object.sha
        if($ref.object.type -eq 'tag')
        {
            $commit = (Invoke-RestMethod -Uri "$api/git/tags/$commit" -Headers $headers -ErrorAction Stop).object.sha
        }
    }
    Write-Verbose "v$version is commit $commit"

    $text = "$Trigger$(if($Description){": $Description"})"
    if($text.Length -gt 140){ $text = $text.Substring(0,137) + '...' }
    $status = @{
        state       = $State
        context     = "downstream/$($Check.Trim()) ($version)"
        description = $text
    }
    if($TargetUrl){ $status.target_url = $TargetUrl }

    $null = Invoke-RestMethod -Method Post -Uri "$api/statuses/$commit" -Headers $headers -Body ($status | ConvertTo-Json) -ContentType 'application/json; charset=utf-8' -ErrorAction Stop
    Write-Information "Reported $State for '$Check' against ModuleForge v$version" -InformationAction Continue
}catch{
    Write-Warning "Unable to report '$Check' to ModuleForge v$($Version): $($_.Exception.Message)"
}
