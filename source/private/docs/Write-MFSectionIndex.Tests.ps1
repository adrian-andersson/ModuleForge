[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'

    #Load This File (the function lives alongside this test in source/private)
    $fileName = $PSCommandPath.Replace('.Tests.ps1','.ps1')
    $functionName = 'Write-MFSectionIndex'
    . $fileName

    #Temp working folder. Use GetTempPath for cross-platform safety (env:TEMP is null on Linux CI)
    $testFolder = join-path -path ([System.IO.Path]::GetTempPath()) -childPath "mfTest_SectionIndex_$(New-Guid)"
    new-item -ItemType Directory -Path $testFolder | out-null

}

AfterAll{
    Remove-Item $testFolder -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Check Clean Environment' {
    It 'Should have loaded the function directly, not from an imported module' {
        (get-command $functionName).source | should -BeNullOrEmpty
    }
}

Describe 'Write-MFSectionIndex' {
    It 'Writes front matter with has_children and an H1 matching the title' {
        $file = join-path -path $testFolder -childPath 'index.md'
        Write-MFSectionIndex -FilePath $file -Title 'Tutorials'
        $raw = Get-Content $file -Raw
        $raw | Should -Match '(?s)^---\r?\nlayout: default\r?\ntitle: Tutorials\r?\nhas_children: true\r?\n---'
        $raw | Should -Match '(?m)^# Tutorials$'
    }

    It 'Includes a parent field when supplied' {
        $file = join-path -path $testFolder -childPath 'childIndex.md'
        Write-MFSectionIndex -FilePath $file -Title 'Sub Section' -Parent 'Tutorials'
        Get-Content $file -Raw | Should -Match '(?m)^parent: Tutorials$'
    }

    It 'Appends the supplied child link list to the body' {
        $file = join-path -path $testFolder -childPath 'withLinks.md'
        $links = @('- [Alpha](./alpha.md)', '- [Beta](./beta/)')
        Write-MFSectionIndex -FilePath $file -Title 'Section' -ChildLinks $links
        $raw = Get-Content $file -Raw
        $raw | Should -Match '\- \[Alpha\]\(\./alpha\.md\)'
        $raw | Should -Match '\- \[Beta\]\(\./beta/\)'
    }
}
