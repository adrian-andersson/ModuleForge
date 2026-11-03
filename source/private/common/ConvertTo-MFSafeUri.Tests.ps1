[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeDiscovery{
    $cases = @(
        @{ Name = 'https with a token'; Uri = 'https://user:ghp_secret@github.com/owner/repo.git'; Expected = 'https://github.com/owner/repo' }
        @{ Name = 'https with a token only'; Uri = 'https://ghp_secret@github.com/owner/repo'; Expected = 'https://github.com/owner/repo' }
        @{ Name = 'Azure DevOps https with a PAT'; Uri = 'https://org:pat123@dev.azure.com/org/My%20Project/_git/repo'; Expected = 'https://dev.azure.com/org/My%20Project/_git/repo' }
        @{ Name = 'Azure DevOps https with a user name'; Uri = 'https://org@dev.azure.com/org/project/_git/repo'; Expected = 'https://dev.azure.com/org/project/_git/repo' }
        @{ Name = 'GitHub scp-style SSH'; Uri = 'git@github.com:owner/repo.git'; Expected = 'https://github.com/owner/repo' }
        @{ Name = 'ssh:// URL with a port'; Uri = 'ssh://git@gitlab.example.com:2222/group/repo.git'; Expected = 'https://gitlab.example.com/group/repo' }
        @{ Name = 'Azure DevOps SSH'; Uri = 'git@ssh.dev.azure.com:v3/org/project/repo'; Expected = 'https://dev.azure.com/org/project/_git/repo' }
        @{ Name = 'a clean https URI'; Uri = 'https://github.com/owner/repo'; Expected = 'https://github.com/owner/repo' }
        @{ Name = 'a host-only URI'; Uri = 'https://example.com'; Expected = 'https://example.com' }
        @{ Name = 'a clean URI with escaping'; Uri = 'https://dev.azure.com/org/My%20Project/_git/repo'; Expected = 'https://dev.azure.com/org/My%20Project/_git/repo' }
        @{ Name = 'surrounding whitespace'; Uri = "  https://github.com/owner/repo.git`n"; Expected = 'https://github.com/owner/repo' }
    )
    $unchanged = @(
        @{ Name = 'a local Windows path'; Uri = 'C:\repos\module' }
        @{ Name = 'a local relative path'; Uri = '../module' }
        @{ Name = 'a file URI'; Uri = 'file:///srv/git/module.git' }
    )
}

BeforeAll{

    $WarningPreference = 'SilentlyContinue'

    #Load This File (the function lives alongside this test in source/private)
    $fileName = $PSCommandPath -replace '\.tests\.ps1$','.ps1'
    $functionName = 'ConvertTo-MFSafeUri'
    . $fileName

}

Describe 'Check Clean Environment' {
    It 'Should have loaded the script directly, not from the module' {
        (get-command $functionName).source | should -BeNullOrEmpty
    }
}

Describe 'ConvertTo-MFSafeUri cleans <Name>' -ForEach $cases {
    It 'Should return the clean https address' {
        ConvertTo-MFSafeUri -Uri $Uri | Should -Be $Expected
    }
}

Describe 'ConvertTo-MFSafeUri leaves <Name> alone' -ForEach $unchanged {
    It 'Should return it unchanged' {
        ConvertTo-MFSafeUri -Uri $Uri | Should -Be $Uri
    }
}

Describe 'ConvertTo-MFSafeUri warnings' {
    It 'Should warn when it removes a password or token' {
        $null = ConvertTo-MFSafeUri -Uri 'https://user:secret@github.com/owner/repo' -WarningVariable warned -WarningAction SilentlyContinue
        $warned | Should -Not -BeNullOrEmpty
        "$warned" | Should -Not -Match 'secret'
    }
    It 'Should not warn for a user name alone' {
        $null = ConvertTo-MFSafeUri -Uri 'https://org@dev.azure.com/org/project/_git/repo' -WarningVariable warned -WarningAction SilentlyContinue
        $warned | Should -BeNullOrEmpty
    }
    It 'Should pass empty values through' {
        ConvertTo-MFSafeUri -Uri '' | Should -BeNullOrEmpty
        ConvertTo-MFSafeUri -Uri $null | Should -BeNullOrEmpty
    }
}
