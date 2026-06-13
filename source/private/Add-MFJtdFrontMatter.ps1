function Add-MFJtdFrontMatter
{

    <#
        .SYNOPSIS
            Prepend Just The Docs front matter to a markdown file.

        .DESCRIPTION
            Builds a YAML front matter block from the supplied fields and writes it to the top of
            the file. Any existing front matter block is stripped and replaced - the body content
            is preserved. Only call this on files that Test-MFHasJtdFrontMatter returns false for,
            to avoid overwriting intentional manual front matter.

        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding()]
    PARAM(
        #Path to the markdown file to update
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$FilePath,
        #Value for the 'title:' front matter field
        [Parameter(Mandatory)]
        [string]$Title,
        #Value for the 'parent:' front matter field. Omit for root-level pages.
        [Parameter()]
        [string]$Parent,
        #Value for the 'grand_parent:' front matter field. Omit for depth-1 pages.
        [Parameter()]
        [string]$GrandParent
    )
    process{
        $existing = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
        if(-not $existing){ return }

        $fmLines = [System.Collections.Generic.List[string]]::new()
        $fmLines.Add('---')
        $fmLines.Add('layout: default')
        $fmLines.Add("title: $Title")
        if($Parent)     { $fmLines.Add("parent: $Parent") }
        if($GrandParent){ $fmLines.Add("grand_parent: $GrandParent") }
        $fmLines.Add('---')
        $fmLines.Add('')

        # Strip any existing front matter, preserving the body
        if($existing -match '(?s)^---\r?\n.*?\r?\n---\r?\n')
        {
            $body = $existing.Substring($Matches[0].Length)
        }else{
            $body = $existing
        }

        ($fmLines -join "`n") + $body | Out-File $FilePath -Force
    }
}
