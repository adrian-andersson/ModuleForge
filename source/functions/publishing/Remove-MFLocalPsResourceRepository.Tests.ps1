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

    #Dependencies by filename anywhere under source/, loaded in this order. Throws if a name is missing or found more than once
    $dependencies = & (join-path -path $sourcePath -childPath 'resource' -AdditionalChildPath 'scripts','Get-MFTestDependency.ps1') -SourcePath $sourcePath -Name @(
        'Register-MFLocalPsResourceRepository.ps1'
    )
    $dependencies.ForEach{ . $_ }
    
    #Create a temp folder so we don't clobber anything
    $repoTestPath = join-path -path $TestDrive -childPath 'repoTest'
    if(!(test-path $repoTestPath)){
        new-item -ItemType Directory -Path $repoTestPath
    }

    #Load This File
    $fileName = ($PSCommandPath -replace '\.tests\.ps1$','.ps1')
    $functionName = 'Register-MFLocalPsResourceRepository'
    . $fileName
    
    #Param for our RepoName
    $repoName = 'PesterTesting'

}

Describe 'Check Clean Environment' {
    BeforeAll {
        write-warning "PSCommandPath: $psCommandPath; scriptToLoad: $(($PSCommandPath -replace '\.tests\.ps1$','.ps1'))"
    }
    It 'Should have loaded the script directly, not from the module' {
        ($PSCommandPath -replace '\.tests\.ps1$','.ps1')|should -be $fileName
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
