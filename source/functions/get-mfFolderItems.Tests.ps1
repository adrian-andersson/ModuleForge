BeforeAll{

    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    
    #Load This File
     $fileName = $PSCommandPath.Replace('.Tests.ps1','.ps1')
     $functionName = 'get-mfFolderItems'
    . $fileName

    $tempCopyLocation = join-path -Path $currentPath -ChildPath 'TempCopy'

    $privatePath = join-path $sourcePath -ChildPath 'private'

}

Describe 'Check Clean Environment' {
    BeforeAll {
        write-warning "PSCommandPath: $psCommandPath; scriptToLoad: $($PSCommandPath.Replace('.Tests.ps1','.ps1'))"
    }
    It 'Should have loaded the script directly, not from the module' {
        $PSCommandPath.Replace('.Tests.ps1','.ps1')|should -be $fileName
        (get-command $functionName).source |should -BeNullOrEmpty
    }
}

Describe 'get-mfFolderItems' {

    BeforeAll {
        $folderItems = get-mfFolderItems -path $sourcePath -psScriptsOnly
        $relativePath = join-path $(join-path '.' -ChildPath 'functions') -ChildPath 'build-mfProject.ps1'
    }

    It 'Should have returned more than 10 of items' {
        $folderItems.Count | Should -BeGreaterThan 10
    }
    It 'Should have a build-mfProject.ps1 item' {
        $folderItems.Name | Should -Contain 'build-mfProject.ps1'
        $folderItems.RelativePath | Should -Contain $relativePath
        $folderItems.Folder
    }

}

Describe 'get-mfFolderItems w trailing directory separator' {
    BeforeAll {
        $sourcePath2 = "$sourcePath$([IO.Path]::DirectorySeparatorChar)"
        $folderItems = get-mfFolderItems -path $sourcePath2 -psScriptsOnly
    }

    It 'Should have returned more than 10 of items, even though we added a trailing / to the discovery' {
        $folderItems.Count | Should -BeGreaterThan 10
    }

}

Describe 'get-mfFolderItems w Copy' {
    BeforeAll {
        new-item -ItemType Directory -Path $tempCopyLocation
        $folderItems = get-mfFolderItems -path $privatePath -copy -destination $tempCopyLocation
    }

    It 'Should have returned 1 item' {
        (get-childItem $tempCopyLocation).count | Should -BeGreaterOrEqual 1
    }
}


AfterAll {
    remove-item -Recurse -Path $tempCopyLocation -Force -ErrorAction Ignore
}