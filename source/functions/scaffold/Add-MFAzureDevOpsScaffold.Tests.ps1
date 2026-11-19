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
    $testPath = join-path -path ([System.IO.Path]::GetTempPath()) -childPath "mfTest_azdScaffoldTest_$(New-Guid)"
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
     $fileName = ($PSCommandPath -replace '\.tests\.ps1$','.ps1')
     $functionName = 'Add-MFAzureDevOpsScaffold'
    . $fileName
    #The scaffold calls Add-MFProjectScripts, so load it for the call to resolve
    . $PSCommandPath.Replace('Add-MFAzureDevOpsScaffold.Tests.ps1','Add-MFProjectScripts.ps1')


    
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

Describe 'Add-MFAzureDevOpsScaffold adds the build test' {
    It 'Should have added the buildTest pipeline disabled, as .example' {
        (join-path $pipelinesFolder 'buildTest.yml.example')|Should -Exist
        (join-path $pipelinesFolder 'buildTest.yml')|Should -Not -Exist
    }
    It 'Should have added the generic build test' {
        (join-path $testPath 'buildTest' -AdditionalChildPath 'Module.Build.Tests.ps1')|Should -Exist
    }
    It 'Should keep an edited build test when run again' {
        $buildTestFile = join-path $testPath 'buildTest' -AdditionalChildPath 'Module.Build.Tests.ps1'
        '#my own changes'|Out-File $buildTestFile -Append
        Add-MFAzureDevOpsScaffold
        get-content $buildTestFile|Should -Contain '#my own changes'
    }
}
Describe 'Add-MFAzureDevOpsScaffold Pester pipeline' {
    It 'Should not fail the test run when coverage cannot be published' {
        #Publishing coverage fails when a project's Test Plans service is off, which must not block a pull request
        $text = Get-Content -Path $pesterTestFile -Raw
        $text | Should -Match '(?s)- task: PublishCodeCoverageResults@\d+.*?continueOnError: true.*?displayName:'
    }
}

Describe 'Add-MFAzureDevOpsScaffold Azure Artifacts feeds' {
    It 'Should publish to the feed the pipeline found, so project and organization feeds both work' {
        $text = Get-Content -Path $buildandreleaseFile -Raw
        $text | Should -Match "publishVstsFeed: '\$\(publishFeed\)'"
        $text | Should -Match 'variable=publishFeed'
    }
}

Describe 'Build and Release form matches GitHub' {
    BeforeAll {
        #The release choices, including the commented-out Stable Release ones, in the order they appear
        $optionPattern = "(?m)^\s*#?\s*- '((?:Next Prerelease|New Prerelease Series|Promote to Stable|Stable Release)[^']*)'"
        $azdText = Get-Content -Path (join-path $sourcePath 'resource' -AdditionalChildPath 'azureDevOps','pipelines','buildAndRelease.yml') -Raw
        $ghText = Get-Content -Path (join-path $sourcePath 'resource' -AdditionalChildPath 'github','workflows','buildandrelease.yml') -Raw
        $azdOptions = [regex]::Matches($azdText, $optionPattern).ForEach{ $_.Groups[1].Value }
        $ghOptions = [regex]::Matches($ghText, $optionPattern).ForEach{ $_.Groups[1].Value }
    }
    It 'Should offer the same release choices, in the same order' {
        $azdOptions.Count | Should -Be 7
        $azdOptions | Should -Be $ghOptions
    }
    It 'Should default to the same release choice' {
        $azdDefault = [regex]::Match($azdText, "(?m)^\s+default: '(Next Prerelease[^']*)'").Groups[1].Value
        $ghDefault = [regex]::Match($ghText, "(?m)^\s+default: '(Next Prerelease[^']*)'").Groups[1].Value
        $azdDefault | Should -Not -BeNullOrEmpty
        $azdDefault | Should -Be $ghDefault
        $azdOptions | Should -Contain $azdDefault
    }
    It 'Should leave the Stable Release choices commented out' {
        $azdText | Should -Not -Match "(?m)^\s*- 'Stable Release"
        $ghText | Should -Not -Match "(?m)^\s*- 'Stable Release"
    }
    It 'Should work out <Expected> from <Prefix>' -ForEach @(
        @{ Prefix = 'Next Prerelease';              Expected = 'prerelease/none' }
        @{ Prefix = 'New Prerelease Series: minor'; Expected = 'prerelease/minor' }
        @{ Prefix = 'New Prerelease Series: major'; Expected = 'prerelease/major' }
        @{ Prefix = 'Promote to Stable';            Expected = 'stable/none' }
        @{ Prefix = 'Stable Release: patch';        Expected = 'stable/patch' }
        @{ Prefix = 'Stable Release: minor';        Expected = 'stable/minor' }
        @{ Prefix = 'Stable Release: major';        Expected = 'stable/major' }
    ) {
        #The same parsing the version step does, on the option as written in the pipeline
        $option = $azdOptions | Where-Object { $_.StartsWith($Prefix) }
        $option | Should -HaveCount 1
        $choice = ($option -split '\(')[0].Trim()
        $releaseType = if($choice -match '^(Promote to Stable|Stable Release)'){ 'stable' }else{ 'prerelease' }
        $versionType = if($choice -match '\b(major|minor|patch)\b'){ $Matches[1].ToLower() }else{ 'none' }
        "$releaseType/$versionType" | Should -Be $Expected
    }
    It 'Should parse the release choice the same way on both platforms' {
        $parseLine = '$versionType = if($choice -match ''\b(major|minor|patch)\b''){ $Matches[1].ToLower() }else{ ''none'' }'
        $azdText | Should -BeLike "*$([WildcardPattern]::Escape($parseLine))*"
        $ghText | Should -BeLike "*$([WildcardPattern]::Escape($parseLine))*"
    }
    It 'Should not tag or publish on a dry run' {
        $azdText | Should -Match '(?s)\$\{\{ if eq\(parameters\.dry_run, false\) \}\}:.*Apply Version Tag.*DotNetCoreCLI'
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
