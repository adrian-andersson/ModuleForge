[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Reference paths for loading the dependency private functions
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    #Get-MFChildLinkList depends on two other private functions. Resolve them by filename anywhere
    #under source/, so tests stay independent of the folder layout. List order is load order.
    $sourceMap = @{}
    Get-ChildItem -Path $sourcePath -Recurse -Filter '*.ps1' -File | ForEach-Object { if(-not $sourceMap.ContainsKey($_.Name)){ $sourceMap[$_.Name] = $_.FullName } }
    $dependencies = @(
        'Get-MFH1FromFile.ps1'
        'ConvertTo-MFNavTitle.ps1'
    )
    $dependencies.ForEach{
        if($sourceMap.ContainsKey($_)){ . $sourceMap[$_] }else{ write-warning "Dependency not found under source: $_" }
    }

    #Load This File (the function lives alongside this test in source/private)
    $fileName = $PSCommandPath.Replace('.Tests.ps1','.ps1')
    $functionName = 'Get-MFChildLinkList'
    . $fileName

    #Build a temp section folder with markdown children and a sub-directory
    $testFolder = join-path -path ([System.IO.Path]::GetTempPath()) -childPath "mfTest_ChildLinks_$(New-Guid)"
    new-item -ItemType Directory -Path $testFolder | out-null

    Set-Content -Path (join-path -path $testFolder -childPath 'alpha.md') -Value @('# Alpha Heading', 'body')
    Set-Content -Path (join-path -path $testFolder -childPath 'beta.md') -Value @('## No H1 here', 'body')
    new-item -ItemType Directory -Path (join-path -path $testFolder -childPath 'subSection') | out-null

    $mdFiles = Get-ChildItem -Path $testFolder -Filter '*.md' -File
    $subDirs = Get-ChildItem -Path $testFolder -Directory

}

AfterAll{
    Remove-Item $testFolder -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Check Clean Environment' {
    It 'Should have loaded the function directly, not from an imported module' {
        (get-command $functionName).source | should -BeNullOrEmpty
    }
}

Describe 'Get-MFChildLinkList' {
    BeforeAll{
        $result = Get-MFChildLinkList -MdFiles $mdFiles -SubDirs $subDirs
    }

    It 'Uses the H1 heading as the link label for a markdown file' {
        $result | Should -Contain '- [Alpha Heading](./alpha.md)'
    }

    It 'Falls back to the base filename when a file has no H1' {
        $result | Should -Contain '- [beta](./beta.md)'
    }

    It 'Derives a nav title for sub-directories and links with a trailing slash' {
        $result | Should -Contain '- [Sub Section](./subSection/)'
    }

    It 'Returns one entry per file and sub-directory' {
        $result.Count | Should -Be 3
    }
}
