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

Describe 'Get-MFDependencyTree with shared and circular dependencies' {

    BeforeAll {
        #Builds reference data in the same shape as get-mfFolderItemDetails, from a hashtable of file = dependencies
        function newReferenceData {
            param([System.Collections.Specialized.OrderedDictionary]$Files)
            foreach ($file in $Files.Keys) {
                [PSCustomObject]@{
                    relativePath = $file
                    Dependencies = @($Files[$file].ForEach{ [PSCustomObject]@{ ReferenceFile = $_ } })
                }
            }
        }

        #Diamond: A and B both lead to D, so D's dependencies should only be printed once
        $diamond = newReferenceData -Files ([ordered]@{
            'A.ps1' = @('B.ps1','C.ps1')
            'B.ps1' = @('D.ps1')
            'C.ps1' = @('D.ps1')
            'D.ps1' = @('E.ps1')
            'E.ps1' = @()
        })
        $diamondTree = Get-MFDependencyTree -ReferenceData $diamond

        #Loop: X -> Y -> Z -> X, nothing outside the loop
        $loop = newReferenceData -Files ([ordered]@{
            'X.ps1' = @('Y.ps1')
            'Y.ps1' = @('Z.ps1')
            'Z.ps1' = @('X.ps1','X.ps1')
        })
        $loopTree = Get-MFDependencyTree -ReferenceData $loop
        $loopMermaid = Get-MFDependencyTree -ReferenceData $loop -OutputType Mermaid
    }

    It 'Should start from the file nothing depends on' {
        $diamondTree[0] | Should -Be 'A.ps1'
    }

    It 'Should not print a file as a root once it has been shown under another file' {
        @($diamondTree.where{$_ -match '^\S'}) | Should -Be @('A.ps1')
    }

    It 'Should expand a shared dependency only once' {
        @($diamondTree.where{$_ -match 'E\.ps1'}).Count | Should -Be 1
        @($diamondTree.where{$_ -match 'D\.ps1 \(dependencies shown above\)'}).Count | Should -Be 1
    }

    It 'Should finish and flag a circular reference' {
        $loopTree[0] | Should -Be 'X.ps1'
        @($loopTree.where{$_ -match 'X\.ps1 \(circular reference\)'}).Count | Should -Be 1
        $loopTree.Count | Should -Be 4
    }

    It 'Should return nothing, without error, when no file has dependencies' {
        $none = newReferenceData -Files ([ordered]@{ 'Alone.ps1' = @(); 'AlsoAlone.ps1' = @() })
        { Get-MFDependencyTree -ReferenceData $none -ErrorAction Stop } | Should -Not -Throw
        Get-MFDependencyTree -ReferenceData $none | Should -BeNullOrEmpty
    }

    It 'Should not repeat an arrow in the Mermaid chart' {
        @(($loopMermaid -split "`n").where{$_ -eq "'Z.ps1' --> 'X.ps1'"}).Count | Should -Be 1
    }
}
