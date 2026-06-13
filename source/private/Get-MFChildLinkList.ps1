function Get-MFChildLinkList
{

    <#
        .SYNOPSIS
            Build a markdown bullet list of child page links for a Just The Docs parent index page.

        .DESCRIPTION
            For each supplied markdown file, reads the H1 heading to use as the link label (falling
            back to the base filename). For each supplied sub-directory, derives the nav title with
            ConvertTo-MFNavTitle. Returns a list of markdown bullet strings ready to embed in a
            parent index page.

        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding()]
    [OutputType([object[]])]
    PARAM(
        #Markdown files to link to. Typically the direct .md children of the section folder.
        [Parameter()]
        $MdFiles,
        #Subdirectories to link to as sub-sections. Pass an empty array when none exist.
        [Parameter()]
        $SubDirs
    )
    process{
        $links = [System.Collections.Generic.List[string]]::new()

        foreach($f in ($MdFiles | Sort-Object Name))
        {
            $h1   = Get-MFH1FromFile -FilePath $f.FullName
            $text = if($h1){ $h1 }else{ $f.BaseName }
            $links.Add("- [$text](./$($f.Name))")
        }

        foreach($d in ($SubDirs | Sort-Object Name))
        {
            $dTitle = ConvertTo-MFNavTitle -FolderName $d.Name
            $links.Add("- [$dTitle](./$($d.Name)/)")
        }

        return ,$links
    }
}