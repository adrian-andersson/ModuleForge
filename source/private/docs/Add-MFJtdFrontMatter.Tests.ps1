[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'

    #Load This File (the function lives alongside this test in source/private)
    $fileName = $PSCommandPath.Replace('.Tests.ps1','.ps1')
    $functionName = 'Add-MFJtdFrontMatter'
    . $fileName

    #Temp working folder. Use GetTempPath for cross-platform safety (env:TEMP is null on Linux CI)
    $testFolder = join-path -path ([System.IO.Path]::GetTempPath()) -childPath "mfTest_JtdAdd_$(New-Guid)"
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

Describe 'Add-MFJtdFrontMatter' {
    It 'Prepends front matter and preserves the existing body' {
        $file = join-path -path $testFolder -childPath 'bodyOnly.md'
        Set-Content -Path $file -Value @('# Body Heading', 'Some content')
        Add-MFJtdFrontMatter -FilePath $file -Title 'My Page'
        $raw = Get-Content $file -Raw
        $raw | Should -Match '(?s)^---\r?\nlayout: default\r?\ntitle: My Page\r?\n---'
        $raw | Should -Match '# Body Heading'
    }

    It 'Includes parent and grand_parent fields when supplied' {
        $file = join-path -path $testFolder -childPath 'withParents.md'
        Set-Content -Path $file -Value @('# Body')
        Add-MFJtdFrontMatter -FilePath $file -Title 'Child Page' -Parent 'Section' -GrandParent 'Guides'
        $raw = Get-Content $file -Raw
        $raw | Should -Match '(?m)^parent: Section$'
        $raw | Should -Match '(?m)^grand_parent: Guides$'
    }

    It 'Replaces existing front matter rather than stacking it' {
        $file = join-path -path $testFolder -childPath 'existingFm.md'
        Set-Content -Path $file -Value @('---', 'title: Old Title', '---', '# Real Body')
        Add-MFJtdFrontMatter -FilePath $file -Title 'New Title'
        $raw = Get-Content $file -Raw
        $raw | Should -Match '(?m)^title: New Title$'
        $raw | Should -Not -Match 'Old Title'
        $raw | Should -Match '# Real Body'
        #Only one front matter delimiter pair should remain
        ([regex]::Matches($raw, '(?m)^---$')).Count | Should -Be 2
    }
}
