# NOTE: This lives in the dedicated /tests folder as the script under test is a resource template,
# and neither source/resource nor its tests are discovered alongside functions.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeDiscovery{
    $templates = @(
        @{ Name = 'GitHub'; Path = 'source/resource/github/workflows/projectRules.yml.example' }
        @{ Name = 'Azure DevOps'; Path = 'source/resource/azureDevOps/pipelines/projectRules.yml.example' }
    )
}

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Reference Current Path
    $currentPath = $(get-location).path
    $scriptPath = join-path -path $currentPath -childPath 'source/resource/scripts/Invoke-MFProjectRules.ps1'

    #Need to ensure PSScriptAnalyzer is available
    if(!(get-module 'PSScriptAnalyzer' -ListAvailable))
    {
        install-module -Repository 'PSGallery' -Name PSScriptAnalyzer -Force -SkipPublisherCheck
    }

    #A rule that flags any call to Get-Foo, once per call
    $customRule = @'
function Measure-NoFoo {
    [CmdletBinding()]
    PARAM([Parameter(Mandatory)][System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst)
    process {
        if($null -eq $ScriptBlockAst.Parent){
            foreach($hit in $ScriptBlockAst.FindAll({ param($ast) $ast -is [System.Management.Automation.Language.CommandAst] -and $ast.GetCommandName() -eq 'Get-Foo' }, $true)){
                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{ Message = 'Get-Foo is banned'; Extent = $hit.Extent; RuleName = 'Measure-NoFoo'; Severity = 'Warning' }
            }
        }
    }
}
Export-ModuleMember -Function Measure-*
'@

    $throwingRule = @'
function Measure-Throws {
    [CmdletBinding()]
    PARAM([Parameter(Mandatory)][System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst)
    process { throw 'rule blew up' }
}
Export-ModuleMember -Function Measure-*
'@

    $clmSettings = "@{ IncludeRules = @('PSUseConstrainedLanguageMode'); Rules = @{ PSUseConstrainedLanguageMode = @{ Enable = `$true; IgnoreSignatures = `$true } } }"

    #A project where every source file has a default rule hit (the gci alias), so a leak of the default rules shows
    function New-TestProject
    {
        PARAM([hashtable]$Files = @{})
        $root = join-path -path $TestDrive -childPath ([guid]::NewGuid().Guid)
        $source = @{
            'moduleForgeConfig.xml' = ''
            'source/functions/Get-Thing.ps1' = 'function Get-Thing { gci; Get-Foo; [PSCustomObject]@{a=1} }'
            'source/functions/Get-Thing.Tests.ps1' = 'gci; Get-Foo'
        }
        foreach($item in ($source + $Files).GetEnumerator())
        {
            $path = join-path -path $root -childPath $item.Key
            $null = new-item -Path $path -ItemType File -Force
            set-content -LiteralPath $path -Value $item.Value
        }
        $root
    }

    function Invoke-TestProject
    {
        PARAM([string]$Path,[hashtable]$Splat = @{})
        & $scriptPath -ProjectPath $Path -InformationAction SilentlyContinue @Splat
    }
}

Describe 'Invoke-MFProjectRules with nothing to run' {
    It 'Should do nothing with no PSScriptAnalyzer folder' {
        (Invoke-TestProject (New-TestProject)).HasRuleSets | Should -BeFalse
    }
    It 'Should do nothing if the only file in the folder is disabled' {
        $project = New-TestProject @{ 'PSScriptAnalyzer/clm.psd1.example' = $clmSettings }
        (Invoke-TestProject $project).HasRuleSets | Should -BeFalse
    }
    It 'Should do nothing with an empty rule folder' {
        $project = New-TestProject @{ 'PSScriptAnalyzer/rules/Empty/readme.txt' = 'nothing here' }
        (Invoke-TestProject $project).HasRuleSets | Should -BeFalse
    }
    It 'Should not write a report' {
        $reportPath = join-path $TestDrive 'nothingToRun.md'
        $null = Invoke-TestProject (New-TestProject) @{ ReportPath = $reportPath }
        $reportPath | Should -Not -Exist
    }
}

Describe 'Invoke-MFProjectRules settings files' {
    It 'Should run the named rule and nothing else' {
        $result = Invoke-TestProject (New-TestProject @{ 'PSScriptAnalyzer/clm.psd1' = $clmSettings })
        $result.RuleSets.Status | Should -Be 'Findings'
        $result.RuleSets.Findings.RuleName | Should -Be 'PSUseConstrainedLanguageMode'
    }
    It 'Should keep default rules out when the file has no IncludeRules' {
        $project = New-TestProject @{ 'PSScriptAnalyzer/clm.psd1' = '@{ Rules = @{ PSUseConstrainedLanguageMode = @{ Enable = $true } } }' }
        (Invoke-TestProject $project).RuleSets.Findings.RuleName | Should -Be 'PSUseConstrainedLanguageMode'
    }
    It 'Should keep default rules out when the file asks for them' {
        $settings = "@{ IncludeDefaultRules = `$true; IncludeRules = @('PSUseConstrainedLanguageMode'); Rules = @{ PSUseConstrainedLanguageMode = @{ Enable = `$true } } }"
        $project = New-TestProject @{ 'PSScriptAnalyzer/clm.psd1' = $settings }
        (Invoke-TestProject $project).RuleSets.Findings.RuleName | Should -Be 'PSUseConstrainedLanguageMode'
    }
    It 'Should run a default rule the file deliberately names' {
        $project = New-TestProject @{ 'PSScriptAnalyzer/alias.psd1' = "@{ IncludeRules = @('PSAvoidUsingCmdletAliases') }" }
        (Invoke-TestProject $project).RuleSets.Findings.RuleName | Should -Be 'PSAvoidUsingCmdletAliases'
    }
    It 'Should report a misspelled rule as not run' {
        $project = New-TestProject @{ 'PSScriptAnalyzer/typo.psd1' = "@{ IncludeRules = @('PSUseConstrainedLanguageMod') }" }
        $result = (Invoke-TestProject $project).RuleSets
        $result.Status | Should -Be 'NotRun'
        $result.Detail | Should -Match 'PSUseConstrainedLanguageMod not found'
    }
    It 'Should report a wildcard as not run' {
        $project = New-TestProject @{ 'PSScriptAnalyzer/all.psd1' = "@{ IncludeRules = @('PS*') }" }
        (Invoke-TestProject $project).RuleSets.Status | Should -Be 'NotRun'
    }
    It 'Should report a file naming no rules as not run' {
        $project = New-TestProject @{ 'PSScriptAnalyzer/none.psd1' = "@{ ExcludeRules = @('PSAvoidUsingCmdletAliases') }" }
        (Invoke-TestProject $project).RuleSets.Status | Should -Be 'NotRun'
    }
    It 'Should report an unreadable file as not run' {
        $project = New-TestProject @{ 'PSScriptAnalyzer/bad.psd1' = '@{ not valid' }
        (Invoke-TestProject $project).RuleSets.Status | Should -Be 'NotRun'
    }
    It 'Should not call a default-off rule with no Enable clean' {
        $project = New-TestProject @{ 'PSScriptAnalyzer/clm.psd1' = "@{ IncludeRules = @('PSUseConstrainedLanguageMode') }" }
        $result = (Invoke-TestProject $project).RuleSets
        $result.Status | Should -Be 'Unconfirmed'
        $result.Detail | Should -Match 'PSUseConstrainedLanguageMode'
    }
}

Describe 'Invoke-MFProjectRules custom rules' {
    It 'Should run a rule folder without the default rules' {
        $result = (Invoke-TestProject (New-TestProject @{ 'PSScriptAnalyzer/rules/MyRules/MyRules.psm1' = $customRule })).RuleSets
        $result.Type | Should -Be 'Custom rules'
        $result.Findings.RuleName | Should -Be 'Measure-NoFoo'
    }
    It 'Should run a rule module placed directly in the rules folder' {
        $result = (Invoke-TestProject (New-TestProject @{ 'PSScriptAnalyzer/rules/MyRules.psm1' = $customRule })).RuleSets
        $result.Findings.RuleName | Should -Be 'Measure-NoFoo'
    }
    It 'Should keep default rules out with a settings file beside the source file' {
        $project = New-TestProject @{
            'PSScriptAnalyzer/rules/MyRules/MyRules.psm1' = $customRule
            'source/functions/PSScriptAnalyzerSettings.psd1' = '@{ IncludeDefaultRules = $true }'
        }
        (Invoke-TestProject $project).RuleSets.Findings.RuleName | Should -Be 'Measure-NoFoo'
    }
    It 'Should report a rule that throws as failed, not clean' {
        $result = (Invoke-TestProject (New-TestProject @{ 'PSScriptAnalyzer/rules/Throws/Throws.psm1' = $throwingRule })).RuleSets
        $result.Status | Should -Be 'Failed'
        $result.Detail | Should -Match 'rule blew up'
    }
    It 'Should report a module with a syntax error as failed' {
        $project = New-TestProject @{ 'PSScriptAnalyzer/rules/Broken/Broken.psm1' = 'function Measure-Bad { this is { broken' }
        (Invoke-TestProject $project).RuleSets.Status | Should -Be 'Failed'
    }
}

Describe 'Invoke-MFProjectRules scanning' {
    It 'Should scan classes as well as functions' {
        $project = New-TestProject @{
            'PSScriptAnalyzer/clm.psd1' = $clmSettings
            'source/classes/MyClass.ps1' = 'class MyClass { [string]$Name }'
        }
        (Invoke-TestProject $project).RuleSets.Findings.ScriptName | Should -Contain 'MyClass.ps1'
    }
    It 'Should not scan test files' {
        $project = New-TestProject @{ 'PSScriptAnalyzer/rules/MyRules/MyRules.psm1' = $customRule }
        (Invoke-TestProject $project).RuleSets.Findings.ScriptName | Should -Not -Contain 'Get-Thing.Tests.ps1'
    }
    It 'Should not scan outside the source folders' {
        $project = New-TestProject @{
            'PSScriptAnalyzer/rules/MyRules/MyRules.psm1' = $customRule
            'source/resource/template.ps1' = 'Get-Foo'
        }
        (Invoke-TestProject $project).RuleSets.Findings.ScriptName | Should -Not -Contain 'template.ps1'
    }
    It 'Should cope with a source folder holding no scripts, as scaffolded projects have' {
        $project = New-TestProject @{
            'PSScriptAnalyzer/clm.psd1' = $clmSettings
            'source/classes/.gitignore' = ''
        }
        (Invoke-TestProject $project).RuleSets.Status | Should -Be 'Findings'
    }
}

Describe 'Invoke-MFProjectRules report' {
    BeforeAll{
        $mixedProject = New-TestProject @{
            'PSScriptAnalyzer/zeta.psd1' = $clmSettings
            'PSScriptAnalyzer/typo.psd1' = "@{ IncludeRules = @('PSNotARule') }"
            'PSScriptAnalyzer/rules/Throws/Throws.psm1' = $throwingRule
        }
        $mixedReportPath = join-path $TestDrive 'mixed.md'
        $mixed = Invoke-TestProject $mixedProject @{ ReportPath = $mixedReportPath }

        $cleanProject = New-TestProject @{ 'PSScriptAnalyzer/clean.psd1' = "@{ IncludeRules = @('PSUseDeclaredVarsMoreThanAssignments'); Rules = @{ PSUseDeclaredVarsMoreThanAssignments = @{ Enable = `$true } } }" }
        $clean = Invoke-TestProject $cleanProject
    }
    It 'Should sort rule sets by name' {
        $mixed.RuleSets.Name | Should -Be @('Throws','typo','zeta')
    }
    It 'Should open with the marker the Azure DevOps comment job looks for' {
        ($mixed.Report -split "`n")[0] | Should -Be '<!-- moduleforge:project-rules -->'
        ($clean.Report -split "`n")[0] | Should -Be '<!-- moduleforge:project-rules -->'
    }
    It 'Should show each rule set with its status' {
        $mixed.Report | Should -Match '\|Throws\|Custom rules\|❌ Failed: .*\|-\|'
        $mixed.Report | Should -Match '\|typo\|Settings\|❌ Not run: PSNotARule not found\|-\|'
        $mixed.Report | Should -Match '\|zeta\|Settings\|⚠️ Findings\|1\|'
    }
    It 'Should only show detail for rule sets with findings' {
        $mixed.Report | Should -Match '#### zeta'
        $mixed.Report | Should -Not -Match '#### typo'
        $mixed.Report | Should -Not -Match '#### Throws'
    }
    It 'Should show the PSScriptAnalyzer version' {
        $mixed.Report | Should -Match '_PSScriptAnalyzer \d+\.\d+\.\d+_'
        $clean.Report | Should -Match '_PSScriptAnalyzer \d+\.\d+\.\d+_'
    }
    It 'Should save the report when asked' {
        (Get-Content $mixedReportPath -Raw).Trim() | Should -Be $mixed.Report.Trim()
    }
    It 'Should cap tables at the Top value' {
        $files = @{ 'PSScriptAnalyzer/rules/MyRules/MyRules.psm1' = $customRule }
        1..3 | ForEach-Object { $files["source/functions/File$_.ps1"] = 'Get-Foo' }
        $report = (Invoke-TestProject (New-TestProject $files) @{ Top = 2 }).Report
        (($report -split "`n") -match '\.ps1\|').Count | Should -Be 2
    }
    It 'Should keep a pipe in a message from breaking the table' {
        $settings = "@{ IncludeRules = @('PSNot|ARule') }"
        (Invoke-TestProject (New-TestProject @{ 'PSScriptAnalyzer/pipe.psd1' = $settings })).Report | Should -Match 'PSNot\\\|ARule'
    }
    It 'Should shrink to one line when everything is clean' {
        $clean.RuleSets.Status | Should -Be 'Clean'
        $clean.Report | Should -Match '✅ All rule sets clean: `clean`'
        $clean.Report | Should -Not -Match 'Rule set\|Type'
    }
    It 'Should leave the thread active with findings, and closed when clean' {
        $mixed.ThreadStatus | Should -Be 'active'
        $clean.ThreadStatus | Should -Be 'closed'
    }
}

Describe 'Project Rules template for <Name>' -ForEach $templates {
    BeforeAll{
        $content = Get-Content -LiteralPath (join-path $currentPath $Path) -Raw
    }
    It 'Should call the script' {
        $content | Should -Match 'Invoke-MFProjectRules\.ps1 -InstallPSScriptAnalyzer'
    }
    It 'Should include a working CLM example' {
        $content | Should -Match 'PSUseConstrainedLanguageMode'
        $content | Should -Match 'Enable = \$true'
    }
}
