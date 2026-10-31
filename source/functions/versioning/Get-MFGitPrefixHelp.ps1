function Get-MFGitPrefixHelp
{
<#
    .SYNOPSIS
        Displays a terminal friendly quick reference for ModuleForge commit prefixes.

    .DESCRIPTION
        Returns a short plain text summary of the commit prefix convention used by Get-MFGitChangeLog, including the commit format, the prefix list, examples, how to pick a version increment, and common gotchas.
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
        [ValidateSet('All','Format','Prefixes','Examples','Increments','Gotchas')]
        [string]$Section = 'All'
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        #Sections should match the defaults in Get-MFGitChangeLog. The tests compare the two so they cannot drift
        $prefixes = @(
            [PSCustomObject]@{Prefix = 'feat'; ChangeLog = 'New Features'; Bump = 'minor'; Example = 'add -IncludeChangeLog switch to Write-MFModuleDocs'}
            [PSCustomObject]@{Prefix = 'fix'; ChangeLog = 'Bug Fixes'; Bump = 'patch'; Example = 'handle empty commit history in Get-MFGitChangeLog'}
            [PSCustomObject]@{Prefix = 'docs'; ChangeLog = 'Documentation Changes'; Bump = 'none'; Example = 'update tutorial to use PSResourceGet syntax'}
            [PSCustomObject]@{Prefix = 'refactor'; ChangeLog = 'Code Rewrite/Refactor'; Bump = 'patch'; Example = 'simplify dependency resolution logic'}
            [PSCustomObject]@{Prefix = 'perf'; ChangeLog = 'Performance Improvements'; Bump = 'patch'; Example = 'reduce redundant git calls in Get-MFGitLatestVersion'}
            [PSCustomObject]@{Prefix = 'chore'; ChangeLog = '(excluded)'; Bump = 'none'; Example = 'update GitHub Actions runner to ubuntu-24.04'}
            [PSCustomObject]@{Prefix = 'test'; ChangeLog = '(excluded)'; Bump = 'none'; Example = 'add coverage for empty parameter set in New-MFProject'}
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
                $($rowFormat -f 'Prefix','Changelog section','Typical bump')
                $($rowFormat -f '------','-----------------','------------')
                $($prefixes.foreach{$rowFormat -f "$($_.Prefix):",$_.ChangeLog,$_.Bump})
            )
            Examples = @(
                'EXAMPLES'
                $($prefixes.foreach{"  $($_.Prefix): $($_.Example)"})
            )
            Increments = @(
                'VERSION INCREMENT'
                '  Pick one at release time, based on the commits since the last tag:'
                '  Any breaking change            major'
                '  One or more feat:              minor'
                '  Only fix:, refactor:, perf:    patch'
                '  Only docs:, chore:, test:      none'
            )
            Gotchas = @(
                'GOTCHAS'
                '  Unknown prefixes are dropped without warning: feature:, bugfix:, feat!:'
                '  Scopes are not supported yet, so feat(build): is dropped too.'
                '  Text after a second colon is lost: "fix: bad path: C:\x" -> "bad path"'
                '  Only the subject line is read. A BREAKING CHANGE: note in the body has'
                '    no effect, so choose the major increment yourself.'
                '  Prefixes do not bump versions. They only guide the increment you pick.'
                '  Azure DevOps squash merges start with "Merged PR 11:", which hides the'
                '    prefix. Edit the squash message so that it starts with the prefix.'
                '  If only chore: and test: commits exist, the changelog has no entries.'
                '  A custom -ChangeLogTypes replaces the defaults, so list every prefix.'
            )
        }

        $selected = if($Section -eq 'All'){$sections.Keys}else{$Section}
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
