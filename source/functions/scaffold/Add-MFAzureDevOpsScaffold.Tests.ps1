[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    $tempCopyLocation = join-path -Path $currentPath -ChildPath 'TempCopy'

    $privatePath = join-path $sourcePath -ChildPath 'private'

    $mockPsScriptRoot = $sourcePath

    #Create a temp folder so we don't clobber anything
    $testPath = join-path -path $currentPath -childPath 'azdScaffoldTest'
    if(!(test-path $testPath)){
        new-Item -ItemType Directory -Path $testPath
    }

    Set-Location $testPath
    #Our function checks for a moduleForgeConfig, but doesn't check the contents
    #Creating an empty file should suffice
    new-Item -ItemType File -Name 'moduleForgeConfig.xml'
    
    #Some references to make things easier
    $azdFolder = join-path -Path $testPath -ChildPath '.azuredevops'
    $prTemplateFile = join-path $azdFolder 'pull_request_template.md'
    $pipelinesFolder = join-path $azdFolder 'pipelines'
    $pesterTestFile = join-path $pipelinesFolder 'pesterTest.yml'
    $buildandreleaseFile = join-path $pipelinesFolder 'buildAndRelease.yml'
    $projectRulesExample = join-path $pipelinesFolder 'projectRules.yml.example'
    $projectRulesActive = join-path $pipelinesFolder 'projectRules.yml'
    $projectRulesScript = join-path (join-path $testPath 'scripts') 'Invoke-MFProjectRules.ps1'


     #Load This File
     $fileName = $PSCommandPath.Replace('.Tests.ps1','.ps1')
     $functionName = 'Add-MFAzureDevOpsScaffold'
    . $fileName
    #The scaffold calls Add-MFProjectScripts, so load it for the call to resolve
    . $PSCommandPath.Replace('Add-MFAzureDevOpsScaffold.Tests.ps1','Add-MFProjectScripts.ps1')


    
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

Describe 'Add-MFAzureDevOpsScaffold should Copy Files' {
    BeforeAll{
        Add-MFAzureDevOpsScaffold
    }
    
    It 'Should have created the .azuredevops folder' {
        get-Item $azdFolder -Force|Should -Not -BeNullOrEmpty
    }
    It 'Should have created the  PR Template' {
        get-Item $prTemplateFile|Should -Not -BeNullOrEmpty
        get-content $prTemplateFile|should -Not -BeNullOrEmpty
    }
    It 'Should have created the pipelines folder '  {
        get-Item $pipelinesFolder|Should -Not -BeNullOrEmpty
    }
    It 'Should have created the pesterTest file '  {
        get-Item $pesterTestFile|Should -Not -BeNullOrEmpty
        get-content $pesterTestFile|should -Not -BeNullOrEmpty
    }
    It 'Should have created the buildandrelease file '  {
        get-Item $buildandreleaseFile|Should -Not -BeNullOrEmpty
        get-content $buildandreleaseFile|should -Not -BeNullOrEmpty
    }
    It 'Should have left the project rules pipeline disabled' {
        $projectRulesExample|Should -Exist
        $projectRulesActive|Should -Not -Exist
    }
    It 'Should have added the script the project rules pipeline calls' {
        $projectRulesScript|Should -Exist
    }

}

Describe 'Add-MFAzureDevOpsScaffold should NOT copy if files exist' {
    BeforeAll{
        $endOfFileString = "`n#### End of File Change"
        $endOfFileString|Out-File $prTemplateFile -Append
        Add-MFAzureDevOpsScaffold
    }
    
    It 'Rerunning should not remove our end of file message in the PR Template'  {
        get-Item $prTemplateFile|Should -Not -BeNullOrEmpty
        get-content $prTemplateFile|should -Not -BeNullOrEmpty
        get-content $prTemplateFile|should -Contain '#### End of File Change'
    }

}

Describe 'Add-MFAzureDevOpsScaffold should copy if files exist and -force is used' {

    BeforeAll{
        Add-MFAzureDevOpsScaffold -force
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