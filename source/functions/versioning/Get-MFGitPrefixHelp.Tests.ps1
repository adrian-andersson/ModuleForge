[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Load This File
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
    #The help describes this function, so the tests check one against the other
    . $PSCommandPath.Replace('Get-MFGitPrefixHelp.Tests.ps1','Get-MFGitChangeLog.ps1')

}

Describe 'Get-MFGitPrefixHelp output' {
    BeforeAll{
        $help = Get-MFGitPrefixHelp
        $lines = $help -split "`n"
    }

    It 'Should return a single string' {
        $help | Should -BeOfType [string]
        @($help).Count | Should -Be 1
    }

    It 'Should link to the full guide' {
        $help | Should -Match ([regex]::Escape('https://adrian-andersson.github.io/ModuleForge/commit-prefixes.html'))
    }

    It 'Should fit in 80 columns, apart from the guide link' {
        $tooWide = $lines.where{$_.Length -gt 80 -and $_ -notlike 'Full guide:*'}
        $tooWide | Should -BeNullOrEmpty
    }

    It 'Should only contain ASCII' {
        $help | Should -Not -Match '[^\x00-\x7F]'
    }

    It 'Should include the <heading> section by default' -ForEach @(
        @{heading = 'FORMAT'}
        @{heading = 'PREFIXES'}
        @{heading = 'EXAMPLES'}
        @{heading = 'VERSION INCREMENT'}
        @{heading = 'GOTCHAS'}
    ) {
        $lines | Should -Contain $heading
    }
}

Describe 'Get-MFGitPrefixHelp -Section' {
    It 'Should only return the requested section' {
        $result = Get-MFGitPrefixHelp -Section Gotchas
        $result | Should -MatchExactly 'GOTCHAS'
        $result | Should -Not -MatchExactly 'EXAMPLES'
        $result | Should -Not -MatchExactly 'PREFIXES'
    }

    It 'Should keep the guide link on a single section' {
        Get-MFGitPrefixHelp -Section Format | Should -Match 'Full guide:'
    }

    It 'Should reject an unknown section' {
        { Get-MFGitPrefixHelp -Section 'Nonsense' } | Should -Throw
    }
}

Describe 'Prefixes stay in step with Get-MFGitChangeLog' {
    BeforeAll{
        $parameterAst = (Get-Command Get-MFGitChangeLog).ScriptBlock.Ast.Body.ParamBlock.Parameters.where{$_.Name.VariablePath.UserPath -eq 'ChangeLogTypes'}[0]
        $defaultTypes = $parameterAst.DefaultValue.SafeGetValue()

        $rows = @((Get-MFGitPrefixHelp -Section Prefixes) -split "`n" | ForEach-Object {
            if($_ -match '^\s+(?<prefix>[a-z]+):\s+(?<section>.+?)\s{2,}(?<bump>\S+)$'){
                [PSCustomObject]@{Prefix = $Matches.prefix; Section = $Matches.section; Bump = $Matches.bump}
            }
        })
    }

    It 'Should list every default changelog type with the same heading' {
        foreach($key in $defaultTypes.Keys)
        {
            ($rows.where{$_.Prefix -eq $key}).Section | Should -Be $defaultTypes[$key]
        }
    }

    It 'Should only mark prefixes as excluded when they are not default types' {
        $excluded = $rows.where{$_.Section -eq '(excluded)'}.Prefix
        $excluded | Should -Be @('chore','test')
        $excluded | Should -Not -BeIn @($defaultTypes.Keys)
    }

    It 'Should list every prefix in the examples' {
        $examples = Get-MFGitPrefixHelp -Section Examples
        foreach($row in $rows)
        {
            $examples | Should -Match "(?m)^  $($row.Prefix): "
        }
    }
}

Describe 'Gotchas are true of Get-MFGitChangeLog' {
    BeforeAll{
        function Get-ChangeLogFor([string[]]$Subject)
        {
            $repo = Join-Path $TestDrive ([guid]::NewGuid().Guid)
            New-Item -ItemType Directory -Path $repo | Out-Null
            Push-Location $repo
            try{
                git init --quiet
                git config user.email 'test@example.com'
                git config user.name 'test'
                git commit --quiet --allow-empty -m 'chore: first commit'
                git tag v1.0.0
                $Subject.ForEach{git commit --quiet --allow-empty -m $_}
                Get-MFGitChangeLog -FromLastTag
            }finally{
                Pop-Location
            }
        }
    }

    It 'Should drop <subject>' -ForEach @(
        @{subject = 'feature: unknown long form'}
        @{subject = 'bugfix: unknown long form'}
        @{subject = 'feat!: unknown bang form'}
        @{subject = 'feat(build): unsupported scope'}
        @{subject = 'Merged PR 11: fix: squashed in azure devops'}
    ) {
        Get-ChangeLogFor -Subject $subject | Should -Match 'No relevant commit messages'
    }

    It 'Should have no entries when only chore and test commits exist' {
        Get-ChangeLogFor -Subject 'chore: housekeeping','test: more tests' | Should -Match 'No relevant commit messages'
    }

    It 'Should ignore a BREAKING CHANGE note in the commit body' {
        Get-ChangeLogFor -Subject "feat: new thing`n`nBREAKING CHANGE: removed old thing" | Should -Not -Match 'removed old thing'
    }
}
