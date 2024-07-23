function get-mfScriptText
{

    <#
        .SYNOPSIS
            Get the text from a PS1 file, return it
            
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
            
            
            Changelog:
            
                yyyy-mm-dd - AA
                    - Changed x for y
                    
    #>

    [CmdletBinding()]
    PARAM(
        #PARAM DESCRIPTION
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string[]]$path,
        [Parameter()]
        [ValidateSet('function', 'dscClass', 'other')]
        [string]$scriptType = 'function',
        [Parameter()]
        [switch]$force
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $outputObject = @{
            output = [string]''
            functionResources = [System.Collections.Generic.List[string]](New-Object System.Collections.Generic.List[string])
            dscResources =[System.Collections.Generic.List[string]](New-Object System.Collections.Generic.List[string])
        }
        
    }
    
    process{
        foreach($item in $path)
        {
            write-verbose "Processing file: $item"
            $itemDetails = get-item $item
            if(!$itemDetails)
            {
                write-warning "Unable to get details for file: $item. Skipping"
                continue #Stop processing, go to next item
            }
            if($itemDetails.extension -ne '.ps1')
            {
                if(!$force)
                {
                    write-warning "File: $item is not a PS1 file. Skipping. Use -Force switch to ignore these warnings"
                    continue #Stop processing, go to next item
                }else{
                    write-warning "File: $item is not a PS1 file. -Force switch used. Proceeding with Warning"
                }
            }

            $content = get-content $itemDetails.FullName
            write-verbose 'Retrieved Content, Analyising'
            
            switch ($scriptType) {
                'dscClass' {
                    write-verbose 'Analysing as a DSC Class'
                    $lineNo = 1
                    $content.foreach{
                        if($_ -like 'class *')
                        {
                            write-verbose "Found class in: $($item) Line:$lineNo"
                            $className = ($_ -split 'class ')[1]
                            if($className -like '*{*')
                            {
                                #Remove the script-block if it was appended to the function line
                                $className = $($className -split '{')[0]
                            }
                            $className = $className.trim()
                            write-verbose "Adding $className to exportable dscResources"
                            $outputObject.dscResources.Add($className)

                        }

                        $lineNo++
                    }
                }
                'function' {
                    write-verbose 'Analysing as a Function file'
                    $lineNo = 1
                    $content.foreach{
                        if($_ -like 'function *')
                        {
                            write-verbose "Found Function in: $($item) Line:$lineNo"
                            $functionName = ($_ -split 'function ')[1]
                            #write-verbose "fnameBase: $functionName"
                            if($functionName -like '*{*')
                            {
                                #Remove the script-block if it was appended to the function line
                                $functionName = $($functionName -split '{')[0]
                            }
                            if($functionName -like '*(*')
                            {
                                #If we are dealing with a non-advanced powershell function, handle that as well
                                $functionName = $($functionName -split '(')[0]
                            }
                            $functionName = $functionName.trim()
                            write-verbose "Adding $functionName to exportable function resources"
                            $outputObject.functionResources.Add($functionName)
                        }

                        $lineNo++
                    }
                }
                default {
                    #write-verbose 'Analysing as Other file'
                }
                
            }
            write-verbose "Add content of $item"
            $outputObject.output = "$($outputObject.output)`n`n#FromFile: $($itemDetails.name)`n`n`n$($content|out-string)"
        }

        [PSCustomObject]$outputObject
        
    }
    
}