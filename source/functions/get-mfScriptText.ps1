function get-mfScriptText
{

    <#
        .SYNOPSIS
            Identify functions and classes in a PS1 file, return the name of the function along with the actual content of the file.
            
        .DESCRIPTION
            Used to pull the names of functions and classes from a PS1 file, and return them in an object along with the content itself.
            This will provide a way to get the names of functions and resources as well as copying the content cleanly into a module file.
            It works best when you keep to single types (Classes or Functions) in a file.
            By returning the function and dscResource names, we can also compile what we need to export in a module manifest
            
        ------------
        .EXAMPLE
            get-mfScriptText c:\myFile.ps1 -scriptType function
            
            
            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                2024-07-28 - AA
                    - Refactored from Bartender

                2024-08-02 - AA
                    - May be superceded by the get-mfDependencyTreeAsJob
                    
    #>

    [CmdletBinding()]
    PARAM(
        #Path to the file
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string[]]$path,
        #The type of function to return. Use Function to return function-names, use dscClasses for dscResources to export. Use other for private function, classes etc you do not want to export etc
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