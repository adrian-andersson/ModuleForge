function get-mfGitLatestVersion
{

    <#
        .SYNOPSIS
            Retrieves the latest Git tag version in semantic version format.
            
        .DESCRIPTION
            This function queries Git for available tags and processes them as semantic versions.
            If no tags are found, it initializes a new version starting from `1.0.0`.
            If Git is unavailable or returns an error, a warning is displayed, and processing continues gracefully.
            
        ------------
        .EXAMPLE
            get-mfGitLatestVersion

            #### DESCRIPTION
            Queries the current Git repository for version tags, identifies the latest version,
            and returns it in `major.minor.patch` format.

            #### OUTPUT
            1.2.3
            (Example: If Git tags include `v1.0.0`, `v1.2.3`, `v1.1.0`, the function returns `1.2.3` as the latest.)

        .EXAMPLE
            get-mfGitLatestVersion -Verbose

            #### DESCRIPTION
            Runs the function with verbose output, providing detailed debugging information
            about the Git command execution and version determination.

            #### OUTPUT
            ```
            ===========Executing get-mfGitLatestVersion===========
            Got VersionTags: v1.0.0 v1.2.3 v1.1.0
            Latest Tag Version: 1.2.3
            ```
            
            
        .NOTES
            Author: Adrian Andersson
            
    #>

    [CmdletBinding()]
    PARAM(

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        
    }
    
    process{
        try{
            $versionTags = git tag --list 2>&1
            if ($LASTEXITCODE -ne 0 -or $versionTags -match "fatal:") {
                throw "Git Error: $versionTags"
            }
        }catch{
            Write-Warning "Error with git command: $_"
            $versionTags = $null
        }
        
        write-verbose "Got VersionTags: $versionTags"
        if($versionTags) {
        $versions = $versionTags.ForEach{[semver]::new($_.TrimStart("v"))}
            $latest = ($versions | Sort-Object -Descending | Select-Object -First 1)
        Write-Verbose "Latest Tag Version: $($latest.tostring())"
        } else {
        Write-Verbose 'Generating new version from scratch at 1'
            $latest = [semver]::new(1,0,0)
        }
        return $latest
    }
    
}