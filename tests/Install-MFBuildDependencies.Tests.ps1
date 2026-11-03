# NOTE: This lives in the dedicated /tests folder as the script under test is a resource template,
# and neither source/resource nor its tests are discovered alongside functions.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Reference Current Path
    $currentPath = $(get-location).path
    $scriptPath = join-path -path $currentPath -childPath 'source/resource/scripts/Install-MFBuildDependencies.ps1'
    $templatePath = join-path -path $currentPath -childPath 'source/resource/projectRoot/BuildDependencies.psd1'

    function New-TestProject
    {
        PARAM([string]$Dependencies)
        $root = join-path -path $TestDrive -childPath ([guid]::NewGuid().Guid)
        $null = new-item -Path $root -ItemType Directory -Force
        $null = new-item -Path (join-path $root 'moduleForgeConfig.xml') -ItemType File
        if($Dependencies)
        {
            Set-Content -LiteralPath (join-path $root 'BuildDependencies.psd1') -Value $Dependencies
        }
        $root
    }

    $pinned = @"
@{
    'Pester' = @{ version = '[6.0.0, 7.0.0)'; repository = 'PSGallery' }
    'ModuleForge' = @{ version = '1.4.0'; repository = 'PSGallery' }
}
"@
}

Describe 'Install-MFBuildDependencies' {
    BeforeEach{
        #Never install anything for real
        Mock Install-PSResource {}
        Mock Install-Module {}
        Mock Get-InstalledPSResource { [PSCustomObject]@{ Name = $Name; Version = [version]'1.0.0'; Prerelease = $null } }
    }

    It 'Should install everything in the file, at the pinned versions' {
        $null = & $scriptPath -ProjectPath (New-TestProject $pinned)
        Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter {
            $RequiredResource.Count -eq 2 -and $RequiredResource['Pester'].version -eq '[6.0.0, 7.0.0)' -and $RequiredResource['ModuleForge'].version -eq '1.4.0'
        }
    }

    It 'Should install only the modules asked for, matching names case-insensitively' {
        $null = & $scriptPath -ProjectPath (New-TestProject $pinned) -Name 'pester'
        Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter {
            $RequiredResource -and $RequiredResource.Count -eq 1 -and $RequiredResource.ContainsKey('Pester')
        }
    }

    It 'Should ignore the pinned versions when installing from PSGallery' {
        $null = & $scriptPath -ProjectPath (New-TestProject $pinned) -Source PSGallery
        Should -Invoke Install-PSResource -Times 0 -Exactly -ParameterFilter { $RequiredResource }
        Should -Invoke Install-PSResource -Times 2 -Exactly -ParameterFilter { $Name -and !$Prerelease -and $Repository -eq 'PSGallery' }
    }

    It 'Should allow prereleases when asked' {
        $null = & $scriptPath -ProjectPath (New-TestProject $pinned) -Source PSGalleryPrerelease -Name ModuleForge
        Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter { $Name -eq 'ModuleForge' -and $Prerelease }
    }

    It 'Should fall back to PSGallery for a module the file does not pin' {
        $null = & $scriptPath -ProjectPath (New-TestProject $pinned) -Name 'Pester','PSScriptAnalyzer' -WarningVariable warned
        Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter { $RequiredResource -and $RequiredResource.ContainsKey('Pester') }
        Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter { $Name -eq 'PSScriptAnalyzer' }
        "$warned" | Should -Match 'PSScriptAnalyzer is not pinned'
    }

    It 'Should install the essential modules from PSGallery when there is no file' {
        $null = & $scriptPath -ProjectPath (New-TestProject) -WarningVariable warned
        Should -Invoke Install-PSResource -Times 3 -Exactly -ParameterFilter { $Name -in 'ModuleForge','Pester','PSScriptAnalyzer' }
        "$warned" | Should -Match 'No BuildDependencies.psd1'
    }

    It 'Should report the version each module resolved to' {
        $result = & $scriptPath -ProjectPath (New-TestProject $pinned) -Name Pester
        $result.Name | Should -Be 'Pester'
        $result.Version | Should -Be '1.0.0'
    }

    It 'Should bootstrap PSResourceGet only when it is missing' {
        $null = & $scriptPath -ProjectPath (New-TestProject $pinned) -Name Pester
        Should -Invoke Install-Module -Times 0 -Exactly
    }

    It 'Should stop when an install fails' {
        Mock Install-PSResource { throw 'feed unavailable' }
        { & $scriptPath -ProjectPath (New-TestProject $pinned) -Name Pester } | Should -Throw '*feed unavailable*'
    }
}

Describe 'BuildDependencies.psd1 template' {
    BeforeAll{
        $template = Import-PowerShellDataFile -LiteralPath $templatePath
    }
    It 'Should be a valid data file' {
        $template | Should -BeOfType [hashtable]
    }
    It 'Should pin <_> to a version range on PSGallery' -ForEach @('ModuleForge','Pester','PSScriptAnalyzer','platyPS') {
        $template[$_].version | Should -Match '^\[.+\)$'
        $template[$_].repository | Should -Be 'PSGallery'
    }
    It 'Should not list PSResourceGet, which installs everything else' {
        $template.ContainsKey('Microsoft.PowerShell.PSResourceGet') | Should -BeFalse
    }
}
