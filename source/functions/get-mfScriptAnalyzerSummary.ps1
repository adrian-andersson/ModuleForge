function get-mfScriptAnalyzerSummary
{

    <#
        .SYNOPSIS
            Simple description
            
        .DESCRIPTION
            Detailed Description
            
        ------------
        .EXAMPLE
            verb-noun param1
            
            #### DESCRIPTION
            Line by line of what this example will do
            
            
            #### OUTPUT
            Copy of the output of this line
            
            
            
        .NOTES
            Author: Adrian Andersson
            
    #>

    [CmdletBinding()]
    PARAM(
        #PARAM DESCRIPTION
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("p1")]
        [string]$sourcePath = $(join-path $(join-path '.' -childPath 'source') -childPath functions),
        [parameter()]
        [string[]]$severity = @('Error','Warning','Information'),
        [Parameter(dontshow)]
        [hashtable]$weights = @{
            Error = 50
            Warning = 15
            Information = 1
        },
        [Parameter()]
        [switch]$suppressOutput,
        [Parameter()]
        [string[]]$excludeRules = @(
            'PSAvoidTrailingWhitespace' #Noisy rule. Preference script readability over strict whitespace adherance
        )
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $psScriptAnalyzerSplat = @{
            severity = $severity
            ExcludeRule = $excludeRules
        }

        if(!(get-module -ListAvailable 'PSScriptAnalyzer')){
            throw 'PSScriptAnalyzer module must be present on this system for this function to work'
        }
        
    }
    
    process{
        $functionFiles = Get-ChildItem -Recurse -Include '*.ps1' -Exclude '*.Tests.ps1' -Path $sourcePath 
        #Use a GenList to avoid iterative arrays
        $capture = [System.Collections.Generic.List[object]]::new()
        write-verbose 'Try w a ArrayList'
        $functionFiles.foreach{
            remove-variable invokeResult -errorAction ignore
            if($suppressOutput)
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
                    Weight = [int]($($weights.Error * $Errors) +$($weights.Warning * $Warnings) +$($weights.Information * $Informations))
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