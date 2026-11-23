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
    It 'Should add every rule set by default' {
        $path = New-TestProject -Name 'both'
        Add-MFProjectRules -ModulePath $path
        Test-Path (Join-Path $path 'PSScriptAnalyzer/clm.psd1') | Should -Be $true
        Test-Path (Join-Path $path 'PSScriptAnalyzer/rules/HelpExamples/HelpExamples.psm1') | Should -Be $true
        Test-Path (Join-Path $path 'PSScriptAnalyzer/rules/ArrayAddition/ArrayAddition.psm1') | Should -Be $true
        Test-Path (Join-Path $path 'PSScriptAnalyzer/rules/NestedFunctions/NestedFunctions.psm1') | Should -Be $true
    }
    It 'Should add a NestedFunctions rule module that exports its rule' {
        $path = New-TestProject -Name 'nestedContent'
        Add-MFProjectRules -ModulePath $path -RuleSet NestedFunctions
        $ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $path 'PSScriptAnalyzer/rules/NestedFunctions/NestedFunctions.psm1'), [ref]$null, [ref]$null)
        $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true).Name | Should -Contain 'Measure-MFNestedFunction'
        Test-Path (Join-Path $path 'PSScriptAnalyzer/rules/ArrayAddition') | Should -Be $false
    }
    It 'Should add an ArrayAddition rule module that exports its rule' {
        $path = New-TestProject -Name 'arrayContent'
        Add-MFProjectRules -ModulePath $path -RuleSet ArrayAddition
        $ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $path 'PSScriptAnalyzer/rules/ArrayAddition/ArrayAddition.psm1'), [ref]$null, [ref]$null)
        $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true).Name | Should -Contain 'Measure-MFArrayAddition'
        Test-Path (Join-Path $path 'PSScriptAnalyzer/rules/HelpExamples') | Should -Be $false
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

Describe 'ArrayAddition rule' -Skip:(!(Get-Module -ListAvailable PSScriptAnalyzer)) {
    BeforeAll {
        $path = New-TestProject -Name 'arrayAddition' -Folders 'source/functions'
        Add-MFProjectRules -ModulePath $path -RuleSet ArrayAddition
        $fixture = @'
function Get-LoopAdd {
    $results = @()
    foreach($item in 1..3){ $results += $item }
    $results
}
function Get-PipelineAdd {
    $piped = @()
    1..3 | ForEach-Object { $piped += $_ }
    $piped
}
function Get-TypedParamAdd {
    param([string[]]$Names)
    $Names += 'extra'
    $Names
}
function Get-TypedAdd {
    [array]$typed = Get-Item .
    while($false){ $typed += 1 }
}
function Get-NumberAdd {
    $count = 0
    foreach($item in 1..3){ $count += $item }
    $text = ''
    $text += 'a'
    $count
}
function Get-ListAdd {
    $list = [System.Collections.Generic.List[int]]::new()
    foreach($item in 1..3){ $list.Add($item) }
    $list
}
function Get-OtherScope {
    $elsewhere += 1
}
function Get-Collected {
    $elsewhere = @()
    $elsewhere = foreach($item in 1..3){ $item }
    $elsewhere
}
'@
        $fixturePath = Join-Path $path 'source/functions/Fixture.ps1'
        $fixture | Set-Content $fixturePath
        $findings = @(Invoke-ScriptAnalyzer -Path $fixturePath -CustomRulePath (Join-Path $path 'PSScriptAnalyzer/rules/ArrayAddition') -IncludeRule 'Measure-MFArrayAddition')
        $lines = ($fixture -split "`r?`n")
        $findingFor = { param($text) $findings | Where-Object { $lines[$_.Line - 1] -like "*$text*" } }
    }
    It 'Should warn about += on an array in a foreach loop' {
        $finding = & $findingFor '$results += $item'
        $finding | Should -HaveCount 1
        "$($finding.Severity)" | Should -Be 'Warning'
        $finding.Message | Should -Match 'Generic\.List'
    }
    It 'Should warn about += on an array in a ForEach-Object block' {
        "$((& $findingFor '$piped += $_').Severity)" | Should -Be 'Warning'
    }
    It 'Should report += on an array parameter outside a loop as Information' {
        "$((& $findingFor "`$Names += 'extra'").Severity)" | Should -Be 'Information'
    }
    It 'Should warn about += on an [array] typed variable in a while loop' {
        "$((& $findingFor '$typed += 1').Severity)" | Should -Be 'Warning'
    }
    It 'Should not report += on a number or a string' {
        & $findingFor '$count +=' | Should -BeNullOrEmpty
        & $findingFor '$text +=' | Should -BeNullOrEmpty
    }
    It 'Should not report a variable that only another function sets up as an array' {
        & $findingFor '$elsewhere += 1' | Should -BeNullOrEmpty
    }
    It 'Should report only the four array additions' {
        $findings | Should -HaveCount 4
    }
}

Describe 'NestedFunctions rule' -Skip:(!(Get-Module -ListAvailable PSScriptAnalyzer)) {
    BeforeAll {
        $path = New-TestProject -Name 'nestedFunctions' -Folders 'source/functions'
        Add-MFProjectRules -ModulePath $path -RuleSet NestedFunctions
        $fixture = @'
function Get-Outer {
    function innerHelper { 'inner' }
    if($true){
        function innerInIf { 'deeper' }
    }
    innerHelper
}
function Get-TwoLevels {
    function levelOne {
        function levelTwo { 2 }
        levelTwo
    }
    levelOne
}
function Get-JobHelper {
    Start-Job -ScriptBlock {
        function jobOnly { 'runs in the job' }
        jobOnly
    }
}
function Get-Suppressed {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('Measure-MFNestedFunction', '', Justification = 'Kept on purpose')]
    param()
    function keptOnPurpose { 'fine' }
    keptOnPurpose
}
function Get-Alone { 'no nesting' }
class Widget {
    [string] Describe() {
        function inMethod { 'in a method' }
        return (inMethod)
    }
}
'@
        $fixturePath = Join-Path $path 'source/functions/Fixture.ps1'
        $fixture | Set-Content $fixturePath
        $findings = @(Invoke-ScriptAnalyzer -Path $fixturePath -CustomRulePath (Join-Path $path 'PSScriptAnalyzer/rules/NestedFunctions') -IncludeRule 'Measure-MFNestedFunction')
        $findingFor = { param($name) $findings | Where-Object { $_.Message -match "^Function '$name' " } }
    }
    It 'Should warn about a function defined inside another' {
        $finding = & $findingFor 'innerHelper'
        $finding | Should -HaveCount 1
        "$($finding.Severity)" | Should -Be 'Warning'
        $finding.Message | Should -Match "inside 'Get-Outer'"
    }
    It 'Should warn about a function nested inside a statement in another function' {
        & $findingFor 'innerInIf' | Should -HaveCount 1
    }
    It 'Should name the closest function each nested function is inside' {
        (& $findingFor 'levelOne').Message | Should -Match "inside 'Get-TwoLevels'"
        (& $findingFor 'levelTwo').Message | Should -Match "inside 'levelOne'"
    }
    It 'Should warn about a function defined in a class method' {
        (& $findingFor 'inMethod').Message | Should -Match "inside 'Widget::Describe'"
    }
    It 'Should not report a function inside a script block' {
        & $findingFor 'jobOnly' | Should -BeNullOrEmpty
    }
    It 'Should not report a nested function the outer function suppresses' {
        & $findingFor 'keptOnPurpose' | Should -BeNullOrEmpty
    }
    It 'Should not report top-level functions' {
        $findings.Message | Should -Not -Match "'Get-(Outer|TwoLevels|JobHelper|Suppressed|Alone)' is defined inside"
    }
    It 'Should report only the five nested functions' {
        $findings | Should -HaveCount 5
    }
}
