[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    $currentPath = $(Get-Location).path
    $sourcePath = Join-Path $currentPath 'source'

    $mockPsScriptRoot = $sourcePath

    $testPath = Join-Path $currentPath 'scriptScaffoldTest'
    if(!(Test-Path $testPath)){
        New-Item -ItemType Directory -Path $testPath
    }

    Set-Location $testPath

    $scriptsFolder  = Join-Path $testPath 'scripts'
    $pesterScript   = Join-Path $scriptsFolder 'Invoke-MFPester.ps1'

    $fileName     = $PSCommandPath.Replace('.Tests.ps1','.ps1')
    $functionName = 'Add-MFProjectScripts'
    . $fileName

}

Describe 'Check Clean Environment' {
    BeforeAll {
        Write-Warning "PSCommandPath: $PSCommandPath; scriptToLoad: $($PSCommandPath.Replace('.Tests.ps1','.ps1'))"
    }
    It 'Should have loaded the script directly, not from the module' {
        $PSCommandPath.Replace('.Tests.ps1','.ps1') | Should -be $fileName
        (Get-Command $functionName).source | Should -BeNullOrEmpty
    }
}

Describe 'Add-MFProjectScripts should Copy Files' {
    BeforeAll{
        Add-MFProjectScripts -WarningAction SilentlyContinue
    }
    It 'Should have created the scripts folder' {
        Get-Item $scriptsFolder -Force | Should -Not -BeNullOrEmpty
    }
    It 'Should have created the Invoke-MFPester script' {
        Get-Item $pesterScript | Should -Not -BeNullOrEmpty
        Get-Content $pesterScript | Should -Not -BeNullOrEmpty
    }
}

Describe 'Add-MFProjectScripts should NOT copy if files exist' {
    BeforeAll{
        $endOfFileString = "`n#### End of File Change"
        $endOfFileString | Out-File $pesterScript -Append
        Add-MFProjectScripts -WarningAction SilentlyContinue
    }

    It 'Rerunning should not overwrite our end of file message in the Pester script' {
        Get-Item $pesterScript | Should -Not -BeNullOrEmpty
        Get-Content $pesterScript | Should -Not -BeNullOrEmpty
        Get-Content $pesterScript | Should -Contain '#### End of File Change'
    }
}

Describe 'Add-MFProjectScripts should copy if files exist and -Force is used' {
    BeforeAll{
        Add-MFProjectScripts -Force -WarningAction SilentlyContinue
    }

    It 'Rerunning with -Force should remove our end of file message from the Pester script' {
        Get-Item $pesterScript | Should -Not -BeNullOrEmpty
        Get-Content $pesterScript | Should -Not -BeNullOrEmpty
        Get-Content $pesterScript | Should -Not -Contain '#### End of File Change'
    }
}


AfterAll{
    Remove-Variable mockPsScriptRoot -ErrorAction Ignore
    Set-Location $currentPath
    Remove-Item $testPath -Force -Recurse -ProgressAction SilentlyContinue
}