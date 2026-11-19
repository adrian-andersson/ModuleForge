[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{
    $WarningPreference = 'SilentlyContinue'
    #Load This File
    . ($PSCommandPath -replace '\.tests\.ps1$','.ps1')
}

Describe 'Get-MFNextSemver' {
    BeforeAll {
        $initialVersion = get-mfNextSemver -initialPreRelease
    }
    It 'should substantiate correct initial version' {
        $initialVersion.ToString() | should -BeExactly '1.0.0-prev001'
    }
    It 'Should increment the prerelease version'{
        $next = get-mfNextSemver -version $initialVersion -prerelease
        $next.ToString() | should -BeExactly '1.0.0-prev002'
    }
    It 'Should create a stable version'{
        $next = get-mfNextSemver -version $initialVersion -stableRelease
        $next.ToString() | should -BeExactly '1.0.0'
    }
    It 'Should increase the Patch version into a new PreRelease' {
        $next = get-mfNextSemver -version $initialVersion -stableRelease
        $newPreRelease = get-mfNextSemver -version $next -prerelease -increment Patch
        $newPreRelease.ToString() | should -BeExactly '1.0.1-prev001'
    }
    It 'Should increase the Minor version into a new PreRelease' {
        $next = get-mfNextSemver -version $initialVersion -stableRelease
        $newPreRelease = get-mfNextSemver -version $next -prerelease -increment Minor
        $newPreRelease.ToString() | should -BeExactly '1.1.0-prev001'
    }
    It 'Should increase the Major version into a new PreRelease'  {
        $next = get-mfNextSemver -version $initialVersion -stableRelease
        $newPreRelease = get-mfNextSemver -version $next -prerelease -increment Major
        $newPreRelease.ToString() | should -BeExactly '2.0.0-prev001'
    }
    It 'Should create a new patch Prerelease'  {
        $newPreRelease = get-mfNextSemver -version $([semver]::new('3.0.0')) -prerelease
        $newPreRelease.ToString() | should -BeExactly '3.0.1-prev001'
    }

    It 'Should create a new prerelease label and restart the prerelease numbering'  {
        $newPreRelease = get-mfNextSemver -version $([semver]::new('3.0.0')) -prerelease -preReleaseLabel 'stage'
        $newPreRelease.ToString() | should -BeExactly '3.0.1-stagev001'
    }
}

Describe 'Get-MFNextSemver Error Handling' {
    It 'Should throw when no increment or switch is provided' {
        { Get-MFNextSemver -Version ([semver]::new('1.0.0')) } | Should -Throw
    }
    It 'Should throw a clear message when promoting a version that is already stable' {
        { Get-MFNextSemver -Version ([semver]::new('1.0.0')) -StableRelease } | Should -Throw '*already stable*'
    }
}

Describe 'Get-MFNextSemver release matrix' {
    #Every increment and release type, from a prerelease and from a stable version. As Build and Release calls it
    It 'From <From>, increment <Increment>, <Release> gives <Expected>' -ForEach @(
        @{ From = '1.2.3-prev002'; Increment = $null;   Release = 'PreRelease';    Expected = '1.2.3-prev003' }
        @{ From = '1.2.3-prev002'; Increment = 'Patch'; Release = 'PreRelease';    Expected = '1.2.4-prev001' }
        @{ From = '1.2.3-prev002'; Increment = 'Minor'; Release = 'PreRelease';    Expected = '1.3.0-prev001' }
        @{ From = '1.2.3-prev002'; Increment = 'Major'; Release = 'PreRelease';    Expected = '2.0.0-prev001' }
        @{ From = '1.2.3-prev002'; Increment = $null;   Release = 'StableRelease'; Expected = '1.2.3' }
        @{ From = '1.2.3-prev002'; Increment = 'Patch'; Release = 'StableRelease'; Expected = '1.2.4' }
        @{ From = '1.2.3-prev002'; Increment = 'Minor'; Release = 'StableRelease'; Expected = '1.3.0' }
        @{ From = '1.2.3-prev002'; Increment = 'Major'; Release = 'StableRelease'; Expected = '2.0.0' }
        @{ From = '1.2.3';         Increment = $null;   Release = 'PreRelease';    Expected = '1.2.4-prev001' }
        @{ From = '1.2.3';         Increment = 'Patch'; Release = 'PreRelease';    Expected = '1.2.4-prev001' }
        @{ From = '1.2.3';         Increment = 'Minor'; Release = 'PreRelease';    Expected = '1.3.0-prev001' }
        @{ From = '1.2.3';         Increment = 'Major'; Release = 'PreRelease';    Expected = '2.0.0-prev001' }
        @{ From = '1.2.3';         Increment = 'Patch'; Release = 'StableRelease'; Expected = '1.2.4' }
        @{ From = '1.2.3';         Increment = 'Minor'; Release = 'StableRelease'; Expected = '1.3.0' }
        @{ From = '1.2.3';         Increment = 'Major'; Release = 'StableRelease'; Expected = '2.0.0' }
    ) {
        $splat = @{ Version = [semver]$From; $Release = $true }
        if($Increment){ $splat.Increment = $Increment }
        (Get-MFNextSemver @splat).ToString() | Should -BeExactly $Expected
    }
}

Describe 'Get-MFNextSemver Prerelease Label Change' {
    It 'Should reset prerelease counter to 001 when label changes' {
        $preReleaseVersion = [semver]::new('1.0.0-prev003')
        $result = Get-MFNextSemver -Version $preReleaseVersion -PreRelease -PreReleaseLabel 'stage'
        $result.ToString() | Should -BeExactly '1.0.0-stagev001'
    }
    It 'Should continue the counter for a label containing a v' {
        $result = Get-MFNextSemver -Version ([semver]'1.0.0-devv003') -PreRelease
        $result.ToString() | Should -BeExactly '1.0.0-devv004'
    }
    It 'Should continue the counter for a label ending in v' {
        $result = Get-MFNextSemver -Version ([semver]'1.0.0-previewv009') -PreRelease
        $result.ToString() | Should -BeExactly '1.0.0-previewv010'
    }
    It 'Should continue the counter, without a warning, when the same label is supplied' {
        $result = Get-MFNextSemver -Version ([semver]'1.0.0-prev003') -PreRelease -PreReleaseLabel 'pre' -WarningVariable warned -WarningAction SilentlyContinue
        $result.ToString() | Should -BeExactly '1.0.0-prev004'
        $warned | Should -BeNullOrEmpty
    }
    It 'Should warn and continue the counter when only the label casing changes' {
        $result = Get-MFNextSemver -Version ([semver]'1.0.0-prev003') -PreRelease -PreReleaseLabel 'Pre' -WarningVariable warned -WarningAction SilentlyContinue
        $result.ToString() | Should -BeExactly '1.0.0-Prev004'
        $warned | Should -Not -BeNullOrEmpty
    }
    It 'Should start again at v001, with a warning, for a prerelease not in the label-v-number format' {
        $result = Get-MFNextSemver -Version ([semver]'1.0.0-beta.1') -PreRelease -WarningVariable warned -WarningAction SilentlyContinue
        $result.ToString() | Should -BeExactly '1.0.0-prev001'
        $warned | Should -Not -BeNullOrEmpty
    }
}