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

    $tempCopyLocation = join-path -Path $TestDrive -ChildPath 'TempCopy'

    $privatePath = join-path $sourcePath -ChildPath 'private'

    $mockPsScriptRoot = $sourcePath

    #Create a temp folder so we don't clobber anything
    $testPath = join-path -path ([System.IO.Path]::GetTempPath()) -childPath "mfTest_gitScaffoldTest_$(New-Guid)"
    if(!(test-path $testPath)){
        new-Item -ItemType Directory -Path $testPath
    }

    Set-Location $testPath
    #Our function checks for a moduleForgeConfig, but doesn't check the contents
    #Creating an empty file should suffice
    new-Item -ItemType File -Name 'moduleForgeConfig.xml'
    
    #Some references to make things easier
    $githubFolder = join-path -Path $testPath -ChildPath '.github'
    $prTemplateFile = join-path $githubFolder 'PULL_REQUEST_TEMPLATE.md'
    $workflowsFolder = join-path $githubFolder 'workflows'
    $pesterTestFile = join-path $workflowsFolder 'pesterTest.yml'
    $buildandreleaseFile = join-path $workflowsFolder 'buildandrelease.yml'
    $projectRulesExample = join-path $workflowsFolder 'projectRules.yml.example'
    $projectRulesActive = join-path $workflowsFolder 'projectRules.yml'
    $projectRulesScript = join-path (join-path $testPath 'scripts') 'Invoke-MFProjectRules.ps1'


     #Load This File
     $fileName = ($PSCommandPath -replace '\.tests\.ps1$','.ps1')
     $functionName = 'Add-MFGithubScaffold'
    . $fileName
    #The scaffold calls Add-MFProjectScripts, so load it for the call to resolve
    . $PSCommandPath.Replace('Add-MFGithubScaffold.Tests.ps1','Add-MFProjectScripts.ps1')

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

Describe 'Add-MFGithubScaffold should Copy Files' {
    BeforeAll{
        Add-MFGithubScaffold
    }
    It 'Should have created the .github folder' {
        get-Item $githubFolder -force|Should -Not -BeNullOrEmpty
    }
    It 'Should have created the  PR Template' {
        get-Item $prTemplateFile|Should -Not -BeNullOrEmpty
        get-content $prTemplateFile|should -Not -BeNullOrEmpty
    }
    It 'Should have created the workflows folder '  {
        get-Item $workflowsFolder|Should -Not -BeNullOrEmpty
    }
    It 'Should have created the pesterTest file '  {
        get-Item $pesterTestFile|Should -Not -BeNullOrEmpty
        get-content $pesterTestFile|should -Not -BeNullOrEmpty
    }
    It 'Should have created the buildandrelease file '  {
        get-Item $buildandreleaseFile|Should -Not -BeNullOrEmpty
        get-content $buildandreleaseFile|should -Not -BeNullOrEmpty
    }
    It 'Should have left the project rules workflow disabled' {
        $projectRulesExample|Should -Exist
        $projectRulesActive|Should -Not -Exist
    }
    It 'Should have added the script the project rules workflow calls' {
        $projectRulesScript|Should -Exist
    }

}

Describe 'Add-MFGithubScaffold adds the build test' {
    It 'Should have added the buildTest workflow disabled, as .example' {
        (join-path $workflowsFolder 'buildTest.yml.example')|Should -Exist
        (join-path $workflowsFolder 'buildTest.yml')|Should -Not -Exist
    }
    It 'Should have added the generic build test' {
        (join-path $testPath 'buildTest' -AdditionalChildPath 'Module.Build.Tests.ps1')|Should -Exist
    }
    It 'Should keep an edited build test when run again' {
        $buildTestFile = join-path $testPath 'buildTest' -AdditionalChildPath 'Module.Build.Tests.ps1'
        '#my own changes'|Out-File $buildTestFile -Append
        Add-MFGithubScaffold
        get-content $buildTestFile|Should -Contain '#my own changes'
    }
}
Describe 'Add-MFGithubScaffold should NOT copy if files exist' {
    BeforeAll{
        $endOfFileString = "`n#### End of File Change"
        $endOfFileString|Out-File $prTemplateFile -Append
        Add-MFGithubScaffold
    }
    
    It 'Rerunning should not remove our end of file message in the PR Template'  {
        get-Item $prTemplateFile|Should -Not -BeNullOrEmpty
        get-content $prTemplateFile|should -Not -BeNullOrEmpty
        get-content $prTemplateFile|should -Contain '#### End of File Change'
    }

}

Describe 'Add-MFGithubScaffold should copy if files exist and -force is used' {

    BeforeAll{
        Add-MFGithubScaffold -force
    }
    
    It 'Rerunning should not remove our end of file message in the PR Template'  {
        get-Item $prTemplateFile|Should -Not -BeNullOrEmpty
        get-content $prTemplateFile|should -Not -BeNullOrEmpty
        get-content $prTemplateFile|should -Not  -Contain '#### End of File Change'
    }

}



AfterAll{
    Remove-Variable mockPsScriptRoot -ErrorAction Ignore
    Set-Location $currentPath
    remove-Item $testPath -Force -Recurse -ProgressAction SilentlyContinue
}
