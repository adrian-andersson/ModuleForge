BeforeAll{

    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    
    #Load This File
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')

    $tempCopyLocation = join-path -Path $currentPath -ChildPath 'TempCopy'

    $privatePath = join-path $sourcePath -ChildPath 'private'

}


# Define the Pester tests
Describe 'get-mfGitChangeLog' {
    # Mock the git version command
    Mock git {
        param($args)
        if ($args -eq '--version') {
            return 'git version 2.30.0'
        }
        if ($args -eq 'rev-parse --is-inside-work-tree') {
            return 'true'
        }
        if ($args -eq 'tag --sort=-creatordate') {
            return @('v1.1.0', 'v1.0.0')
        }
        if ($args -eq 'log v1.0.0..v1.1.0 --pretty=format:"%s"') {
            return @('feat: Added new feature', 'fix: Fixed bug', 'docs: Updated documentation')
        }
        if ($args -eq 'log --pretty=format:"%s"') {
            return @('feat: Initial commit')
        }
    }

    # Test case for multiple tags
    It 'should generate changelog for multiple tags' {
        $changeLogTypes = @{
            'feat' = 'New Features'
            'fix' = 'Bug Fixes'
            'docs' = 'Documentation Changes'
        }
        $result = get-mfGitChangeLog -changeLogTypes $changeLogTypes
        $result | Should -Contain '# Change Log'
        $result | Should -Contain 'Version: v1.0.0 --> v1.1.0'
        $result | Should -Contain '## New Features'
        $result | Should -Contain '- Added new feature'
        $result | Should -Contain '## Bug Fixes'
        $result | Should -Contain '- Fixed bug'
        $result | Should -Contain '## Documentation Changes'
        $result | Should -Contain '- Updated documentation'
    }

    # Test case for single tag
    It 'should generate changelog for single tag' {
        Mock git {
            param($args)
            if ($args -eq 'tag --sort=-creatordate') {
            return @('v1.0.0')
            }
        }

        $changeLogTypes = @{
            'feat' = 'New Features'
            'fix' = 'Bug Fixes'
            'docs' = 'Documentation Changes'
        }
        $result = get-mfGitChangeLog -changeLogTypes $changeLogTypes
        $result | Should -Contain '# Change Log'
        $result | Should -Contain 'Version: v1.0.0'
        $result | Should -Contain '## New Features'
        $result | Should -Contain '- Initial commit'
    }

    # Test case for no tags
    It 'should warn when no tags are found' {
        Mock git {
            param($args)
            if ($args -eq 'tag --sort=-creatordate') {
            return @()
            }
        }

        $changeLogTypes = @{
            'feat' = 'New Features'
            'fix' = 'Bug Fixes'
            'docs' = 'Documentation Changes'
        }
        { get-mfGitChangeLog -changeLogTypes $changeLogTypes } | Should -Throw -ErrorId 'No tags found. May not be a release.'
}
}
