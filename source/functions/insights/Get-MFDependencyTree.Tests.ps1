[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Reference Current Path
    $currentPath = $(get-location).path
    #Walk up from this test to the project root, so it runs the same from any working directory
    $projectRoot = $PSScriptRoot
    while(!(test-path (join-path -path $projectRoot -childPath 'moduleForgeConfig.xml'))){ $projectRoot = split-path -path $projectRoot -parent; if(!$projectRoot){ throw 'Unable to find moduleForgeConfig.xml above this test' } }
    $sourcePath = join-path -path $projectRoot -childPath 'source'
    $mockPsScriptRoot = $sourcePath

    #Dependencies by filename anywhere under source/, loaded in this order. Throws if a name is missing or found more than once
    $dependencies = & (join-path -path $sourcePath -childPath 'resource' -AdditionalChildPath 'scripts','Get-MFTestDependency.ps1') -SourcePath $sourcePath -Name @(
        'Get-MFFolderItems.ps1'
        'Get-MFFolderItemDetails.ps1'
        'printTree.ps1'
    )
    $dependencies.ForEach{ . $_ }

    
    #Load This File
    . ($PSCommandPath -replace '\.tests\.ps1$','.ps1')

}

Describe 'Get-MFDependencyTree' {

    BeforeAll {
        $folderItemDetails = get-mfFolderItemDetails -path $sourcePath
        $depTree = Get-MFDependencyTree -referenceData $($folderItemDetails|Select-Object relativePath,Dependencies)
        $Mermaid = Get-MFDependencyTree -referenceData $($folderItemDetails|Select-Object relativePath,Dependencies) -outputType mermaid
    }

    It 'Should have returned more than 5 lines of output' {
        $depTree.Count | Should -BeGreaterThan 5
    }
    It 'Should have Correctly outputted a dependency' {
        # Layout-agnostic: assert the Get-MFFolderItemDetails -> Get-MFFolderItems dependency by filename, not by folder path
        $joined = $depTree -join "`n"
        $joined | Should -Match 'Get-MFFolderItemDetails\.ps1'
        $joined | Should -Match '>--DEPENDS-ON-->.*Get-MFFolderItems\.ps1'
    }
    It 'Should have made a Mermaid chart' {
        # Layout-agnostic: the mermaid flowchart should contain the Build-MFProject -> Get-MFDependencyTree arrow by filename
        $joinedMermaid = $Mermaid -join "`n"
        $joinedMermaid | Should -Match 'flowchart TD'
        $joinedMermaid | Should -Match "Build-MFProject\.ps1' --> '[^']*Get-MFDependencyTree\.ps1'"
    }


}
