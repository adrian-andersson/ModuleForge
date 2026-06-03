#Requires -Module Pester
<#
    .SYNOPSIS
        Run Pester tests for a ModuleForge project with code coverage.

    .DESCRIPTION
        Locates the ModuleForge project root by walking up from the script's own directory,
        discovers all source\functions test files, and runs Pester with code coverage enabled
        across all non-test function scripts.

        .Tests.ps1 and .Skip.ps1 files are always excluded from coverage measurement.
        Additional filenames can be excluded via the ExcludeFromCoverage parameter.

        Sets the working directory to the project root before invoking Pester so that
        test files using the existing get-location convention resolve paths correctly.

        Does not import or depend on ModuleForge. Safe to run in a clean CI environment.

    .EXAMPLE
        .\scripts\Invoke-MFPester.ps1

        Run all Pester tests with code coverage from a clean environment.

    .EXAMPLE
        .\scripts\Invoke-MFPester.ps1 -ExcludeFromCoverage 'Get-Something.ps1'

        Run all tests, excluding the named file from code coverage metrics.

    .NOTES
        Author: Adrian Andersson
#>
[CmdletBinding()]
PARAM(
    #Filenames (not full paths) to exclude from code coverage measurement
    [Parameter()]
    [string[]]$ExcludeFromCoverage = @(),
    #Pester output verbosity level
    [Parameter()]
    [ValidateSet('None','Normal','Detailed','Diagnostic')]
    [string]$Verbosity = 'Detailed'
)

# Walk up from this script's directory to find moduleForgeConfig.xml
$searchPath = $PSScriptRoot
$root = $null
while($searchPath)
{
    if(Get-ChildItem -LiteralPath $searchPath -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ieq 'moduleForgeConfig.xml' })
    {
        $root = $searchPath
        break
    }
    $parent = Split-Path $searchPath -Parent
    if($parent -eq $searchPath){ break }
    $searchPath = $parent
}

if(-not $root)
{
    throw "Unable to locate 'moduleForgeConfig.xml' in '$PSScriptRoot' or any parent directory. Is this a ModuleForge project?"
}

Write-Verbose "Project root: $root"
$functionsPath = Join-Path $root 'source' 'functions'

if(!(Test-Path $functionsPath))
{
    throw "Functions folder not found at: $functionsPath"
}

$coveragePaths = (Get-ChildItem $functionsPath -Filter '*.ps1' -Recurse).Where{
    $_.Name -notmatch '\.Tests\.ps1$' -and
    $_.Name -notmatch '\.Skip\.ps1$' -and
    $_.Name -notin $ExcludeFromCoverage
}.FullName

Write-Verbose "Coverage files: $($coveragePaths.Count)"

$pesterConfig = New-PesterConfiguration -hashtable @{
    Run          = @{Passthru = $true; Path = $functionsPath}
    CodeCoverage = @{Enabled = $true; Path = $coveragePaths}
    Output       = @{Verbosity = $Verbosity}
}

$previousLocation = Get-Location
try
{
    Set-Location $root
    Invoke-Pester -Configuration $pesterConfig
}
finally
{
    Set-Location $previousLocation
}