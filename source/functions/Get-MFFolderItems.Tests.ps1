[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    
    #Load This File
     $fileName = $PSCommandPath.Replace('.Tests.ps1','.ps1')
     $functionName = 'Get-MFFolderItems'
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

Describe 'Get-MFFolderItems' {

    BeforeAll {
        $folderItems = Get-MFFolderItems -path $sourcePath -psScriptsOnly
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

Describe 'Get-MFFolderItems w trailing directory separator' {
    BeforeAll {
        $sourcePath2 = "$sourcePath$([IO.Path]::DirectorySeparatorChar)"
        $folderItems = Get-MFFolderItems -path $sourcePath2 -psScriptsOnly
    }

    It 'Should have returned more than 10 of items, even though we added a trailing / to the discovery' {
        $folderItems.Count | Should -BeGreaterThan 10
    }

}

Describe 'Get-MFFolderItems w Copy' {
    BeforeAll {
        new-item -ItemType Directory -Path $tempCopyLocation
        $folderItems = Get-MFFolderItems -path $privatePath -copy -destination $tempCopyLocation
    }

    It 'Should have returned 1 item' {
        (get-childItem $tempCopyLocation).count | Should -BeGreaterOrEqual 1
    }
}


Describe 'Get-MFFolderItems throws on invalid destination' {
    It 'Should throw when the destination path does not exist' {
        $invalidDest = join-path $currentPath 'NonExistentDestination99999'
        { Get-MFFolderItems -Path $sourcePath -Destination $invalidDest } | Should -Throw
    }
    It 'Should handle a destination path with a trailing separator' {
        $trailingDest = "$($tempCopyLocation)$([IO.Path]::DirectorySeparatorChar)"
        New-Item -ItemType Directory -Path $tempCopyLocation -Force | Out-Null
        { Get-MFFolderItems -Path $privatePath -Destination $trailingDest } | Should -Not -Throw
    }
    AfterAll {
        Remove-Item $tempCopyLocation -Recurse -Force -ErrorAction Ignore -ProgressAction SilentlyContinue
    }
}

Describe 'Get-MFFolderItems respects .mfignore' {
    BeforeAll {
        $ignorePath = join-path $currentPath 'MFIgnoreTest'
        new-item -ItemType Directory -Path $ignorePath
        'function include-me {}' | Out-File (join-path $ignorePath 'include-me.ps1')
        'function exclude-me {}' | Out-File (join-path $ignorePath 'exclude-me.ps1')
        'exclude-me.ps1' | Out-File (join-path $ignorePath '.mfignore')
        $ignoreItems = Get-MFFolderItems -Path $ignorePath -PSScriptsOnly
    }
    It 'Should not return the file listed in .mfignore' {
        $ignoreItems.Name | Should -Not -Contain 'exclude-me.ps1'
    }
    It 'Should still return files not listed in .mfignore' {
        $ignoreItems.Name | Should -Contain 'include-me.ps1'
    }
    AfterAll {
        Remove-Item $ignorePath -Recurse -Force -ErrorAction Ignore -ProgressAction SilentlyContinue
    }
}

AfterAll {
    remove-item -Recurse -Path $tempCopyLocation -Force -ErrorAction Ignore -ProgressAction SilentlyContinue
}