# NOTE: This test deliberately lives in the dedicated /tests folder rather than alongside its
# function in source/private. Its sibling private tests were moved to source/private (co-located).
# This one is kept here on purpose: it exercises the optional root 'tests' folder discovery path
# (so we have a working test OF that feature) and serves as a worked example for anyone who prefers
# the separate-tests-folder convention. Because it is not co-located, it resolves the function under
# test by filename anywhere under source/ (layout-independent) instead of the $PSCommandPath trick.
# For a project scaffolded by ModuleForge, the helper it uses is scripts/Get-MFTestDependency.ps1.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Reference Current Path. Invoke-MFPester sets the working directory to the project root before running
    $currentPath = $(get-location).path
    #Walk up from this test to the project root, so it runs the same from any working directory
    $projectRoot = $PSScriptRoot
    while(!(test-path (join-path -path $projectRoot -childPath 'moduleForgeConfig.xml'))){ $projectRoot = split-path -path $projectRoot -parent; if(!$projectRoot){ throw 'Unable to find moduleForgeConfig.xml above this test' } }
    $sourcePath = join-path -path $projectRoot -childPath 'source'

    #This test lives in the dedicated /tests folder, not alongside the function, so we cannot use the
    #$PSCommandPath co-location trick. Resolve the function by filename anywhere under source/ instead.
    #Throws if it is missing or found more than once
    $fileName = & (join-path -path $sourcePath -childPath 'resource' -AdditionalChildPath 'scripts','Get-MFTestDependency.ps1') -SourcePath $sourcePath -Name 'ConvertTo-MFNavTitle.ps1'
    $functionName = 'ConvertTo-MFNavTitle'
    . $fileName

}

Describe 'Check Clean Environment' {
    It 'Should have loaded the function directly, not from an imported module' {
        (get-command $functionName).source | should -BeNullOrEmpty
    }
}

Describe 'ConvertTo-MFNavTitle' {
    It 'Splits camelCase boundaries and title-cases' {
        ConvertTo-MFNavTitle -FolderName 'azureDevOps' | Should -Be 'Azure Dev Ops'
    }

    It 'Splits hyphenated names' {
        ConvertTo-MFNavTitle -FolderName 'my-folder' | Should -Be 'My Folder'
    }

    It 'Splits underscored names' {
        ConvertTo-MFNavTitle -FolderName 'my_folder_name' | Should -Be 'My Folder Name'
    }

    It 'Leaves a single lowercase word title-cased' {
        ConvertTo-MFNavTitle -FolderName 'functions' | Should -Be 'Functions'
    }

    It 'Accepts pipeline input' {
        'getStarted' | ConvertTo-MFNavTitle | Should -Be 'Get Started'
    }
}
