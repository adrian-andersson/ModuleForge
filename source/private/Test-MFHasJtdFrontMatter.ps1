function Test-MFHasJtdFrontMatter
{

    <#
        .SYNOPSIS
            Return true if a markdown file already contains a Just The Docs 'layout:' field.

        .DESCRIPTION
            Reads the file's YAML front matter block and checks for the presence of a 'layout:' key.
            Used to determine whether a page should be skipped during non-destructive stamping.

        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    PARAM(
        #Path to the markdown file
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$FilePath
    )
    process{
        $raw = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
        if($raw -match '(?s)^---\r?\n(.*?)\r?\n---')
        {
            return [bool]($Matches[1] -match '(?m)^layout\s*:')
        }
        return $false
    }
}