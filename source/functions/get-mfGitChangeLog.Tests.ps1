BeforeAll{

    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    
    #Load This File
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')

    $tempCopyLocation = join-path -Path $currentPath -ChildPath 'TempCopy'

    $privatePath = join-path $sourcePath -ChildPath 'private'

}

Describe 'Git Mocking' {
    BeforeAll{
        #https://pester.dev/docs/usage/mocking/
        #Mocking a command line is apparently not so straight forwards.
        #If I make a function though and alias git to it, then it should in theory serve the correct purpose
        #Not a true MOCK, but good enough
        #Need a way to handle potentially multiple param arguments, out of order, in different formats, this is my approach
        function invoke-GitCommand{
            [CmdletBinding()]
            PARAM(
                [Parameter(Position = 0)]
                [Alias("p0")]
                [string]$Param0,
                [Parameter(Position = 1)]
                [Alias("p1")]
                [string]$Param1,
                [Parameter(Position = 2)]
                [Alias("p2")]
                [string]$Param2,
                [Parameter(Position = 3)]
                [Alias("p3")]
                [string]$Param3,
                [Parameter(Position = 4)]
                [Alias("p4")]
                [string]$Param4,
                [Parameter(Position = 5)]
                [Alias("p5")]
                [string]$Param5,
                [Parameter(Position = 6)]
                [Alias("p6")]
                [string]$Param6
            )

            begin{
                $commandLine = "$Param0 $Param1 $Param2 $Param3 $Param4 $Param5 $Param6"
                $commandLine = $commandLine.trim()
            }
            
            process{
                write-warning "Command provided: $commandLine"
                switch -Wildcard ($commandLine) {
                    '--version' { return 'git version 2.30.0.mock' }
                    'rev-parse --is-inside-work-tree' { return 'true' }
                    'tag --sort=-creatordate' { return @('v1.1.0', 'v1.0.0') -join "`n" }
                    'log v1.0.0..v1.1.0 --pretty=format:"%s"' { return @('feat: Added new feature', 'fix: Fixed bug', 'docs: Updated documentation') }
                    'log v1.0.0..v1.1.0 --pretty=format:%s' { return @('feat: Added new feature', 'fix: Fixed bug', 'docs: Updated documentation') }
                    'log --pretty=format:"%s"' { return @('feat: Initial commit') }
                    'log --pretty=format:%s' { return @('feat: Initial commit') }
                    '--one --two' { return 'Multi Param Mocked' }
                    default { throw "Unexpected git command: $commandLine" }
                }
            }
        }

        Set-Alias -name 'git' -Value invoke-GitCommand
    }
    

    It 'should Mock Git Version Correctly' {
        $test = git --version
        $test | should -be 'git version 2.30.0.mock'
    }

    It 'should Mock Git MultiParam Correctly' {
        $test = git --one --two
        $test | should -be 'Multi Param Mocked'
    }

    It 'should Mock Git rev-parse Correctly' {
        $test = git rev-parse --is-inside-work-tree
        $test | should -be 'true'
    }

    It 'should Mock Git format correctly' {
        $test = git log --pretty=format:"%s"
        $test | should -be 'feat: Initial commit'
    }

}
<#
# Define the Pester tests
Describe 'get-mfGitChangeLog for Multi Tag' {
    # Mock the git version command
    BeforeAll{
        Mock git {
            write-verbose 'Mocking GIT'
            write-warning "Args: $args"
            switch -Wildcard ($args) {
                '--version' { return 'git version 2.30.0.mock' }
                'rev-parse --is-inside-work-tree' { return 'true' }
                'tag --sort=-creatordate' { return @('v1.1.0', 'v1.0.0') }
                'log v1.0.0..v1.1.0 --pretty=format:"%s"' { return @('feat: Added new feature', 'fix: Fixed bug', 'docs: Updated documentation') }
                'log --pretty=format:"%s"' { return @('feat: Initial commit') }
                default { throw "Unexpected git command: $args" }
            }

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


#>