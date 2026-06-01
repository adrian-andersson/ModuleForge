function Invoke-MFPester
{

    <#
        .SYNOPSIS
            Run Pester tests for a ModuleForge project with code coverage.

        .DESCRIPTION
            Locates the ModuleForge project root, discovers all source\functions test files,
            and runs Pester with code coverage enabled across all non-test function scripts.

            .Tests.ps1 and .Skip.ps1 files are always excluded from coverage measurement.
            Additional filenames can be excluded via the ExcludeFromCoverage parameter.

            Sets the working directory to the project root before invoking Pester so that
            test files using the existing get-location convention resolve paths correctly.

        .EXAMPLE
            Invoke-MFPester

            #### DESCRIPTION
            Run all Pester tests with code coverage from the current project directory.

        .EXAMPLE
            Invoke-MFPester -ExcludeFromCoverage 'Get-MFFolderItemDetails.ps1'

            #### DESCRIPTION
            Run all tests, but exclude the named file from code coverage metrics.

        .EXAMPLE
            Invoke-MFPester -Verbosity Normal

            #### DESCRIPTION
            Run all tests with reduced output verbosity.

        .OUTPUTS
            [Pester.Run] - Returns the Pester run result object

        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding()]
    PARAM(
        #Root path of the module. Searches upward from the current working directory if not supplied
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [alias('Path')]
        [string]$ModulePath,
        #Filenames (not full paths) to exclude from code coverage measurement
        [Parameter()]
        [string[]]$ExcludeFromCoverage = @(),
        #Pester output verbosity level
        [Parameter()]
        [ValidateSet('None','Normal','Detailed','Diagnostic')]
        [string]$Verbosity = 'Detailed'
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }
    process{
        $getRootSplat = @{}
        if($ModulePath){$getRootSplat.ModulePath = $ModulePath}
        $root = Get-MFProjectRoot @getRootSplat

        write-verbose "Project root: $root"
        $functionsPath = join-path -path (join-path -path $root -ChildPath 'source') -ChildPath 'functions'

        if(!(test-path $functionsPath)){
            throw "Functions folder not found at: $functionsPath"
        }

        $coveragePaths = (get-childitem $functionsPath -Filter '*.ps1' -Recurse).Where{
            $_.Name -notmatch '\.Tests\.ps1$' -and
            $_.Name -notmatch '\.Skip\.ps1$' -and
            $_.Name -notin $ExcludeFromCoverage
        }.FullName

        write-verbose "Coverage files: $($coveragePaths.Count)"

        $pesterConfig = New-PesterConfiguration -hashtable @{
            Run          = @{Passthru = $true; Path = $functionsPath}
            CodeCoverage = @{Enabled = $true; Path = $coveragePaths}
            Output       = @{Verbosity = $Verbosity}
        }

        $previousLocation = get-location
        try{
            set-location $root
            Invoke-Pester -Configuration $pesterConfig
        }finally{
            set-location $previousLocation
        }
    }
}