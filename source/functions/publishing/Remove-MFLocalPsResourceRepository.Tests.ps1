[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    # Resolve dependencies by filename anywhere under source/, so tests stay independent of the folder layout. List order is load order.
    $sourceMap = @{}
    Get-ChildItem -Path $sourcePath -Recurse -Filter '*.ps1' -File | ForEach-Object { if(-not $sourceMap.ContainsKey($_.Name)){ $sourceMap[$_.Name] = $_.FullName } }
    $dependencies = @(
        'Register-MFLocalPsResourceRepository.ps1'
    )
    $dependencies.ForEach{
        if($sourceMap.ContainsKey($_)){
            write-verbose "Dependency identified at: $($sourceMap[$_])"
            . $sourceMap[$_]
        }else{
            write-warning "Dependency not found under source: $_"
        }
    }
    
    #Create a temp folder so we don't clobber anything
    $repoTestPath = join-path -path $currentPath -childPath 'repoTest'
    if(!(test-path $repoTestPath)){
        new-item -ItemType Directory -Path $repoTestPath
    }

    #Load This File
    $fileName = $PSCommandPath.Replace('.Tests.ps1','.ps1')
    $functionName = 'Register-MFLocalPsResourceRepository'
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

Describe 'Remove-MFLocalPsResourceRepository' {
    BeforeAll {
        Register-MFLocalPsResourceRepository -repositoryName $repoName -path $repoTestPath
    }

    it 'Should have registered a local repository' {
        (get-psResourceRepository).Name |Should -Contain $repoName
    }

    it 'Should unregister the repository Correctly' {
        Remove-MFLocalPsResourceRepository -repositoryName $repoName -path $repoTestPath
        (get-psResourceRepository).Name |Should -Not -Contain $repoName
    }
}


AfterAll{
    remove-item $repoTestPath -Recurse -Force -ErrorAction Ignore -ProgressAction SilentlyContinue
}