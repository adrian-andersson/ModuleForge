function get-mfScriptFunctionNames
{

    <#
        .SYNOPSIS
            Retrieves the names of powershell functions from PowerShell script files.
            
        .DESCRIPTION
            Basically, a get-command type function for scripts you haven't dotSourced or imported yet.
            
        ------------
        .EXAMPLE
            get-mfScriptFunctionNames example.ps1
            
            #### DESCRIPTION
            Get the names of any functions in the example.ps1 file           
            
            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                2024-07-22 - AA
                    - Recreated from bartender
                    - Added more verbosity
                    - Simplified
                    - Added extension checks
                2024-08-12
                    - Suspect deprecated, leave for compatibility or revisit
                    
    #>

    [CmdletBinding()]
    PARAM(
        #PS1 / PowerShell Script file to check
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string]$path,
        #Ignore extension name
        [Parameter()]
        [switch]$ignoreFileExtension
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $powershellExtensions = @(
            '.ps1'
            '.psm1'
        )
        
    }
    
    process{
        $item = get-item $path
        
        if(test-path $item)
        {
            write-verbose "Found item at $path"

            if($item.extension -notin $powershellExtensions)
            {
                if(!$ignoreFileExtension)
                {
                    Throw 'File extension is not a PowerShell script filefile'
                }else{
                    write-warning 'File extension is not a PowerShell file. Ignore switch supplied so proceeding with warning'
                }
            }
            write-verbose 'Reading contents and finding function names'
            $contents = get-contents $item
            $contents.foreach{
                if($_ -like 'function *')
                {
                    write-verbose 'Function Found'
                    $($_ -split 'function ')[0]
                }
            }
        }else{
            throw "Error finding file: $path"
        }        
    }
}