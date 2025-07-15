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
    
    #Create a temp folder so we don't clobber anything
    $repoTestPath = join-path -path $currentPath -childPath 'repoTest'
    if(!(test-path $repoTestPath)){
        new-item -ItemType Directory -Path $repoTestPath
    }

    #Load This File
    $fileName = $PSCommandPath.Replace('.Tests.ps1','.ps1')
    $functionName = 'remove-mfLocalPsResourceRepository'
    . $fileName
    
    #Param for our RepoName
    $repoName = 'PesterTesting'

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
    remove-item $repoTestPath -Recurse -Force -ErrorAction Ignore
}