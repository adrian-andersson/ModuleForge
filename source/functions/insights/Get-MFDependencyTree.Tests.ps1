[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'
    $mockPsScriptRoot = $sourcePath

    # Resolve dependencies by filename anywhere under source/, so tests stay independent of the folder layout. List order is load order.
    $sourceMap = @{}
    Get-ChildItem -Path $sourcePath -Recurse -Filter '*.ps1' -File | ForEach-Object { if(-not $sourceMap.ContainsKey($_.Name)){ $sourceMap[$_.Name] = $_.FullName } }
    $dependencies = @(
        'Get-MFFolderItems.ps1'
        'Get-MFFolderItemDetails.ps1'
        'printTree.ps1'
    )
    $dependencies.ForEach{
        if($sourceMap.ContainsKey($_)){
            write-verbose "Dependency identified at: $($sourceMap[$_])"
            . $sourceMap[$_]
        }else{
            write-warning "Dependency not found under source: $_"
        }
    }

    
    #Load This File
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')

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