# NOTE: This test deliberately lives in the dedicated /tests folder rather than alongside its
# function in source/private. Its sibling private tests were moved to source/private (co-located).
# This one is kept here on purpose: it exercises the optional root 'tests' folder discovery path
# (so we have a working test OF that feature) and serves as a worked example for anyone who prefers
# the separate-tests-folder convention. Because it is not co-located, it resolves the function under
# test by filename anywhere under source/ (layout-independent) instead of the $PSCommandPath trick.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Reference Current Path. Invoke-MFPester sets the working directory to the project root before running
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    #This test lives in the dedicated /tests folder, not alongside the function, so we cannot use the
    #$PSCommandPath co-location trick. Resolve the function by filename anywhere under source/ instead.
    $sourceMap = @{}
    Get-ChildItem -Path $sourcePath -Recurse -Filter '*.ps1' -File | ForEach-Object { if(-not $sourceMap.ContainsKey($_.Name)){ $sourceMap[$_.Name] = $_.FullName } }
    $fileName = $sourceMap['ConvertTo-MFNavTitle.ps1']
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
