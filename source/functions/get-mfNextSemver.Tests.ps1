BeforeAll{
    #Load This File
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
}

Describe 'get-mfNextSemver' {
    BeforeAll {
        $initialVersion = get-mfNextSemver -initialPreRelease
    }
    It 'should substantiate correct initial version' {
        $initialVersion.ToString() | should -BeExactly '1.0.0-PREv001'
    }
    It 'Should increment the prerelease version'{
        $next = get-mfNextSemver -version $initialVersion -prerelease
        $next.ToString() | should -BeExactly '1.0.0-PREv002'
    }
    It 'Should create a stable version'{
        $next = get-mfNextSemver -version $initialVersion -stableRelease
        $next.ToString() | should -BeExactly '1.0.0'
    }
    It 'Should increase the Patch version into a new PreRelease' {
        $next = get-mfNextSemver -version $initialVersion -stableRelease
        $newPreRelease = get-mfNextSemver -version $next -prerelease -increment Patch
        $newPreRelease.ToString() | should -BeExactly '1.0.1-PREv001'
    }
    It 'Should increase the Minor version into a new PreRelease' {
        $next = get-mfNextSemver -version $initialVersion -stableRelease
        $newPreRelease = get-mfNextSemver -version $next -prerelease -increment Minor
        $newPreRelease.ToString() | should -BeExactly '1.1.0-PREv001'
    }
    It 'Should increase the Major version into a new PreRelease'  {
        $next = get-mfNextSemver -version $initialVersion -stableRelease
        $newPreRelease = get-mfNextSemver -version $next -prerelease -increment Major
        $newPreRelease.ToString() | should -BeExactly '2.0.0-PREv001'
    }
    It 'Should create a new patch Prerelease'  {
        $newPreRelease = get-mfNextSemver -version $([semver]::new('3.0.0')) -prerelease
        $newPreRelease.ToString() | should -BeExactly '3.0.1-PREv001'
    }
}