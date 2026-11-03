[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'

    #Load This File
    $fileName = $PSCommandPath -replace '\.tests\.ps1$','.ps1'
    $functionName = 'Get-MFBuildSummary'
    . $fileName

    #A minimal project with a built module, made directly so this test needs no other source functions
    $projectPath = join-path -path $TestDrive -childPath 'SummaryProject'
    $moduleFolder = join-path -path $projectPath -childPath 'build' -AdditionalChildPath 'SummaryModule'
    $null = New-Item -ItemType Directory -Path $moduleFolder -Force
    [PSCustomObject]@{ moduleName = 'SummaryModule' } | Export-Clixml -Path (join-path $projectPath 'moduleForgeConfig.xml')
    'function Get-One { [Alias("g1")] param() 1 }; function Get-Two { 2 }' | Set-Content (join-path $moduleFolder 'SummaryModule.psm1')
    'class Validator {}' | Set-Content (join-path $moduleFolder 'SummaryModule.Validators.ps1')
    $null = New-Item -ItemType Directory -Path (join-path $moduleFolder 'resource') -Force
    'resource file' | Set-Content (join-path $moduleFolder 'resource' -AdditionalChildPath 'data.txt')
    New-ModuleManifest -Path (join-path $moduleFolder 'SummaryModule.psd1') -RootModule 'SummaryModule.psm1' -ModuleVersion '1.2.3' -Prerelease 'prev003' -PowerShellVersion '7.6' -FunctionsToExport 'Get-One','Get-Two' -AliasesToExport 'g1'

    $nupkgPath = join-path $projectPath 'SummaryModule.1.2.3-prev003.nupkg'
    'not really a package' | Set-Content $nupkgPath

    $summary = Get-MFBuildSummary -ModulePath $projectPath
    $withPackage = Get-MFBuildSummary -ModulePath $projectPath -NugetPackagePath $nupkgPath
}

Describe 'Check Clean Environment' {
    It 'Should have loaded the script directly, not from the module' {
        (get-command $functionName).source | should -BeNullOrEmpty
    }
}

Describe 'Get-MFBuildSummary' {
    It 'Should report the version, including the prerelease label' {
        $summary.Version | Should -Be '1.2.3-prev003'
    }
    It 'Should report the minimum PowerShell version' {
        $summary.PowerShellVersion | Should -Be '7.6'
    }
    It 'Should count exported functions and aliases' {
        $summary.FunctionCount | Should -Be 2
        $summary.AliasCount | Should -Be 1
    }
    It 'Should hash the manifest first, then the module, then any external scripts' {
        $summary.Files.Name | Should -Be @('SummaryModule.psd1','SummaryModule.psm1','SummaryModule.Validators.ps1')
    }
    It 'Should not hash resource files' {
        $summary.Files.Name | Should -Not -Contain 'data.txt'
    }
    It 'Should match Get-FileHash' {
        $expected = (Get-FileHash -Path (join-path $moduleFolder 'SummaryModule.psm1') -Algorithm SHA256).Hash.ToLower()
        ($summary.Files | Where-Object Name -eq 'SummaryModule.psm1').SHA256 | Should -Be $expected
    }
    It 'Should count every built file in the size, resources included' {
        $summary.Markdown | Should -Match 'across 4 files'
    }
    It 'Should include the package when given one' {
        $withPackage.Files.Name | Should -Contain 'SummaryModule.1.2.3-prev003.nupkg'
        $summary.Files.Name | Should -Not -Contain 'SummaryModule.1.2.3-prev003.nupkg'
    }
    It 'Should produce markdown with each hash' {
        foreach($file in $withPackage.Files)
        {
            $withPackage.Markdown | Should -Match ([regex]::Escape("``$($file.SHA256)``"))
        }
    }
    It 'Should throw when there is no build' {
        $emptyProject = join-path $TestDrive 'NoBuild'
        $null = New-Item -ItemType Directory -Path $emptyProject -Force
        [PSCustomObject]@{ moduleName = 'Missing' } | Export-Clixml -Path (join-path $emptyProject 'moduleForgeConfig.xml')
        { Get-MFBuildSummary -ModulePath $emptyProject } | Should -Throw '*Run Build-MFProject first*'
    }
}
