function Get-MFScriptAnalyzerSummary
{

    <#
        .SYNOPSIS
            Runs, and then summarises the results of PSScriptAnalyzer across a set of PowerShell function files.
            
        .DESCRIPTION
            This function scans `.ps1` files using PSScriptAnalyzer and returns grouped summaries of errors, warnings, and informational findings.

            
        ------------
        .EXAMPLE
            Get-MFScriptAnalyzerSummary -SourcePath '.\source\functions'
            
            #### DESCRIPTION
            Runs PSScriptAnalyzer over all function files in the specified path, provides a summary
            
            
            #### OUTPUT
            Copy of the output of this line
            
            
            
        .NOTES
            Author: Adrian Andersson
            
    #>

    [CmdletBinding()]
    PARAM(
        #Source Path for function files
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$SourcePath = $(join-path $(join-path '.' -childPath 'source') -childPath functions),
        [parameter()]
        #What severities should we scan for
        [string[]]$Severity = @('Error','Warning','Information'),
        #What weights to provide each severity
        [Parameter(dontshow)]
        [hashtable]$Weights = @{
            Error = 50
            Warning = 15
            Information = 1
        },
        #Set this switch to only get the summary
        [Parameter()]
        [switch]$SuppressOutput,
        [Parameter()]
        #Set this for what rules to exclude.
        [string[]]$ExcludeRules = @(
            'PSAvoidTrailingWhitespace' #Noisy rule. Preference script readability over strict whitespace adherance
        )
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $psScriptAnalyzerSplat = @{
            severity = $Severity
            ExcludeRule = $ExcludeRules
        }

        if(!(get-module -ListAvailable 'PSScriptAnalyzer')){
            throw 'PSScriptAnalyzer module must be present on this system for this function to work'
        }
        
    }
    
    process{
        $functionFiles = Get-ChildItem -Recurse -Include '*.ps1' -Exclude '*.Tests.ps1' -Path $SourcePath 
        #Use a GenList to avoid iterative arrays
        $capture = [System.Collections.Generic.List[object]]::new()
        write-verbose 'Try w a ArrayList'
        $functionFiles.foreach{
            remove-variable invokeResult -errorAction ignore
            if($SuppressOutput)
            {
                $invokeResult = Invoke-ScriptAnalyzer -path $_.fullname @psScriptAnalyzerSplat
            }else{
                Invoke-ScriptAnalyzer -path $_.fullname @psScriptAnalyzerSplat|tee-object -variable invokeResult
            }
            $invokeResult.foreach{$capture.add($_)}
        }
        
        if($capture)
        {
            #Transform from GenList to array for better compatibility
            $capture = $capture.ToArray()
            $TopErrors = $capture.where{$_.Severity -eq 'Error'}|group-object -property 'RuleName' |Sort-Object -property 'Count' -Descending|Select-Object 'Name','Count' -first 5
            $TopWarnings = $capture.where{$_.Severity -eq 'Warning'}|group-object -property 'RuleName' |Sort-Object -property 'Count' -Descending|Select-Object 'Name','Count' -first 5
            $TopInfos = $capture.where{$_.Severity -eq 'Information'}|group-object -property 'RuleName' |Sort-Object -property 'Count' -Descending|Select-Object 'Name','Count' -first 5

            $ScriptNameGroup = $capture|group-object -property 'ScriptName'
            $ScriptNameWeighted = $ScriptNameGroup.ForEach{
                $fileFlagsGrouped = $_.Group|group-object -property 'Severity'|Select-Object 'Name','Count'
                $Errors = [int]($fileFlagsGrouped.Where{$_.Name -eq 'Error'}|Select-Object -property 'Count').count
                $Warnings = [int]($fileFlagsGrouped.Where{$_.Name -eq 'Warning'}|Select-Object -property 'Count').count
                $Informations = [int]($fileFlagsGrouped.where{$_.Name -eq 'Information'}|Select-Object -Property 'count').count
                [PSCustomObject]@{
                    ScriptName = $_.Name
                    Counter = "E:$Errors W:$Warnings I:$Informations"
                    Weight = [int]($($Weights.Error * $Errors) +$($Weights.Warning * $Warnings) +$($Weights.Information * $Informations))
                }
            }

            $ScriptNameWeightedSelect = if($ScriptNameWeighted){
                $ScriptNameWeighted|sort-object -property weight -Descending|Select-Object -first 5
            }else{$null}

            [PSCustomObject]@{
                Errors = $($capture.where{$_.severity -eq 'Error'}.count)
                Warnings = $($capture.where{$_.severity -eq 'Warning'}.count)
                Informational = $($capture.where{$_.severity -eq 'Information'}.count)
                TopErrors = $TopErrors
                TopWarnings = $TopWarnings
                TopInformational = $TopInfos
                TopFlaggedFiles = $ScriptNameWeightedSelect 
            }
        }
        
    }
    
}