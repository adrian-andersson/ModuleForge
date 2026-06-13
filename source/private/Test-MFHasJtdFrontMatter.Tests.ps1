[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'

    #Load This File (the function lives alongside this test in source/private)
    $fileName = $PSCommandPath.Replace('.Tests.ps1','.ps1')
    $functionName = 'Test-MFHasJtdFrontMatter'
    . $fileName

    #Temp working folder. Use GetTempPath for cross-platform safety (env:TEMP is null on Linux CI)
    $testFolder = join-path -path ([System.IO.Path]::GetTempPath()) -childPath "mfTest_JtdFrontMatter_$(New-Guid)"
    new-item -ItemType Directory -Path $testFolder | out-null

    $withLayout = join-path -path $testFolder -childPath 'withLayout.md'
    Set-Content -Path $withLayout -Value @('---', 'layout: default', 'title: Example', '---', '# Body')

    $withoutLayout = join-path -path $testFolder -childPath 'withoutLayout.md'
    Set-Content -Path $withoutLayout -Value @('---', 'title: Example', 'nav_order: 2', '---', '# Body')

    $noFrontMatter = join-path -path $testFolder -childPath 'noFrontMatter.md'
    Set-Content -Path $noFrontMatter -Value @('# Just a heading', 'Some content')

}

AfterAll{
    Remove-Item $testFolder -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Check Clean Environment' {
    It 'Should have loaded the function directly, not from an imported module' {
        (get-command $functionName).source | should -BeNullOrEmpty
    }
}

Describe 'Test-MFHasJtdFrontMatter' {
    It 'Returns true when front matter contains a layout key' {
        Test-MFHasJtdFrontMatter -FilePath $withLayout | Should -BeTrue
    }

    It 'Returns false when front matter has no layout key' {
        Test-MFHasJtdFrontMatter -FilePath $withoutLayout | Should -BeFalse
    }

    It 'Returns false when the file has no front matter block' {
        Test-MFHasJtdFrontMatter -FilePath $noFrontMatter | Should -BeFalse
    }

    It 'Accepts pipeline input' {
        $withLayout | Test-MFHasJtdFrontMatter | Should -BeTrue
    }
}
