BeforeAll{

    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    $dependencies = [ordered]@{
        functions = @('get-mfGitChangeLog.ps1')
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
}

Describe 'write-mfModuleDocs' {
    BeforeAll {
        Mock Get-Module {
            return [PSCustomObject]@{ Name = 'MockModule'; Version = '1.0.0' }
        }

        
        
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