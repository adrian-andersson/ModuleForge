[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    $dependencies = [ordered]@{
        functions = @('Get-MFFolderItems.ps1')
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

Describe 'Get-MFFolderItemDetails' {

    BeforeAll {
        $folderItemDetails = Get-MFFolderItemDetails -path $sourcePath
    }

    It 'Should have returned more than 10 of items' {
        $folderItemDetails.Count | Should -BeGreaterThan 10
    }
    It 'Should have function and private groups' {
        $folderItemDetails.group | Should -Contain 'functions'
        $folderItemDetails.group | Should -Contain 'private'
    }
    It 'Should have the correct function names' {
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Add-MFRepositoryXmlData'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Build-MFProject'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Get-MFDependencyTree'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Get-MFFolderItemDetails'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Get-MFFolderItems'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Get-MFNextSemver'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'New-MFProject'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Register-MFLocalPsResourceRepository'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Remove-MFLocalPsResourceRepository'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Update-MFProject'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Add-MFFilesAndFolders'
    }
    It 'Should return appropriate dependencies' {
        $folderItemDetails.where{$_.name -eq 'Get-MFFolderItemDetails.ps1'}.Dependencies.Reference | Should -be 'Get-MFFolderItems'
    }


}