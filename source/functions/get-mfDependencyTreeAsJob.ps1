function get-mfDependencyTreeAsJob
{

    <#
        .SYNOPSIS
            This function generates a report of dependency files for a ps1 script.
            
        .DESCRIPTION
            The `get-mfDependencyTreeAsJob` function takes a path to a script 
            file in the moduleForce source folder. 
            
            It creates a job that generates a dependency report for any downstream functions or types
            The function uses a job to import all the ps1 items so that all types can be reflected correctly
            
            Then it analyses the file supplied at path to see what downstream types and functions may be required 
            for operation.

            Good for figuring out what might be needed for writing Pester tests
            
        ------------
        .EXAMPLE
            get-mfDependencyTreeAsJob .\source\functions\example.ps1
            
            #### DESCRIPTION
            Run a job that imports all the related items.
            Use reflection to see what functions and types are used in example.ps1
            If the functions and types are also in the source folder, return them as a dependency
            
            
            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                2024-07-27 AA
                    - First Refactor
                    
    #>

    [CmdletBinding()]
    PARAM(
        #PARAM DESCRIPTION
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string]$path,
        #Path to ModuleForge, to know how to load it in the scriptblock
        [String]$modulePath = 'C:\Users\AdrianAndersson\Documents\git\ModuleForge\ModuleForge\0.0.29\ModuleForge.psd1'
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        
    }
    
    process{
        [scriptblock]$sblock = {
            param($path,$modulePath)

            [array]$folders = @('enums','validationClasses','classes','dscClasses','functions','private','filters')
            import-module $modulePath

            write-verbose 'Imported Module'
            $folderItems = $folders.ForEach{
                $folderPath = Join-Path $path -ChildPath $_
                get-mfFolderItems -path $folderPath
            }

            $privateMatch = "*$([IO.Path]::DirectorySeparatorChar)private$([IO.Path]::DirectorySeparatorChar)*"
            $functionMatch = "*$([IO.Path]::DirectorySeparatorChar)functions$([IO.Path]::DirectorySeparatorChar)*"

            $folderItems.ForEach{
                
                if($_.path -notlike $privateMatch -and $_.path -notlike $functionMatch)
                {
                    #Need to dot source the files to make sure all the types are loaded
                    #Only needs to happen for non-function files
                    . $_.Path
                }
            }

            $thisPath = (Get-Item $path)
            $relPathBase = ".$([IO.Path]::DirectorySeparatorChar)$($thisPath.name)"
            
            $itemDetails = $folderItems.ForEach{
                $relPath = $relPathBase + $_.RelativePath.Substring(1)
                if($_.path -like $privateMatch -or $_.path -like $functionMatch)
                {   
                    write-verbose "$($_.Path) matched on type: Function"
                    Get-mfScriptDetails -Path $_.Path -RelativePath $relPath -type Function
                }else{
                    write-verbose "$($_.Path) matched on type: Class"
                    Get-mfScriptDetails -Path $_.Path -RelativePath $relPath -type Class
                }
                
            }
    
            write-verbose 'Return items in Context'
            $inContextList =New-Object System.Collections.Generic.List[string]
            $filenameReference = @{}
            $filenameRelativeReference = @{}
    
            $itemDetails.foreach{
                $fullPath = $_.path
                $relPath = $_.relativePath
                write-verbose "Getting details for $($_.name)"
                $_.FunctionDetails.Foreach{
                    $inContextList.add($_.functionName)
                    $filenameReference.add($_.functionName,$fullPath)
                    $filenameRelativeReference.Add($_.functionName,$relPath)
                }
                $_.ClassDetails.Foreach{
                    $inContextList.add($_.className)
                    $filenameReference.add($_.className,$fullPath)
                    $filenameRelativeReference.Add($_.className,$relPath)
                }
            }

            $checklist = $filenameReference.GetEnumerator().name

            foreach($item in $itemDetails)
            {
                #Clumsy way of doing this list, could just do array with +
                #Feel like this is slightly neater and easier to turn bits off or expand
                write-verbose "Checking dependencies for file: $($item.name)"
                $compareList =New-Object System.Collections.Generic.List[string]
                $item.ClassDetails.methods.name.foreach{$compareList.add($_)}
                $item.FunctionDetails.cmdlets.name.foreach{$compareList.add($_)}
                $item.FunctionDetails.types.Name.foreach{$compareList.add($_)}
                $item.FunctionDetails.validators.name.foreach{$compareList.add($_)}
                $item.FunctionDetails.parameterTypes.name.foreach{$compareList.add($_)}


                $dependenciesList =New-Object System.Collections.Generic.List[object]

                
                
                foreach($c in $compareList)
                {
                    write-verbose "Checking dependency of $c"
                    if($c -in $checklist)
                    {
                        write-verbose "$c found in checklist"
                        if($item.path -ne $filenameReference["$c"])
                        {
                            write-verbose "$c found in checklist"

                            $dependenciesList.add([psCustomObject]@{Reference=$c;ReferenceFile=$filenameRelativeReference["$c"]})
                            
                        }else{
                            write-verbose "$c found in checklist - but in same file, ignoring"
                        }
                        
                    }
                    
                    
                    

                }
                
                #Add dependencies as an item
                $item|add-member -MemberType NoteProperty -Name 'Dependencies' -Value $dependenciesList
                $item


            }
            

        }

        $job = Start-Job -ScriptBlock $sblock -ArgumentList $path, $modulePath
        $job|Wait-Job|out-null
        $output = Receive-Job -Job $job

        remove-job -job $job
        return $output
        
    }
    
}

