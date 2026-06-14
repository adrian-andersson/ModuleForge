[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'

    #Load This File (the function lives alongside this test in source/private)
    $fileName = $PSCommandPath.Replace('.Tests.ps1','.ps1')
    $functionName = 'Get-MFH1FromFile'
    . $fileName

    #Temp working folder. Use GetTempPath for cross-platform safety (env:TEMP is null on Linux CI)
    $testFolder = join-path -path ([System.IO.Path]::GetTempPath()) -childPath "mfTest_GetMFH1_$(New-Guid)"
    new-item -ItemType Directory -Path $testFolder | out-null

    $h1File = join-path -path $testFolder -childPath 'withH1.md'
    Set-Content -Path $h1File -Value @('Some intro text', '# Real Title', '## A subheading', '# A second H1')

    $noH1File = join-path -path $testFolder -childPath 'noH1.md'
    Set-Content -Path $noH1File -Value @('## Only a subheading', 'plain text')

    $paddedFile = join-path -path $testFolder -childPath 'padded.md'
    Set-Content -Path $paddedFile -Value @('#    Padded Heading   ')

}

AfterAll{
    Remove-Item $testFolder -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Check Clean Environment' {
    It 'Should have loaded the function directly, not from an imported module' {
        (get-command $functionName).source | should -BeNullOrEmpty
    }
}

Describe 'Get-MFH1FromFile' {
    It 'Returns the first H1 heading' {
        Get-MFH1FromFile -FilePath $h1File | Should -Be 'Real Title'
    }

    It 'Returns null when no H1 is present' {
        Get-MFH1FromFile -FilePath $noH1File | Should -BeNullOrEmpty
    }

    It 'Trims surrounding whitespace from the heading text' {
        Get-MFH1FromFile -FilePath $paddedFile | Should -Be 'Padded Heading'
    }

    It 'Accepts pipeline input' {
        $h1File | Get-MFH1FromFile | Should -Be 'Real Title'
    }
}
