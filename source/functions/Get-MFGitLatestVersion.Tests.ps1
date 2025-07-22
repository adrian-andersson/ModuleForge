BeforeAll{
    
    #Load This File
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')

}

Describe 'Get-MFGitLatestVersion' {
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
                $tags = @(
                    'v1.0.1-prev001'
                    'v1.0.1-prev002'
                    'v1.0.1-prev003'
                    'v1.0.1-prev004'
                    'v1.0.1-prev005'
                    'v1.1.0-prev001'
                )
            }
            
            process{
                Write-Verbose "Command provided: $commandLine"
                switch -Wildcard ($commandLine) {
                    '--version' { return 'git version 2.30.0.mock' }
                    'tag *' {$global:LASTEXITCODE = 0 ;return $tags } #Need to make sure we are setting the exitcode to 0 for this, else the get-mfGitlatestVersion may trap incorrectly
                    default { throw "Unexpected git command: $commandLine" }
                }
            }
        }

        Set-Alias -name 'git' -Value invoke-GitCommand

        $latestVer = get-mfGitLatestVersion -Verbose
    }

    It 'should Mock Git Version Correctly' {
        $test = git --version
        $test | should -be 'git version 2.30.0.mock'
    }

    It 'Should have returned the correct version' {
        $latestVer.GetType().name |should -be 'SemanticVersion'
        $latestVer.ToString() |should -be '1.1.0-prev001'
        $latestVer.prereleaselabel |should -be 'prev001'
    }

    AfterAll{
        remove-alias git
    }
}