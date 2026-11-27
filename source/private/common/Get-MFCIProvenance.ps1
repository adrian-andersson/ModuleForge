function Get-MFCIProvenance
{

    <#
        .SYNOPSIS
            Get the CI run and source commit a build came from, when it's running in GitHub Actions or Azure Pipelines.

        .DESCRIPTION
            Build-MFProject adds these to its build provenance, beside the ModuleForge version and hashes. Each value
            can be checked against the CI platform: the commit against the repository, and the run URL leads to the
            run's logs and release plan. Together they trace a built module back to the exact source and run that
            produced it, after it's installed and the package metadata is gone.

            Reads the CI platform's own environment variables, so there's nothing to pass in:
              - GitHub Actions, when GITHUB_ACTIONS is true
              - Azure Pipelines, when TF_BUILD is true

            How much it returns depends on -Detail, from the project's sourceProvenance setting. The repository, branch
            and run URL name the organisation, project and repository, and a published module can't be unpublished,
            so a private repository shouldn't be named in one by default:
              - Full: everything
              - Minimal: the platform, commit, run ID and attempt, which mean nothing without access to the repository
              - Auto: Full when the repository is public, otherwise Minimal. GitHub says whether a repository is private
                in the run's event data. Azure Pipelines doesn't, so Auto is always Minimal there

            Returns nothing outside CI, so local builds don't record any of this. Values the platform doesn't
            provide are left out. The repository URI has any credentials removed, as it goes into the manifest.

        .OUTPUTS
            [System.Collections.Specialized.OrderedDictionary] - Platform, Repository, Commit, Branch, RunId,
            RunAttempt and RunUrl, or nothing outside CI

        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    PARAM(
        #How much to return. Auto is Full for a public repository, otherwise Minimal
        [Parameter()]
        [ValidateSet('Auto','Full','Minimal')]
        [string]$Detail = 'Auto'
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }
    process{
        $isPublic = $false
        if($env:GITHUB_ACTIONS -eq 'true')
        {
            write-verbose 'Running in GitHub Actions'
            $repository = if($env:GITHUB_SERVER_URL -and $env:GITHUB_REPOSITORY){ "$($env:GITHUB_SERVER_URL)/$($env:GITHUB_REPOSITORY)" }
            $values = [ordered]@{
                Platform   = 'GitHub Actions'
                Repository = $repository
                Commit     = $env:GITHUB_SHA
                Branch     = $env:GITHUB_REF_NAME
                RunId      = $env:GITHUB_RUN_ID
                RunAttempt = $env:GITHUB_RUN_ATTEMPT
                RunUrl     = if($repository -and $env:GITHUB_RUN_ID){ "$repository/actions/runs/$($env:GITHUB_RUN_ID)" }
            }
            #The event data describes the repository. Anything unreadable or missing counts as private
            if($Detail -eq 'Auto' -and $env:GITHUB_EVENT_PATH -and (Test-Path -LiteralPath $env:GITHUB_EVENT_PATH))
            {
                try{
                    $eventRepository = (Get-Content -LiteralPath $env:GITHUB_EVENT_PATH -Raw | ConvertFrom-Json -ErrorAction Stop).repository
                    $isPublic = $eventRepository.visibility -eq 'public' -or ($null -eq $eventRepository.visibility -and $eventRepository.private -eq $false)
                }catch{
                    write-verbose "Unable to read the GitHub event data, so treating the repository as private: $($_.Exception.Message)"
                }
            }
        }elseif($env:TF_BUILD -eq 'True'){
            write-verbose 'Running in Azure Pipelines. It does not say whether a project is public, so Auto treats it as private'
            #The branch is refs/heads/<name> for a branch build. The short name drops anything after the last /, so trim the prefix instead
            $branch = if($env:BUILD_SOURCEBRANCH){ $env:BUILD_SOURCEBRANCH -replace '^refs/heads/','' }
            $runUrl = if($env:SYSTEM_COLLECTIONURI -and $env:SYSTEM_TEAMPROJECT -and $env:BUILD_BUILDID){
                "$($env:SYSTEM_COLLECTIONURI.TrimEnd('/'))/$([uri]::EscapeDataString($env:SYSTEM_TEAMPROJECT))/_build/results?buildId=$($env:BUILD_BUILDID)"
            }
            $values = [ordered]@{
                Platform   = 'Azure Pipelines'
                Repository = $env:BUILD_REPOSITORY_URI
                Commit     = $env:BUILD_SOURCEVERSION
                Branch     = $branch
                RunId      = $env:BUILD_BUILDID
                RunAttempt = $env:SYSTEM_JOBATTEMPT
                RunUrl     = $runUrl
            }
        }else{
            write-verbose 'Not running in GitHub Actions or Azure Pipelines, so there is no CI provenance'
            return
        }

        $full = $Detail -eq 'Full' -or ($Detail -eq 'Auto' -and $isPublic)
        if(!$full)
        {
            write-verbose 'Leaving out the repository, branch and run URL, as the repository may be private'
            foreach($name in 'Repository','Branch','RunUrl')
            {
                $values.Remove($name)
            }
        }

        if($values.Repository)
        {
            $values.Repository = ConvertTo-MFSafeUri -Uri $values.Repository
        }

        #Only the values the platform provided
        $result = [ordered]@{}
        foreach($key in $values.Keys)
        {
            if(![string]::IsNullOrWhiteSpace($values[$key]))
            {
                $result[$key] = "$($values[$key])"
            }
        }
        $result
    }
}
