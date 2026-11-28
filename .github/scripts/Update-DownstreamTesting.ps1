<#
    .SYNOPSIS
        Redraw the Downstream testing table in the release notes of each release on a commit.

    .DESCRIPTION
        Test repositories report each check as a commit status named 'downstream/<Check> (<Version>)'. This reads
        every status on the commit, and for each version that has a release, rewrites the section of its notes
        between the downstream markers, leaving the rest of the notes alone. The section is added at the end the
        first time.

        Only checks that have reported get a row, as not every check runs for every release. Each row shows the
        latest result, and how many runs there have been, with the time of the last failure if there was one.

        The whole table is rebuilt from the statuses every time, so it's safe to run again, and results that
        arrive at the same time can't overwrite each other.

        Uses GITHUB_TOKEN, or GH_TOKEN, which needs contents: write to edit releases, and statuses: read.

    .EXAMPLE
        ./Update-DownstreamTesting.ps1 -Repository 'adrian-andersson/ModuleForge' -Sha 'a44b41efcf2c1eac6a1f66d9c0633f8660da8eaf'

        Redraw the table for every release on that commit.

    .EXAMPLE
        ./Update-DownstreamTesting.ps1 -Repository 'adrian-andersson/ModuleForge' -Tag 'v1.5.0-prev003'

        Redraw the table for one release, such as from a manual run.
#>
[CmdletBinding(DefaultParameterSetName='Sha')]
PARAM(
    #The repository, as owner/name
    [Parameter(Mandatory)]
    [string]$Repository,
    #The commit whose releases to redraw
    [Parameter(Mandatory,ParameterSetName='Sha')]
    [string]$Sha,
    #A release tag to redraw, such as v1.5.0-prev003
    [Parameter(Mandatory,ParameterSetName='Tag')]
    [string]$Tag,
    #The only accounts whose results are shown, so another collaborator, app or integration posting a downstream
    #status can't add rows. Defaults to the repository owner, whose tokens the test repositories use, and this
    #repository's own workflows, whose GITHUB_TOKEN posts as github-actions[bot] and works only on this repository
    [Parameter()]
    [string[]]$AllowedCreator = @(($Repository -split '/')[0], 'github-actions[bot]')
)

$ErrorActionPreference = 'Stop'
$token = if($env:GITHUB_TOKEN){ $env:GITHUB_TOKEN }else{ $env:GH_TOKEN }
if([string]::IsNullOrWhiteSpace($token)){ throw 'No GITHUB_TOKEN or GH_TOKEN' }
$headers = @{
    Authorization          = "Bearer $token"
    Accept                 = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
}
$api = "https://api.github.com/repos/$Repository"
$startMarker = '<!-- downstream:start -->'
$endMarker = '<!-- downstream:end -->'

function ConvertTo-SafeCell
{
    #Results come from other repositories and end up in public release notes, so they're shown as plain text:
    #no HTML (which could end the section early), no links, images or code, and no @mentions notifying anyone
    PARAM([AllowNull()][string]$Text)
    if([string]::IsNullOrWhiteSpace($Text)){ return '' }
    $clean = ($Text -replace '[\r\n\t]+',' ').Trim()
    if($clean.Length -gt 140){ $clean = $clean.Substring(0,137) + '...' }
    $clean = $clean.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;')
    $clean = $clean -replace '([\\`*_\[\]|!])','\$1'
    #A zero-width space after @ and :// stops GitHub turning them into a mention or a link
    $clean = $clean.Replace('@',"@$([char]0x200B)").Replace('://',":$([char]0x200B)//")
    $clean
}

if($PSCmdlet.ParameterSetName -eq 'Tag')
{
    $ref = Invoke-RestMethod -Uri "$api/git/ref/tags/$Tag" -Headers $headers
    $Sha = $ref.object.sha
    if($ref.object.type -eq 'tag'){ $Sha = (Invoke-RestMethod -Uri "$api/git/tags/$Sha" -Headers $headers).object.sha }
}
Write-Verbose "Commit: $Sha"

#Every status on the commit, newest first, a page of 100 at a time
$statuses = [System.Collections.Generic.List[object]]::new()
$page = 1
do{
    #Invoke-RestMethod returns a JSON list as one object, so the pipeline splits it into its items
    $batch = @(Invoke-RestMethod -Uri "$api/commits/$Sha/statuses?per_page=100&page=$page" -Headers $headers | ForEach-Object { $_ })
    foreach($item in $batch){ $statuses.Add($item) }
    $page++
}while($batch.Count -eq 100)
Write-Verbose "Statuses on the commit: $($statuses.Count)"

#Only ours, split into the check and the version it tested
$downstream = foreach($status in $statuses)
{
    if($status.context -match '^downstream/(?<check>.+) \((?<version>[0-9A-Za-z.+-]+)\)$')
    {
        if($status.creator.login -notin $AllowedCreator)
        {
            Write-Warning "Ignoring '$($status.context)' from $($status.creator.login), who isn't one of: $($AllowedCreator -join ', ')"
            continue
        }
        [PSCustomObject]@{
            Check       = $Matches.check
            Version     = $Matches.version
            State       = $status.state
            Description = $status.description
            TargetUrl   = $status.target_url
            Created     = [datetime]$status.created_at
        }
    }
}

$versions = if($PSCmdlet.ParameterSetName -eq 'Tag'){ @($Tag.TrimStart('v')) }else{ @($downstream.Version | Sort-Object -Unique) }
#Built from their code points, so this file stays plain ASCII
$icons = @{
    success = [char]::ConvertFromUtf32(0x2705)
    failure = [char]::ConvertFromUtf32(0x274C)
    error   = [char]::ConvertFromUtf32(0x26A0) + [char]0xFE0F
    pending = [char]::ConvertFromUtf32(0x23F3)
}

foreach($version in $versions)
{
    try{
        $release = Invoke-RestMethod -Uri "$api/releases/tags/v$version" -Headers $headers
    }catch{
        Write-Warning "No release for v$version, so there's nothing to update: $($_.Exception.Message)"
        continue
    }

    $rows = foreach($group in ($downstream | Where-Object Version -eq $version | Group-Object Check | Sort-Object Name))
    {
        #Kept in the order GitHub returns them, newest first, rather than sorted by time, as results posted in the same second would tie
        $latest = $group.Group | Select-Object -First 1
        $finished = @($group.Group | Where-Object State -ne 'pending')
        $lastFailure = $finished | Where-Object State -in 'failure','error' | Select-Object -First 1
        $result = $icons[$latest.State]
        if($latest.TargetUrl -match '^https://[^\s()<>]+$'){ $result = "[$result]($($latest.TargetUrl))" }
        $history = @()
        if($finished.Count -gt 1){ $history += "$($finished.Count) runs" }
        if($lastFailure -and $lastFailure -ne $latest){ $history += "last failure $($lastFailure.Created.ToUniversalTime().ToString('MM-dd HH:mm')) UTC" }
        $note = ((ConvertTo-SafeCell $latest.Description) + $(if($history){" ($($history -join '; '))"})).Trim()
        "| $(ConvertTo-SafeCell $group.Name) | $result | $note | $($latest.Created.ToUniversalTime().ToString('MM-dd HH:mm')) |"
    }
    if(-not $rows)
    {
        Write-Verbose "No checks have reported for v$version"
        continue
    }

    $section = @(
        $startMarker
        '## Downstream testing'
        ''
        '| Check | Result | Notes | Updated (UTC) |'
        '| --- | --- | --- | --- |'
        $rows
        ''
        "_Checks appear as they run. Not every check runs for every release: the public test runs only after a PSGallery publish. $($icons.success) passed, $($icons.failure) failed, $($icons.error) error, $($icons.pending) running._"
        $endMarker
    ) -join "`n"

    $body = "$($release.body)"
    $start = $body.IndexOf($startMarker)
    $end = $body.IndexOf($endMarker)
    if($start -ge 0 -and $end -gt $start)
    {
        $body = $body.Substring(0,$start) + $section + $body.Substring($end + $endMarker.Length)
    }else{
        $body = $body.TrimEnd() + "`n`n" + $section
    }

    if($body -eq $release.body)
    {
        Write-Verbose "v$version is already up to date"
        continue
    }
    $null = Invoke-RestMethod -Method Patch -Uri "$api/releases/$($release.id)" -Headers $headers -Body (@{ body = $body } | ConvertTo-Json) -ContentType 'application/json; charset=utf-8'
    Write-Information "Updated the Downstream testing table on v$version ($(@($rows).Count) checks)" -InformationAction Continue
}
