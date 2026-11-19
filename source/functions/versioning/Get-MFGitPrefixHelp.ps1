function Get-MFGitPrefixHelp
{
<#
    .SYNOPSIS
        Displays a terminal friendly quick reference for ModuleForge commit prefixes.

    .DESCRIPTION
        Returns a short plain text summary of the commit prefix convention used by Get-MFGitChangeLog, including the commit format, the prefix list and the type of change each one is, examples, which Build and Release choice to pick, and common gotchas.
        Output is limited to ASCII and 80 columns so it reads well in any terminal. The full guide is at https://adrian-andersson.github.io/ModuleForge/commit-prefixes.html

    .EXAMPLE
        Get-MFGitPrefixHelp

        #### DESCRIPTION
        Show the full quick reference.

        #### OUTPUT
        ModuleForge commit prefixes
        Full guide: https://adrian-andersson.github.io/ModuleForge/commit-prefixes.html

        FORMAT
          <prefix>: <short description in imperative mood>
        ...

    .EXAMPLE
        Get-MFGitPrefixHelp -Section Gotchas

        #### DESCRIPTION
        Show only the gotchas section.

        #### OUTPUT
        ModuleForge commit prefixes
        Full guide: https://adrian-andersson.github.io/ModuleForge/commit-prefixes.html

        GOTCHAS
          Unknown prefixes are dropped without warning: feature:, bugfix:, feat!:
        ...

    .OUTPUTS
        [STRING] - Returns plain text that can be displayed or redirected to a file

    .NOTES
        Author: Adrian Andersson
    #>

    [CmdletBinding()]
    [OutputType([string])]
    PARAM(
        #Section to display. Displays every section by default
        [Parameter()]
        #Increments is the old name for Release, kept so existing calls still work
        [ValidateSet('All','Format','Prefixes','Examples','Release','Increments','Gotchas')]
        [string]$Section = 'All'
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        #Sections should match the defaults in Get-MFGitChangeLog. The tests compare the two so they cannot drift
        $prefixes = @(
            [PSCustomObject]@{Prefix = 'feat'; ChangeLog = 'New Features'; Type = 'Feature'; Example = 'add -IncludeChangeLog switch to Write-MFModuleDocs'}
            [PSCustomObject]@{Prefix = 'fix'; ChangeLog = 'Bug Fixes'; Type = 'Fix'; Example = 'handle empty commit history in Get-MFGitChangeLog'}
            [PSCustomObject]@{Prefix = 'docs'; ChangeLog = 'Documentation Changes'; Type = 'Non-module'; Example = 'update tutorial to use PSResourceGet syntax'}
            [PSCustomObject]@{Prefix = 'refactor'; ChangeLog = 'Code Rewrite/Refactor'; Type = 'Fix'; Example = 'simplify dependency resolution logic'}
            [PSCustomObject]@{Prefix = 'perf'; ChangeLog = 'Performance Improvements'; Type = 'Fix'; Example = 'reduce redundant git calls in Get-MFGitLatestVersion'}
            [PSCustomObject]@{Prefix = 'chore'; ChangeLog = '(excluded)'; Type = 'Non-module'; Example = 'update GitHub Actions runner to ubuntu-24.04'}
            [PSCustomObject]@{Prefix = 'test'; ChangeLog = '(excluded)'; Type = 'Non-module'; Example = 'add coverage for empty parameter set in New-MFProject'}
        )
    }

    process{
        write-verbose 'Building help sections'
        $rowFormat = '  {0,-10}{1,-27}{2}'
        $sections = [ordered]@{
            Format = @(
                'FORMAT'
                '  <prefix>: <short description in imperative mood>'
                '  Should complete "If applied, this commit will...". Under 72 characters.'
            )
            Prefixes = @(
                'PREFIXES'
                $($rowFormat -f 'Prefix','Changelog section','Type of change')
                $($rowFormat -f '------','-----------------','--------------')
                $($prefixes.foreach{$rowFormat -f "$($_.Prefix):",$_.ChangeLog,$_.Type})
            )
            Examples = @(
                'EXAMPLES'
                $($prefixes.foreach{"  $($_.Prefix): $($_.Example)"})
            )
            Release = @(
                'RELEASE'
                '  Build and Release asks what you are releasing. The changes since the last'
                '  stable release say whether to start a new prerelease series:'
                '  Any breaking change            New Prerelease Series: major'
                '  One or more feat:              New Prerelease Series: minor'
                '  Anything else                  Next Prerelease'
                '  Start a series once, run Next Prerelease until it is ready, then'
                '  Promote to Stable.'
            )
            Gotchas = @(
                'GOTCHAS'
                '  Unknown prefixes are dropped without warning: feature:, bugfix:, ci:,'
                '    feat!:. Use chore: for CI changes.'
                '  Scopes are not supported yet, so feat(build): is dropped too.'
                '  Only the subject line is read. A BREAKING CHANGE: note in the body has'
                '    no effect, so start a New Prerelease Series: major yourself.'
                '  Prefixes do not choose the version. They only guide the release you pick.'
                '  Azure DevOps squash merges start with "Merged PR 11:", which hides the'
                '    prefix. Edit the squash message so that it starts with the prefix.'
                '  If only chore: and test: commits exist, the changelog has no entries.'
                '  A custom -ChangeLogTypes replaces the defaults, so list every prefix.'
            )
        }

        $selected = switch($Section){ 'All' { $sections.Keys } 'Increments' { 'Release' } default { $Section } }
        $output = @(
            'ModuleForge commit prefixes'
            'Full guide: https://adrian-andersson.github.io/ModuleForge/commit-prefixes.html'
            foreach($name in $selected){
                ''
                $sections[$name]
            }
        )

        write-verbose 'Converting to String'
        return $output -join "`n"
    }
}
