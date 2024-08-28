$functionsPath = $(join-path -path (join-path -path . -childpath 'source') -childpath 'functions')
#Exclude get-mfFolderItemDetails.ps1 from CodeCoverage as it has a giant scriptblock that is hard to get code-coverage for.
$CodeCoveragePaths = (get-childitem $functionsPath -Filter '*.ps1' -recurse).where{$_.name -notmatch '\.Tests\.ps1$' -and $_.name -notmatch '\.Skip\.ps1$' -and $_.name -notmatch 'get-mfFolderItemDetails.ps1$'}.fullname
$pesterConfigHash = @{
    Run = @{
        Passthru = $true
        Path = $functionsPath

    }
    CodeCoverage = @{
        Enabled = $true
        Path = $CodeCoveragePaths
    }
    Output = @{
        Verbosity = 'Detailed'
    }
}

$pesterConfig = New-PesterConfiguration -hashtable $pesterConfigHash



invoke-pester -config $pesterConfig