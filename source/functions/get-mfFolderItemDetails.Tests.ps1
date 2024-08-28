BeforeAll{

    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    $dependencies = [ordered]@{
        functions = @('get-mfFolderItems.ps1')
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

Describe 'get-mfFolderItemDetails' {

    BeforeAll {
        $folderItemDetails = get-mfFolderItemDetails -path $sourcePath
    }

    It 'Should have returned more than 10 of items' {
        $folderItemDetails.Count | Should -BeGreaterThan 10
    }
    It 'Should have function and private groups' {
        $folderItemDetails.group | Should -Contain 'functions'
        $folderItemDetails.group | Should -Contain 'private'
    }
    It 'Should have the correct function names' {
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'add-mfRepositoryXmlData'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'build-mfProject'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'get-mfDependencyTree'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'get-mfFolderItemDetails'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'get-mfFolderItems'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'get-mfNextSemver'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'new-mfProject'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'register-mfLocalPsResourceRepository'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'remove-mfLocalPsResourceRepository'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'update-mfProject'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'add-mfFilesAndFolders'
    }
    It 'Should return appropriate dependencies' {
        $folderItemDetails.where{$_.name -eq 'get-mfFolderItemDetails.ps1'}.Dependencies.Reference | Should -be 'get-mfFolderItems'
    }


}