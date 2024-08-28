BeforeAll{

    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    $dependencies = [ordered]@{
        functions = @('register-mfLocalPsResourceRepository.ps1')
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
    
    #Create a temp folder so we don't clobber anything
    $repoTestPath = join-path -path $currentPath -childPath 'repoTest'

    $repoName = 'PesterTesting'

}

Describe 'remove-mfLocalPsResourceRepository' {
    BeforeAll {
        register-mfLocalPsResourceRepository -repositoryName $repoName -path $repoTestPath
    }

    it 'Should have registered a local repository' {
        (get-psResourceRepository).Name |Should -Contain $repoName
    }

    it 'Should unregister the repository Correctly' {
        remove-mfLocalPsResourceRepository -repositoryName $repoName -path $repoTestPath
        (get-psResourceRepository).Name |Should -Not -Contain $repoName
    }
}

AfterAll{
    remove-item repoTest -Recurse -Force
}