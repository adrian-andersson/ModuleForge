function ConvertTo-MFSafeUri
{

    <#
        .SYNOPSIS
            Make a git remote safe to publish as a project or repository URI.

        .DESCRIPTION
            Git remotes can carry credentials, and a project URI ends up in the published module manifest.
            This removes any user name, password or token from the URI, turns SSH remotes into their https
            web address, and drops a trailing .git.

            Warns when credentials are removed, as they were stored somewhere they should not have been.
            Anything that is not a remote URL, such as a local path, is returned unchanged.

        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding()]
    [OutputType([string])]
    PARAM(
        #The URI to clean, usually a git remote
        [Parameter(ValueFromPipeline)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Uri
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }
    process{
        if([string]::IsNullOrWhiteSpace($Uri))
        {
            return $Uri
        }
        $value = $Uri.Trim()

        #Azure DevOps SSH remotes have their own layout: git@ssh.dev.azure.com:v3/org/project/repo
        if($value -match '^(?:ssh://)?[^@/\s]+@ssh\.dev\.azure\.com(?::22)?[:/]v3/([^/]+)/([^/]+)/([^/]+?)/?$')
        {
            return "https://dev.azure.com/$($Matches[1])/$($Matches[2])/_git/$($Matches[3])"
        }

        #scp-style SSH remotes: git@github.com:owner/repo.git
        if($value -match '^[^@/\s:]+@([^:/\s]+):(?!//)(.+)$')
        {
            write-verbose 'Converting an SSH remote to its https address'
            $value = "https://$($Matches[1])/$($Matches[2])"
        }

        $parsed = $null
        if(![uri]::TryCreate($value,[UriKind]::Absolute,[ref]$parsed) -or $parsed.Scheme -notin 'http','https','ssh')
        {
            write-verbose 'Not a remote URL, leaving it unchanged'
            return $Uri
        }

        #Nothing to clean, so return it as written rather than reformatted
        if($parsed.Scheme -ne 'ssh' -and !$parsed.UserInfo -and $parsed.AbsolutePath -notmatch '\.git/?$')
        {
            return $value
        }

        if($parsed.UserInfo -match ':')
        {
            write-warning "Removed credentials from $($parsed.Host) URI. A password or token was stored in it, check where it came from"
        }

        $builder = [UriBuilder]::new($parsed)
        $builder.UserName = ''
        $builder.Password = ''
        if($builder.Scheme -eq 'ssh')
        {
            $builder.Scheme = 'https'
            $builder.Port = -1
        }
        $builder.Path = $builder.Path -replace '\.git/?$',''
        $builder.Uri.AbsoluteUri
    }
}
