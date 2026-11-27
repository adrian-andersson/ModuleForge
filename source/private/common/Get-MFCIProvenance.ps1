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
    PARAM()
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }
    process{
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
        }elseif($env:TF_BUILD -eq 'True'){
            write-verbose 'Running in Azure Pipelines'
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
