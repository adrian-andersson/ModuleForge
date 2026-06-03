[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Load This File
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')

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
                Write-Verbose "Command provided: $commandLine"
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

    AfterAll{
        remove-alias git
    }

}

# Define the Pester tests
Describe 'get-mfGitChangeLog for Multi Tag' {
    # Mock the git version command
    BeforeAll{
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


                $tags = @(
                    'v1.0.1-prev006',
                    'v1.0.1-prev005',
                    'v1.0.1-prev004',
                    'v1.0.1-prev003',
                    'v1.0.1-prev002',
                    'v1.0.1-prev001'
                )

                $prettyLog = @(
                    'feat: errors are now a feature'
                    'test: threw spaget at wall to see what stuck'
                    'fix: Added bandaid to small memory leak'
                    'fix: Fixed bug that was stuck on fly paper by removing fly paper'
                    'test: Added true test of patience'
                    'feat: Added another hello world example'
                    'feat: Added new feature'
                    'chore: mopped the floor'
                    'chore: washed the dishes'
                    'fix: Removed the throw command and changed to Write-verbose so error is now a feature'
                    'perf: Removed artificial sleep timer to drastically improve performance'
                    'perf: increased caffiene dossage by ordering strong flatwhite instead of regular flatwhite'
                    'docs: Updated documentation by switching from single spacing to 1.5 spacing and changing font to comic-sans'
                    'refactor: changed ritual sacrifice from jane to jenny '
                )
            }
            
            process{
                Write-Verbose "Command provided: $commandLine"
                switch -Wildcard ($commandLine) {
                    '--version' { return 'git version 2.30.0.mock' }
                    'rev-parse --is-inside-work-tree' { return 'true' }
                    'tag --sort=-creatordate' { return $tags }
                    'log v1.0.1-prev005..v1.0.1-prev006 --pretty=format:"%s"' { return $prettyLog }
                    'log v1.0.1-prev005..v1.0.1-prev006 --pretty=format:%s' { return $prettyLog }
                    default { throw "Unexpected git command: $commandLine" }
                }
            }
        }

        Set-Alias -name 'git' -Value invoke-GitCommand

        $result = get-mfGitChangeLog

        write-verbose $result
    
    }

    # Test case for multiple tags
    It 'should generate changelog for multiple tags' {

        $result | Should -BeLike '*# Change Log*'
        $result | Should -BeLike '*Version: v1.0.1-prev005 --> v1.0.1-prev006*'
        $result | Should -BeLike '*## New Features*'
        $result | Should -BeLike '*- Added new feature*'
        $result | Should -BeLike '*## Bug Fixes*'
        $result | Should -BeLike '*- Fixed bug*'
        $result | Should -BeLike '*## Documentation Changes*'
        $result | Should -BeLike '*- Updated documentation*'
        $result | should -belike '*## Code Rewrite/Refactor*'
        $result | should -Not -BeLike '*## Chore*'
        #>
    }

    
    AfterAll{
        remove-alias git
    }


}

# Define the Pester tests
Describe 'get-mfGitChangeLog for Single Tag' {
    # Mock the git version command
    BeforeAll{
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


                $tags = @(
                    'v1.0.1-prev001'
                )

                $prettyLog = @(
                    'feat: errors are now a feature'
                    'test: threw spaget at wall to see what stuck'
                    'fix: Added bandaid to small memory leak'
                    'fix: Fixed bug that was stuck on fly paper by removing fly paper'
                    'test: Added true test of patience'
                    'feat: Added another hello world example'
                    'feat: Added new feature'
                    'chore: mopped the floor'
                    'chore: washed the dishes'
                    'fix: Removed the throw command and changed to Write-verbose so error is now a feature'
                    'perf: Removed artificial sleep timer to drastically improve performance'
                    'perf: increased caffiene dossage by ordering strong flatwhite instead of regular flatwhite'
                    'docs: Updated documentation by switching from single spacing to 1.5 spacing and changing font to comic-sans'
                    'refactor: changed ritual sacrifice from jane to jenny '
                )
            }
            
            process{
                Write-Verbose "Command provided: $commandLine"
                switch -Wildcard ($commandLine) {
                    '--version' { return 'git version 2.30.0.mock' }
                    'rev-parse --is-inside-work-tree' { return 'true' }
                    'tag --sort=-creatordate' { return $tags }
                    'log --pretty=format:"%s"' { return $prettyLog }
                    'log --pretty=format:%s' { return $prettyLog }
                    default { throw "Unexpected git command: $commandLine" }
                }
            }
        }

        Set-Alias -name 'git' -Value invoke-GitCommand

        $result = get-mfGitChangeLog

        write-verbose $result
    
    }

    # Test case for multiple tags
    It 'should generate changelog for Single tags' {

        $result | Should -BeLike '*# Change Log*'
        $result | Should -BeLike '*## New Features*'
        $result | Should -BeLike '*- Added new feature*'
        $result | Should -BeLike '*## Bug Fixes*'
        $result | Should -BeLike '*- Fixed bug*'
        $result | Should -BeLike '*## Documentation Changes*'
        $result | Should -BeLike '*- Updated documentation*'
        $result | should -belike '*## Code Rewrite/Refactor*'
        $result | should -Not -BeLike '*## Chore*'
        #>
    }

    
    AfterAll{
        remove-alias git
    }


}


Describe 'get-mfGitChangeLog for Custom changeLogTypes' {
    # Mock the git version command
    BeforeAll{
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


                $tags = @(
                    'v1.0.1-prev001'
                )

                $prettyLog = @(
                    'feat: errors are now a feature'
                    'test: threw spaget at wall to see what stuck'
                    'fix: Added bandaid to small memory leak'
                    'fix: Fixed bug that was stuck on fly paper by removing fly paper'
                    'test: Added true test of patience'
                    'feat: Added another hello world example'
                    'feat: Added new feature'
                    'chore: mopped the floor'
                    'chore: washed the dishes'
                    'fix: Removed the throw command and changed to Write-verbose so error is now a feature'
                    'perf: Removed artificial sleep timer to drastically improve performance'
                    'perf: increased caffiene dossage by ordering strong flatwhite instead of regular flatwhite'
                    'docs: Updated documentation by switching from single spacing to 1.5 spacing and changing font to comic-sans'
                    'refactor: changed ritual sacrifice from jane to jenny '
                )
            }
            
            process{
                Write-Verbose "Command provided: $commandLine"
                switch -Wildcard ($commandLine) {
                    '--version' { return 'git version 2.30.0.mock' }
                    'rev-parse --is-inside-work-tree' { return 'true' }
                    'tag --sort=-creatordate' { return $tags }
                    'log --pretty=format:"%s"' { return $prettyLog }
                    'log --pretty=format:%s' { return $prettyLog }
                    default { throw "Unexpected git command: $commandLine" }
                }
            }
        }

        Set-Alias -name 'git' -Value invoke-GitCommand

        $changeLogTypes = @{
            'chore' = 'Chore and Pipeline work'
            'test' = 'Testing'
        }

        $result = get-mfGitChangeLog -changeLogTypes $changeLogTypes

        write-verbose $result
    
    }

    # Test case for multiple tags
    It 'should generate changelog for Single tags' {

        $result | Should -BeLike '*# Change Log*'
        $result | Should -Not -BeLike '*## New Features*'
        $result | Should -Not -BeLike '*- Added new feature*'
        $result | Should -Not -BeLike '*## Bug Fixes*'
        $result | Should -Not -BeLike '*- Fixed bug*'
        $result | Should -Not -BeLike '*## Documentation Changes*'
        $result | Should -Not -BeLike '*- Updated documentation*'
        $result | should -Not -belike '*## Code Rewrite/Refactor*'
        $result | should -BeLike '*## Chore*'
        $result | should -BeLike '*## Testing*'
        #>
    }

    
    AfterAll{
        remove-alias git
    }
}

Describe 'get-mfGitChangeLog for Multi Tag with -All' {

    # Mock the git version command
    BeforeAll{
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


                $tags = @(
                    'v1.0.1',
                    'v1.0.1-prev002',
                    'v1.0.1-prev001'
                )

                $prettyLog1 = @(
                    'feat: errors are now a feature'
                    'test: threw spaget at wall to see what stuck'
                    'fix: Added bandaid to small memory leak'
                    'fix: Fixed bug that was stuck on fly paper by removing fly paper'
                )
                $prettyLog2 = @(
                    'test: Added true test of patience'
                    'feat: Added another hello world example'
                    'feat: Added new feature'
                )
                $prettyLog3 = @(
                    'chore: mopped the floor'
                    'chore: washed the dishes'
                    'fix: Removed the throw command and changed to Write-verbose so error is now a feature'
                    'perf: Removed artificial sleep timer to drastically improve performance'
                    'perf: increased caffiene dossage by ordering strong flatwhite instead of regular flatwhite'
                    'docs: Updated documentation by switching from single spacing to 1.5 spacing and changing font to comic-sans'
                    'refactor: changed ritual sacrifice from jane to jenny '
                )
            }
            
            process{
                Write-Verbose "Command provided: $commandLine"
                switch -Wildcard ($commandLine) {
                    '--version' { return 'git version 2.30.0.mock' }
                    'rev-parse --is-inside-work-tree' { return 'true' }
                    'tag --sort=-creatordate' { return $tags }
                    'log v1.0.1-prev002..v1.0.1 --pretty=format:%s' { return $prettyLog1 }
                    'log v1.0.1-prev001..v1.0.1-prev002 --pretty=format:%s' { return $prettyLog2 }
                    'log v1.0.1-prev001 --pretty=format:%s' { return $prettyLog3 }
                    default { throw "Unexpected git command: $commandLine" }
                }
            }
        }

        Set-Alias -name 'git' -Value invoke-GitCommand

        $result = get-mfGitChangeLog -all

        write-verbose $result
    
    }

    # Test case for multiple tags
    It 'should generate changelog for All Switch' {

        $result | Should -BeLike '*# Change Log*'
        $result | Should -BeLike '*## Version: v1.0.1*'
        $result | Should -BeLike '*## Version: v1.0.1-prev002*'
        $result | Should -BeLike '*## Version: v1.0.1-prev001*'
        $result | Should -BeLike '*### New Features*'
        $result | Should -BeLike '*- Added new feature*'
        $result | Should -BeLike '*### Bug Fixes*'
        $result | Should -BeLike '*- Fixed bug*'
        $result | Should -BeLike '*### Documentation Changes*'
        $result | Should -BeLike '*- Updated documentation*'
        $result | should -belike '*### Code Rewrite/Refactor*'
        $result | should -Not -BeLike '*## Chore*'
        #>
    }

    
    AfterAll{
        remove-alias git
    }
}

Describe 'get-mfGitChangeLog with -fromLastTag and single tag' {
    # Mock the git version command
    BeforeAll{
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


                $tags = @(
                    'v1.0.1',
                    'v1.0.1-prev002',
                    'v1.0.1-prev001'
                )

                $prettyLog1 = @(
                    'feat: errors are now a feature'
                    'test: threw spaget at wall to see what stuck'
                    'fix: Added bandaid to small memory leak'
                    'fix: Fixed bug that was stuck on fly paper by removing fly paper'
                    'feat: this feature is untagged'
                )
            }
            
            process{
                Write-Verbose "Command provided: $commandLine"
                switch -Wildcard ($commandLine) {
                    '--version' { return 'git version 2.30.0.mock' }
                    'rev-parse --is-inside-work-tree' { return 'true' }
                    'tag --sort=-creatordate' { return $tags }
                    'log v1.0.1..HEAD --pretty=format:%s' { return $prettyLog1 }
                    default { throw "Unexpected git command: $commandLine" }
                }
            }
        }

        Set-Alias -name 'git' -Value invoke-GitCommand

        $result = get-mfGitChangeLog -fromLastTag

        write-verbose $result
    
    }

    # Test case for multiple tags
    It 'should generate changelog for -fromLastTag Switch' {

        $result | Should -BeLike '*# Change Log*'
        $result | Should -BeLike '*## New Features*'
        $result | Should -BeLike '*- errors are now a feature*'
        $result | Should -BeLike '*- this feature is untagged*'
        $result | Should -BeLike '*## Bug Fixes*'
        $result | Should -BeLike '*- Fixed bug*'
        #>
    }

    
    AfterAll{
        remove-alias git
    }
}
