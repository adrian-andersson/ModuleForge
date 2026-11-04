function Get-MFLicenseUri
{

    <#
        .SYNOPSIS
            Work out a web link to a project's license file from its project URI.

        .DESCRIPTION
            Looks for a license file in the project root: LICENSE or LICENCE, optionally ending .md or .txt.
            If one exists and the project URI is a GitHub or Azure DevOps repository, returns a link to that
            file on the repository's default branch:

              - GitHub:       https://github.com/<owner>/<repo>/blob/HEAD/<file>
              - Azure DevOps: <repository URI>?path=/<file>

            Returns nothing for any other host, or when there is no license file, so the caller can leave
            LicenseUri empty. Expects a clean https project URI, as ConvertTo-MFSafeUri returns.

        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding()]
    [OutputType([string])]
    PARAM(
        #The project's repository URI, already cleaned by ConvertTo-MFSafeUri
        [Parameter()]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$ProjectUri,
        #Root path of the project, where the license file would be
        [Parameter(Mandatory)]
        [string]$ModulePath
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }
    process{
        if([string]::IsNullOrWhiteSpace($ProjectUri))
        {
            write-verbose 'No project URI, so no license URI'
            return
        }
        #Prefer the plain LICENSE name if a project has more than one
        $licenseFile = Get-ChildItem -LiteralPath $ModulePath -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^licen[cs]e(\.(md|txt))?$' } |
            Sort-Object -Property @{Expression = { $_.Name.Length }}, Name |
            Select-Object -First 1
        if(!$licenseFile)
        {
            write-verbose "No license file in $ModulePath, so no license URI"
            return
        }
        $base = $ProjectUri.Trim().TrimEnd('/') -replace '\.git$',''
        $fileName = [uri]::EscapeDataString($licenseFile.Name)
        if($base -match '^https://github\.com/[^/]+/[^/]+$')
        {
            return "$base/blob/HEAD/$fileName"
        }
        if($base -match '^https://dev\.azure\.com/[^/]+/[^/]+/_git/[^/?#]+$' -or $base -match '^https://[^/]+\.visualstudio\.com/([^/]+/)?[^/]+/_git/[^/?#]+$')
        {
            return "$base`?path=/$fileName"
        }
        write-verbose "Project URI $base is not a GitHub or Azure DevOps repository, so no license URI"
    }
}
