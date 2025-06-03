BeforeAll{

    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    $tempCopyLocation = join-path -Path $currentPath -ChildPath 'TempCopy'

    $privatePath = join-path $sourcePath -ChildPath 'private'

    $mockPsScriptRoot = $sourcePath

    #Create a temp folder so we don't clobber anything
    $testPath = join-path -path $currentPath -childPath 'gItScaffoldTest'
    if(!(test-path $testPath)){
        new-Item -ItemType Directory -Path $testPath
    }

    Set-Location $testPath
    #Our function checks for a moduleForgeConfig, but doesn't check the contents
    #Creating an empty file should suffice
    new-Item -ItemType File -Name 'moduleForgeConfig.xml'
    
    #Some references to make things easier
    $gIthubFolder = join-path -Path $testPath -ChildPath '.gIthub'
    $prTemplateFile = join-path $gIthubFolder 'PULL_REQUEST_TEMPLATE.md'
    $workflowsFolder = join-path $gIthubFolder 'workflows'
    $pesterTestFile = join-path $workflowsFolder 'pesterTest.yml'
    $buildandreleaseFile = join-path $workflowsFolder 'buildandrelease.yml'


     #Load This File
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')

    
}

Describe 'add-mfGIthubScaffold should Copy Files' {
    BeforeAll{
        add-mfGIthubScaffold
    }

    It 'Should have created the .gIthub folder' {
        get-Item $gIthubFolder|Should -Not -BeNullOrEmpty
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

}

Describe 'add-mfGIthubScaffold should NOT copy if files exist' {
    BeforeAll{
        '#### End of File Change'|Out-File $prTemplateFile -Append
        add-mfGIthubScaffold
    }
    
    It 'Rerunning should not remove our end of file message in the PR Template'  {
        get-Item $prTemplateFile|Should -Not -BeNullOrEmpty
        get-content $prTemplateFile|should -Not -BeNullOrEmpty
        get-content $prTemplateFile|should -Contain '#### End of File Change'
    }

}

Describe 'add-mfGIthubScaffold should copy if files exist and -force is used' {

    BeforeAll{
        add-mfGIthubScaffold -force
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
    remove-Item $testPath -Force -Recurse
}