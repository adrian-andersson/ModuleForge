[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{
    #Load This File
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
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
    It 'Should throw when StableRelease is used on a non-prerelease version' {
        { Get-MFNextSemver -Version ([semver]::new('1.0.0')) -StableRelease } | Should -Throw
    }
}

Describe 'Get-MFNextSemver Prerelease Label Change' {
    It 'Should reset prerelease counter to 001 when label changes' {
        $preReleaseVersion = [semver]::new('1.0.0-prev003')
        $result = Get-MFNextSemver -Version $preReleaseVersion -PreRelease -PreReleaseLabel 'stage'
        $result.ToString() | Should -BeExactly '1.0.0-stagev001'
    }
}