function get-mfFolderItemDetails
{

    <#
        .SYNOPSIS
            This function analyses a PS1 file, returning its content, any functions, classes and dependencies, as well as a relative location
            
        .DESCRIPTION
            The `get-mfFolderItemDetails` function takes a path to source folder
            
            It creates a job that generates a details about all found PS1 files,
            including: The content of PS1 files, the names of any functions, any dependencies

            This function uses a job to import all the ps1 items so that all types can be reflected correctly without having to load the module
            
        ------------
        .EXAMPLE
            get-mfFolderItemDetails .\source
            
            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                2024-07-27 AA
                    - First Refactor
                2024-08-12 AA
                    - Improve the relativePath code
                    - Add a folderGroup passthrough
                    - Need to figure out a better way for importing the module
                    
    #>

    [CmdletBinding()]
    PARAM(
        #Path to source folder.
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string]$path,
        #Path to ModuleForge, to know how to load it in the scriptblock
        [Parameter()]
        [String]$modulePath
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        if(!$modulePath)
        {
            $base = 'C:\Users\AdrianAndersson\Documents\git\ModuleForge\ModuleForge\'
            $ci = get-childItem $base
            $vers = $ci.foreach{[version]::new($_.name)}
            $latest = $vers|Sort-Object -Descending|Select-Object -First 1
            $modulePath = "$base\$latest\ModuleForge.psd1"
            write-verbose "Set ModuleForge to $modulePath"
        }   
        
    }
    
    process{
        write-verbose 'Creating Scriptblock'
        [scriptblock]$sblock = {
            param($path,$modulePath)

            [array]$folders = @('enums','validationClasses','classes','dscClasses','functions','private','filters')
            import-module $modulePath

            #Suspect that, instead of relying on this module import, we instead already provide the items
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
                $folderPath = join-path -path $_.folder -childpath $_.RelativePath.Substring(1)
                $relPath = join-path -path $relPathBase -childpath $folderPath
                if($_.path -like $privateMatch -or $_.path -like $functionMatch -or $_.folder -eq $functionMatch -or $_.folder -eq $privateMatch)
                {   
                    write-verbose "$($_.Path) matched on type: Function"
                    Get-mfScriptDetails -Path $_.Path -RelativePath $relPath -type Function -folderGroup $_.folder
                }else{
                    write-verbose "$($_.Path) matched on type: Class"
                    Get-mfScriptDetails -Path $_.Path -RelativePath $relPath -type Class -folderGroup $_.folder
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
        $global:dbgScriptBlock = $sblock

        write-verbose 'Starting Job'
        $job = Start-Job -ScriptBlock $sblock -ArgumentList @($path, $modulePath)
        $job|Wait-Job|out-null
        write-verbose 'Retrieving output and returning result'
        $output = Receive-Job -Job $job

        remove-job -job $job
        return $output
        
    }
    
}

