[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeDiscovery{
    $linked = @(
        @{ Name = 'GitHub'; ProjectUri = 'https://github.com/owner/repo'; Expected = 'https://github.com/owner/repo/blob/HEAD/LICENSE' }
        @{ Name = 'GitHub with a trailing slash'; ProjectUri = 'https://github.com/owner/repo/'; Expected = 'https://github.com/owner/repo/blob/HEAD/LICENSE' }
        @{ Name = 'GitHub with .git'; ProjectUri = 'https://github.com/owner/repo.git'; Expected = 'https://github.com/owner/repo/blob/HEAD/LICENSE' }
        @{ Name = 'Azure DevOps'; ProjectUri = 'https://dev.azure.com/org/project/_git/repo'; Expected = 'https://dev.azure.com/org/project/_git/repo?path=/LICENSE' }
        @{ Name = 'Azure DevOps with an escaped project name'; ProjectUri = 'https://dev.azure.com/org/My%20Project/_git/repo'; Expected = 'https://dev.azure.com/org/My%20Project/_git/repo?path=/LICENSE' }
        @{ Name = 'Azure DevOps on visualstudio.com'; ProjectUri = 'https://org.visualstudio.com/project/_git/repo'; Expected = 'https://org.visualstudio.com/project/_git/repo?path=/LICENSE' }
        @{ Name = 'Azure DevOps on visualstudio.com with a collection'; ProjectUri = 'https://org.visualstudio.com/DefaultCollection/project/_git/repo'; Expected = 'https://org.visualstudio.com/DefaultCollection/project/_git/repo?path=/LICENSE' }
    )
    $notLinked = @(
        @{ Name = 'another host'; ProjectUri = 'https://gitlab.com/owner/repo' }
        @{ Name = 'a GitHub user page, not a repository'; ProjectUri = 'https://github.com/owner' }
        @{ Name = 'an Azure DevOps project, not a repository'; ProjectUri = 'https://dev.azure.com/org/project' }
        @{ Name = 'a host-only URI'; ProjectUri = 'https://example.com' }
        @{ Name = 'an empty project URI'; ProjectUri = '' }
    )
}

BeforeAll{

    $WarningPreference = 'SilentlyContinue'

    #Load This File (the function lives alongside this test in source/private)
    $fileName = $PSCommandPath -replace '\.tests\.ps1$','.ps1'
    $functionName = 'Get-MFLicenseUri'
    . $fileName

    $withLicense = Join-Path $TestDrive 'withLicense'
    $null = New-Item -ItemType Directory -Path $withLicense
    'MIT' | Set-Content -Path (Join-Path $withLicense 'LICENSE')
}

Describe 'Check Clean Environment' {
    It 'Should have loaded the script directly, not from the module' {
        (get-command $functionName).source | should -BeNullOrEmpty
    }
}

Describe 'Get-MFLicenseUri links the license file for <Name>' -ForEach $linked {
    It 'Should return the web link to the license file' {
        Get-MFLicenseUri -ProjectUri $ProjectUri -ModulePath $withLicense | Should -Be $Expected
    }
}

Describe 'Get-MFLicenseUri returns nothing for <Name>' -ForEach $notLinked {
    It 'Should return nothing' {
        Get-MFLicenseUri -ProjectUri $ProjectUri -ModulePath $withLicense | Should -BeNullOrEmpty
    }
}

Describe 'Get-MFLicenseUri license file names' {
    It 'Should return nothing when there is no license file' {
        $empty = Join-Path $TestDrive 'noLicense'
        $null = New-Item -ItemType Directory -Path $empty
        Get-MFLicenseUri -ProjectUri 'https://github.com/owner/repo' -ModulePath $empty | Should -BeNullOrEmpty
    }
    It 'Should use the actual file name, such as LICENSE.md' {
        $md = Join-Path $TestDrive 'mdLicense'
        $null = New-Item -ItemType Directory -Path $md
        'MIT' | Set-Content -Path (Join-Path $md 'LICENSE.md')
        Get-MFLicenseUri -ProjectUri 'https://github.com/owner/repo' -ModulePath $md | Should -Be 'https://github.com/owner/repo/blob/HEAD/LICENSE.md'
    }
    It 'Should accept the LICENCE spelling' {
        $licence = Join-Path $TestDrive 'licence'
        $null = New-Item -ItemType Directory -Path $licence
        'MIT' | Set-Content -Path (Join-Path $licence 'LICENCE.txt')
        Get-MFLicenseUri -ProjectUri 'https://github.com/owner/repo' -ModulePath $licence | Should -Be 'https://github.com/owner/repo/blob/HEAD/LICENCE.txt'
    }
    It 'Should prefer plain LICENSE when there is more than one' {
        $both = Join-Path $TestDrive 'both'
        $null = New-Item -ItemType Directory -Path $both
        'MIT' | Set-Content -Path (Join-Path $both 'LICENSE.md')
        'MIT' | Set-Content -Path (Join-Path $both 'LICENSE')
        Get-MFLicenseUri -ProjectUri 'https://github.com/owner/repo' -ModulePath $both | Should -Be 'https://github.com/owner/repo/blob/HEAD/LICENSE'
    }
    It 'Should not treat other files as a license' {
        $other = Join-Path $TestDrive 'other'
        $null = New-Item -ItemType Directory -Path $other
        'x' | Set-Content -Path (Join-Path $other 'LICENSE-THIRD-PARTY.md')
        Get-MFLicenseUri -ProjectUri 'https://github.com/owner/repo' -ModulePath $other | Should -BeNullOrEmpty
    }
}
