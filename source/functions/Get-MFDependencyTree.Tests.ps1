[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    $dependencies = [ordered]@{
        functions = @('Get-MFFolderItems.ps1','Get-MFFolderItemDetails.ps1')
        private = @('printTree.ps1')
    }

    $dependencies.GetEnumerator().ForEach{
        $DirectoryRef = join-path -path $sourcePath -childPath $_.Key
        $_.Value.ForEach{
            $ItemPath = join-path -path $DirectoryRef -childpath $_
            $ItemRef = get-item $ItemPath -ErrorAction SilentlyContinue
            if($ItemRef){
                write-verbose "Dependency identified at: $($ItemRef.fullname)"
                . $ItemRef.Fullname
            }else{
                write-warning "Dependency not found at: $ItemPath"
            }
        }
    }

    
    #Load This File
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')

}

Describe 'Get-MFDependencyTree' {

    BeforeAll {
        $folderItemDetails = get-mfFolderItemDetails -path $sourcePath
        $depTree = Get-MFDependencyTree -referenceData $($folderItemDetails|Select-Object relativePath,Dependencies)
        $c1Ref = ".$([IO.Path]::DirectorySeparatorChar)source$([IO.Path]::DirectorySeparatorChar)functions$([IO.Path]::DirectorySeparatorChar)get-mfFolderItemDetails.ps1"
        $c2Ref = "     >--DEPENDS-ON--> .$([IO.Path]::DirectorySeparatorChar)source$([IO.Path]::DirectorySeparatorChar)functions$([IO.Path]::DirectorySeparatorChar)get-mfFolderItems.ps1"
        $Mermaid = Get-MFDependencyTree -referenceData $($folderItemDetails|Select-Object relativePath,Dependencies) -outputType mermaid
        $mermaidRef = "'.\source\functions\build-mfProject.ps1' --> '.\source\functions\Get-MFDependencyTree.ps1'"
    }

    It 'Should have returned more than 5 lines of output' {
        $depTree.Count | Should -BeGreaterThan 5
    }
    It 'Should have Correctly outputted a dependency' {
        $depTree| Should -Contain $c1Ref
        $depTree| Should -Contain $c2Ref
    }
    It 'Should have made a Mermaid chart' {
        $mermaidRef | Should -Contain $mermaidRef
    }


}