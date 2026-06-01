function ConvertTo-MFNavTitle
{

    <#
        .SYNOPSIS
            Convert a folder name to a readable Just The Docs navigation title.

        .DESCRIPTION
            Splits on camelCase boundaries, hyphens, and underscores, then applies title case.
            Intended for deriving sidebar nav titles from raw folder names without a lookup table.

        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding()]
    [OutputType([string])]
    PARAM(
        #Folder name to convert
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$FolderName
    )
    process{
        $spaced = $FolderName -creplace '([a-z])([A-Z])', '$1 $2'
        $spaced = $spaced -replace '[-_]', ' '
        (Get-Culture).TextInfo.ToTitleCase($spaced.ToLower())
    }
}