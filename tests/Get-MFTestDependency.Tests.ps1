# NOTE: This lives in the dedicated /tests folder as the script under test is a resource template,
# and neither source/resource nor its tests are discovered alongside functions.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    #Walk up from this test to the project root, so it runs the same from any working directory
    $projectRoot = $PSScriptRoot
    while(!(test-path (join-path -path $projectRoot -childPath 'moduleForgeConfig.xml'))){ $projectRoot = split-path -path $projectRoot -parent; if(!$projectRoot){ throw 'Unable to find moduleForgeConfig.xml above this test' } }
    $scriptPath = join-path -path $projectRoot -childPath 'source' -AdditionalChildPath 'resource','scripts','Get-MFTestDependency.ps1'

    $source = join-path -path $TestDrive -childPath 'source'
    foreach($file in 'functions/Get-One.ps1','functions/sub/Get-Two.ps1','private/Get-Three.ps1','private/Get-Two.ps1.bak','classes/Shared.ps1','enums/Shared.ps1')
    {
        $path = join-path -path $source -childPath $file
        $null = new-item -Path $path -ItemType File -Force
    }
}

Describe 'Get-MFTestDependency' {
    It 'Should return full paths in the order given' {
        $result = & $scriptPath -SourcePath $source -Name 'Get-Three.ps1','Get-One.ps1'
        $result | Should -HaveCount 2
        (Split-Path $result[0] -Leaf) | Should -Be 'Get-Three.ps1'
        (Split-Path $result[1] -Leaf) | Should -Be 'Get-One.ps1'
    }
    It 'Should find a file in a nested folder' {
        & $scriptPath -SourcePath $source -Name 'Get-Two.ps1' | Should -BeLike '*sub*Get-Two.ps1'
    }
    It 'Should match file names case-insensitively' {
        & $scriptPath -SourcePath $source -Name 'get-one.PS1' | Should -BeLike '*Get-One.ps1'
    }
    It 'Should throw for a missing file' {
        { & $scriptPath -SourcePath $source -Name 'Get-Missing.ps1' } | Should -Throw '*Get-Missing.ps1 not found*'
    }
    It 'Should throw for a file name found in two folders' {
        { & $scriptPath -SourcePath $source -Name 'Shared.ps1' } | Should -Throw '*found more than once*'
    }
    It 'Should throw for a name listed twice' {
        { & $scriptPath -SourcePath $source -Name 'Get-One.ps1','get-one.ps1' } | Should -Throw '*listed more than once*'
    }
    It 'Should throw for a missing source folder' {
        { & $scriptPath -SourcePath (join-path $TestDrive 'nope') -Name 'Get-One.ps1' } | Should -Throw '*Source folder not found*'
    }
}
