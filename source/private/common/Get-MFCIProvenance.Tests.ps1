[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Walk up from this test to the project root, so it runs the same from any working directory
    $projectRoot = $PSScriptRoot
    while(!(test-path (join-path -path $projectRoot -childPath 'moduleForgeConfig.xml'))){ $projectRoot = split-path -path $projectRoot -parent; if(!$projectRoot){ throw 'Unable to find moduleForgeConfig.xml above this test' } }
    $sourcePath = join-path -path $projectRoot -childPath 'source'

    #Dependencies by filename anywhere under source/, loaded in this order. Throws if a name is missing or found more than once
    $dependencies = & (join-path -path $sourcePath -childPath 'resource' -AdditionalChildPath 'scripts','Get-MFTestDependency.ps1') -SourcePath $sourcePath -Name @(
        'ConvertTo-MFSafeUri.ps1'
    )
    $dependencies.ForEach{ . $_ }

    #Load This File
    $fileName = ($PSCommandPath -replace '\.tests\.ps1$','.ps1')
    $functionName = 'Get-MFCIProvenance'
    . $fileName

    #Every variable the function reads. Each test sets the ones it needs, so the results don't depend on where
    #the tests run, including inside GitHub Actions or Azure Pipelines
    $ciVariables = @(
        'GITHUB_ACTIONS','GITHUB_SERVER_URL','GITHUB_REPOSITORY','GITHUB_SHA','GITHUB_REF_NAME','GITHUB_RUN_ID','GITHUB_RUN_ATTEMPT'
        'TF_BUILD','BUILD_REPOSITORY_URI','BUILD_SOURCEVERSION','BUILD_SOURCEBRANCH','BUILD_BUILDID','SYSTEM_JOBATTEMPT','SYSTEM_COLLECTIONURI','SYSTEM_TEAMPROJECT'
    )
    $savedCiVariables = @{}
    foreach($name in $ciVariables){ $savedCiVariables[$name] = [Environment]::GetEnvironmentVariable($name) }
}

AfterAll{
    foreach($name in $ciVariables){ [Environment]::SetEnvironmentVariable($name, $savedCiVariables[$name]) }
}

Describe 'Check Clean Environment' {
    It 'Should have loaded the function directly, not from an imported module' {
        (get-command $functionName).source | should -BeNullOrEmpty
    }
}

Describe 'Get-MFCIProvenance' {
    BeforeEach {
        foreach($name in $ciVariables){ [Environment]::SetEnvironmentVariable($name, $null) }
    }

    It 'Should return nothing outside CI' {
        Get-MFCIProvenance | Should -BeNullOrEmpty
    }

    It 'Should return the commit and run in GitHub Actions' {
        $env:GITHUB_ACTIONS = 'true'
        $env:GITHUB_SERVER_URL = 'https://github.com'
        $env:GITHUB_REPOSITORY = 'contoso/TestModule'
        $env:GITHUB_SHA = 'a44b41efcf2c1eac6a1f66d9c0633f8660da8eaf'
        $env:GITHUB_REF_NAME = 'main'
        $env:GITHUB_RUN_ID = '123456789'
        $env:GITHUB_RUN_ATTEMPT = '1'
        $result = Get-MFCIProvenance
        $result.Platform | Should -Be 'GitHub Actions'
        $result.Repository | Should -Be 'https://github.com/contoso/TestModule'
        $result.Commit | Should -Be 'a44b41efcf2c1eac6a1f66d9c0633f8660da8eaf'
        $result.Branch | Should -Be 'main'
        $result.RunId | Should -Be '123456789'
        $result.RunAttempt | Should -Be '1'
        $result.RunUrl | Should -Be 'https://github.com/contoso/TestModule/actions/runs/123456789'
    }

    It 'Should return the commit and run in Azure Pipelines' {
        $env:TF_BUILD = 'True'
        $env:BUILD_REPOSITORY_URI = 'https://dev.azure.com/contoso/My%20Project/_git/TestModule'
        $env:BUILD_SOURCEVERSION = 'a44b41efcf2c1eac6a1f66d9c0633f8660da8eaf'
        $env:BUILD_SOURCEBRANCH = 'refs/heads/feature/new-thing'
        $env:BUILD_BUILDID = '42'
        $env:SYSTEM_JOBATTEMPT = '1'
        $env:SYSTEM_COLLECTIONURI = 'https://dev.azure.com/contoso/'
        $env:SYSTEM_TEAMPROJECT = 'My Project'
        $result = Get-MFCIProvenance
        $result.Platform | Should -Be 'Azure Pipelines'
        $result.Commit | Should -Be 'a44b41efcf2c1eac6a1f66d9c0633f8660da8eaf'
        $result.RunId | Should -Be '42'
        $result.RunUrl | Should -Be 'https://dev.azure.com/contoso/My%20Project/_build/results?buildId=42'
    }

    It 'Should keep the whole branch name, including any slashes' {
        $env:TF_BUILD = 'True'
        $env:BUILD_SOURCEBRANCH = 'refs/heads/feature/new-thing'
        (Get-MFCIProvenance).Branch | Should -Be 'feature/new-thing'
    }

    It 'Should remove credentials from the repository URI' {
        $env:TF_BUILD = 'True'
        $env:BUILD_REPOSITORY_URI = 'https://contoso@dev.azure.com/contoso/Project/_git/TestModule'
        (Get-MFCIProvenance).Repository | Should -Not -Match '@'
    }

    It 'Should leave out values the platform does not provide' {
        $env:GITHUB_ACTIONS = 'true'
        $env:GITHUB_SHA = 'a44b41efcf2c1eac6a1f66d9c0633f8660da8eaf'
        $result = Get-MFCIProvenance
        $result.Keys | Should -Be @('Platform','Commit')
    }

    It 'Should ignore GITHUB_ACTIONS unless it is true' {
        $env:GITHUB_ACTIONS = 'false'
        $env:GITHUB_SHA = 'a44b41efcf2c1eac6a1f66d9c0633f8660da8eaf'
        Get-MFCIProvenance | Should -BeNullOrEmpty
    }
}
