function Get-MFH1FromFile
{

    <#
        .SYNOPSIS
            Return the text of the first H1 heading in a markdown file.

        .DESCRIPTION
            Reads the file line by line and returns the content of the first line matching '^# '.
            Returns null if no H1 heading is found.

        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding()]
    [OutputType([string])]
    PARAM(
        #Path to the markdown file
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$FilePath
    )
    process{
        $lines = Get-Content $FilePath -ErrorAction SilentlyContinue
        foreach($line in $lines)
        {
            if($line -match '^# (.+)')
            {
                return $Matches[1].Trim()
            }
        }
        return $null
    }
}