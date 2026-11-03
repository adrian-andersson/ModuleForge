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
    It 'Should have created the Invoke-MFProjectRules script' {
        Join-Path $scriptsFolder 'Invoke-MFProjectRules.ps1' | Should -Exist
    }
    It 'Should have created the Install-MFBuildDependencies script' {
        Join-Path $scriptsFolder 'Install-MFBuildDependencies.ps1' | Should -Exist
    }
    It 'Should have added BuildDependencies.psd1 to the project root, not the scripts folder' {
        Join-Path $testPath 'BuildDependencies.psd1' | Should -Exist
        Join-Path $scriptsFolder 'BuildDependencies.psd1' | Should -Not -Exist
    }
    It 'Should leave the ModuleForge pin as the template has it when not run from the module' {
        #Dot-sourced here, so there is no running module to pin to
        (Import-PowerShellDataFile (Join-Path $testPath 'BuildDependencies.psd1')).ModuleForge.version | Should -Be '[1.4.0, 2.0.0)'
    }
}

Describe 'Add-MFProjectScripts pins ModuleForge to the running version' {
    BeforeAll{
        #Run it from inside a throwaway module, as it would be from ModuleForge itself
        $pinPath = Join-Path $TestDrive 'pinProject'
        $null = New-Item -ItemType Directory -Path $pinPath -Force
        $functionText = Get-Content -Path $PSCommandPath.Replace('.Tests.ps1','.ps1') -Raw
        $fakeModule = New-Module -Name 'FakeModuleForge' -ScriptBlock ([scriptblock]::Create("$functionText`nExport-ModuleMember -Function Add-MFProjectScripts"))
        $pinVersion = $fakeModule.Version
    }
    It 'Should pin ModuleForge from the running version up to the next major' {
        & $fakeModule { param($root,$path) $mockPsScriptRoot = $root; Add-MFProjectScripts -ModulePath $path -WarningAction SilentlyContinue } $mockPsScriptRoot $pinPath
        $pin = (Import-PowerShellDataFile (Join-Path $pinPath 'BuildDependencies.psd1')).ModuleForge
        $pin.version | Should -Be "[$($pinVersion.Major).$($pinVersion.Minor).$($pinVersion.Build), $($pinVersion.Major + 1).0.0)"
        $pin.repository | Should -Be 'PSGallery'
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