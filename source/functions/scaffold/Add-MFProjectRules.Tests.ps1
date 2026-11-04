[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Walk up from this test to the project root, so it runs the same from any working directory
    $projectRoot = $PSScriptRoot
    while(!(test-path (join-path -path $projectRoot -childPath 'moduleForgeConfig.xml'))){ $projectRoot = split-path -path $projectRoot -parent; if(!$projectRoot){ throw 'Unable to find moduleForgeConfig.xml above this test' } }
    $sourcePath = join-path -path $projectRoot -childPath 'source'
    $mockPsScriptRoot = $sourcePath

    #Load This File
    $fileName = ($PSCommandPath -replace '\.tests\.ps1$','.ps1')
    $functionName = 'Add-MFProjectRules'
    . $fileName
    #It calls Add-MFProjectScripts, so load it for the call to resolve
    . $PSCommandPath.Replace('Add-MFProjectRules.Tests.ps1','Add-MFProjectScripts.ps1')

    #A project with only an empty config file, which is all these functions check for
    function New-TestProject
    {
        param([string]$Name,[string[]]$Folders)
        $path = Join-Path $TestDrive $Name
        $null = New-Item -ItemType Directory -Path $path
        $null = New-Item -ItemType File -Path (Join-Path $path 'moduleForgeConfig.xml')
        foreach($folder in $Folders){ $null = New-Item -ItemType Directory -Path (Join-Path $path $folder) -Force }
        $path
    }
}

Describe 'Check Clean Environment' {
    It 'Should have loaded the script directly, not from the module' {
        ($PSCommandPath -replace '\.tests\.ps1$','.ps1')|should -be $fileName
        (get-command $functionName).source |should -BeNullOrEmpty
    }
}

Describe 'Add-MFProjectRules rule sets' {
    It 'Should add both rule sets by default' {
        $path = New-TestProject -Name 'both'
        Add-MFProjectRules -ModulePath $path
        Test-Path (Join-Path $path 'PSScriptAnalyzer/clm.psd1') | Should -Be $true
        Test-Path (Join-Path $path 'PSScriptAnalyzer/rules/HelpExamples/HelpExamples.psm1') | Should -Be $true
    }
    It 'Should add only the rule set asked for' {
        $path = New-TestProject -Name 'clmOnly'
        Add-MFProjectRules -ModulePath $path -RuleSet CLM
        Test-Path (Join-Path $path 'PSScriptAnalyzer/clm.psd1') | Should -Be $true
        Test-Path (Join-Path $path 'PSScriptAnalyzer/rules') | Should -Be $false
    }
    It 'Should add a CLM settings file PSScriptAnalyzer can read' {
        $path = New-TestProject -Name 'clmContent'
        Add-MFProjectRules -ModulePath $path -RuleSet CLM
        (Import-PowerShellDataFile (Join-Path $path 'PSScriptAnalyzer/clm.psd1')).IncludeRules | Should -Contain 'PSUseConstrainedLanguageMode'
    }
    It 'Should add a HelpExamples rule module that exports its rule' {
        $path = New-TestProject -Name 'helpContent'
        Add-MFProjectRules -ModulePath $path -RuleSet HelpExamples
        $ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $path 'PSScriptAnalyzer/rules/HelpExamples/HelpExamples.psm1'), [ref]$null, [ref]$null)
        $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true).Name | Should -Contain 'Measure-MFHelpExample'
    }
    It 'Should keep an existing rule file without -Force' {
        $path = New-TestProject -Name 'keep' -Folders 'PSScriptAnalyzer'
        'custom' | Set-Content (Join-Path $path 'PSScriptAnalyzer/clm.psd1')
        Add-MFProjectRules -ModulePath $path -RuleSet CLM
        Get-Content (Join-Path $path 'PSScriptAnalyzer/clm.psd1') | Should -Be 'custom'
    }
    It 'Should replace an existing rule file with -Force' {
        $path = New-TestProject -Name 'force' -Folders 'PSScriptAnalyzer'
        'custom' | Set-Content (Join-Path $path 'PSScriptAnalyzer/clm.psd1')
        Add-MFProjectRules -ModulePath $path -RuleSet CLM -Force
        Get-Content (Join-Path $path 'PSScriptAnalyzer/clm.psd1') -Raw | Should -Match 'PSUseConstrainedLanguageMode'
    }
    It 'Should add the project scripts the workflow calls' {
        $path = New-TestProject -Name 'scripts'
        Add-MFProjectRules -ModulePath $path
        Test-Path (Join-Path $path 'scripts/Invoke-MFProjectRules.ps1') | Should -Be $true
    }
    It 'Should throw when there is no ModuleForge config' {
        $path = Join-Path $TestDrive 'noConfig'
        $null = New-Item -ItemType Directory -Path $path
        { Add-MFProjectRules -ModulePath $path } | Should -Throw
    }
    It 'Should reject an unknown rule set' {
        $path = New-TestProject -Name 'unknown'
        { Add-MFProjectRules -ModulePath $path -RuleSet Bogus } | Should -Throw
    }
}

Describe 'Add-MFProjectRules enables the workflow' {
    It 'Should rename the GitHub example workflow, keeping its content' {
        $path = New-TestProject -Name 'ghExample' -Folders '.github/workflows'
        'name: my edited example' | Set-Content (Join-Path $path '.github/workflows/projectRules.yml.example')
        Add-MFProjectRules -ModulePath $path
        Test-Path (Join-Path $path '.github/workflows/projectRules.yml.example') | Should -Be $false
        Get-Content (Join-Path $path '.github/workflows/projectRules.yml') | Should -Be 'name: my edited example'
    }
    It 'Should add the GitHub workflow when there is no example' {
        $path = New-TestProject -Name 'ghNoExample' -Folders '.github'
        Add-MFProjectRules -ModulePath $path
        Get-Content (Join-Path $path '.github/workflows/projectRules.yml') -Raw | Should -Match 'Invoke-MFProjectRules'
    }
    It 'Should enable the Azure DevOps pipeline too' {
        $path = New-TestProject -Name 'azd' -Folders '.azuredevops/pipelines'
        Add-MFProjectRules -ModulePath $path
        Test-Path (Join-Path $path '.azuredevops/pipelines/projectRules.yml') | Should -Be $true
    }
    It 'Should leave an enabled workflow alone without -Force' {
        $path = New-TestProject -Name 'ghEnabled' -Folders '.github/workflows'
        'name: mine' | Set-Content (Join-Path $path '.github/workflows/projectRules.yml')
        Add-MFProjectRules -ModulePath $path
        Get-Content (Join-Path $path '.github/workflows/projectRules.yml') | Should -Be 'name: mine'
    }
    It 'Should not create a CI folder that is not there' {
        $path = New-TestProject -Name 'noCi'
        Add-MFProjectRules -ModulePath $path -WarningVariable warned
        Test-Path (Join-Path $path '.github') | Should -Be $false
        Test-Path (Join-Path $path '.azuredevops') | Should -Be $false
        "$warned" | Should -Match 'Invoke-MFProjectRules'
    }
}

Describe 'Add-MFProjectRules rules run with Project Rules' {
    It 'Should find a function with no help example' -Skip:(!(Get-Module -ListAvailable PSScriptAnalyzer)) {
        $path = New-TestProject -Name 'endToEnd' -Folders 'source/functions'
        Add-MFProjectRules -ModulePath $path -RuleSet HelpExamples
        'function Get-NoExample { param() 1 }' | Set-Content (Join-Path $path 'source/functions/Get-NoExample.ps1')
        $findings = Invoke-ScriptAnalyzer -Path (Join-Path $path 'source') -Recurse -CustomRulePath (Join-Path $path 'PSScriptAnalyzer/rules/HelpExamples') -IncludeRule 'Measure-MFHelpExample'
        $findings.RuleName | Should -Contain 'Measure-MFHelpExample'
    }
}
