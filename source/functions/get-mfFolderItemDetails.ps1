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
        [string]$path
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }
    
    process{

        write-verbose 'Creating Scriptblock'
        [scriptblock]$sblock = {
            param($path,$folderItems)
 
            function Get-mfScriptDetails {
                param(
                    [Parameter(Mandatory)]
                    [string]$Path,
                    [Parameter()]
                    [string]$RelativePath,
                    [ValidateSet('Class','Function','All')]
                    [Parameter()]
                    [string]$type = 'All',
                    [Parameter()]
                    [string]$folderGroup
                )
                begin{
                    write-verbose 'Checking Item'
                    if($path[-1] -eq '\' -or $path[-1] -eq '/')
                    {
                        write-verbose 'Removing extra \ or / from path'
                        $path = $path.Substring(0,$($path.length-1))
                        write-verbose "New Path $path"
                    }
                    $file = get-item $Path
                    if(!$file)
                    {
                        throw "File not found at: $path"
                    }
                }
                process{
                    $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
                    #$Functions = $AST.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

                    #The above was the original way to do this
                    #However it was so efficient it also returned subfunctions AND functions in scriptblocks
                    #Since we don't want to do that, we cycle through and look at the start and end line numbers and only return top-level functions
                    $AllFunctions = $AST.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
                    $TopLevelFunctions = New-Object System.Collections.Generic.List[Object]
                    foreach($func in $allFunctions){
                        $isNested = $false
                        foreach($parentFunc in $allFunctions)
                        {
                            if($func -ne $parentFunc -and $func.Extent.StartLineNumber -ge $parentFunc.Extent.StartLineNumber -and $func.Extent.EndLineNumber -le $parentFunc.Extent.EndLineNumber)
                            {
                                $isNested = $true
                                break
                            }
                        }
                        if(-not $isNested) {
                            $TopLevelFunctions.add($func)
                        }
                    }
                    
                    $Classes = $AST.FindAll({ $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] }, $true)
                    if($type -eq 'All' -or $type -eq 'Function')
                    {
                        $functionDetails = foreach ($Function in $TopLevelFunctions) {
                            $cmdletDependenciesList = New-Object System.Collections.Generic.List[string]
                            $typeDependenciesList = New-Object System.Collections.Generic.List[string]
                            $paramTypeDependenciesList = New-Object System.Collections.Generic.List[string]
                            $validatorTypeDependenciesList = New-Object System.Collections.Generic.List[string]
                            $FunctionName = $Function.Name
                            $Cmdlets = $Function.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)
                            foreach($c in $Cmdlets)
                            {
                                $cmdletDependenciesList.add($c.GetCommandName())
                            }
                            $TypeExpressions = $Function.FindAll({ $args[0] -is [System.Management.Automation.Language.TypeExpressionAst] }, $true)
                            $TypeExpressions.TypeName.FullName.foreach{
                                $tname = $_
                                [string]$tnameReplace = $($tname.Replace('[','')).replace(']','')
                                $typeDependenciesList.add($tnameReplace)
                            }
                            $Parameters = $Function.Body.ParamBlock.Parameters
                            $Parameters.StaticType.Name.foreach{$paramTypeDependenciesList.add($_)}
                            $attributes = $Parameters.Attributes
                            foreach($att in $attributes)
                            {
                                $refType = $att.TypeName.GetReflectionType()
                                if($refType -and ($refType.IsSubclassOf([System.Management.Automation.ValidateArgumentsAttribute]) -or [System.Management.Automation.ValidateArgumentsAttribute].IsAssignableFrom($refType))) {
                                    [string]$tname = $Att.TypeName.FullName
                                    [string]$tname = $($tname.Replace('[','')).replace(']','')
                                    $validatorTypeDependenciesList.Add($tname)
                                }
                            }
                    
                            [psCustomObject]@{
                                functionName = $FunctionName
                                cmdLets = $cmdletDependenciesList|group-object|Select-Object Name,Count
                                types = $typeDependenciesList|group-object|Select-Object Name,Count
                                parameterTypes = $paramTypeDependenciesList|group-object|Select-Object name,count
                                Validators = $validatorTypeDependenciesList|Group-Object|Select-Object name,count
                            }
                        }
                    }
                    if($type -eq 'all' -or $type -eq 'Class')
                    {
                        $classDetails = foreach ($Class in $Classes) {
                            $className = $Class.Name
                            $classMethodsList = New-Object System.Collections.Generic.List[string]
                            $classPropertiesList = New-Object System.Collections.Generic.List[string]
                            $Methods = $Class.Members | Where-Object { $_ -is [System.Management.Automation.Language.FunctionMemberAst] }
                            foreach($m in $Methods)
                            {
                                $classMethodsList.add($m.Name)
                            }
                            $Properties = $Class.Members | Where-Object { $_ -is [System.Management.Automation.Language.PropertyMemberAst] }
                            foreach($p in $Properties)
                            {
                                $classPropertiesList.add($p.Name)
                            }
                            [psCustomObject]@{
                                className = $className
                                methods = $classMethodsList|group-object|Select-Object Name,Count
                                properties = $classPropertiesList|group-object|Select-Object Name,Count
                            }
                        }
                    }
                    $objectHash = @{
                        Name = $file.Name
                        Path = $file.FullName
                        FileSize = "$([math]::round($file.length / 1kb,2)) kb"
                        FunctionDetails = $functionDetails
                        ClassDetails = $classDetails
                        Content = $AST.ToString()
                    }
                    if($RelativePath)
                    {
                        $objectHash.relativePath = $RelativePath
                    }
                    if($folderGroup)
                    {
                        $objectHash.group = $folderGroup
                    }
                    [psCustomObject]$objectHash
                }
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

        write-verbose 'Getting Folder Items'

        [array]$folders = @('enums','validationClasses','classes','dscClasses','functions','private','filters')
        $folderItems = $folders.ForEach{
            $folderPath = Join-Path $path -ChildPath $_
            get-mfFolderItems -path $folderPath
        }

        write-verbose 'Starting Job'
        $job = Start-Job -ScriptBlock $sblock -ArgumentList @($path, $folderItems)
        $job|Wait-Job|out-null
        write-verbose 'Retrieving output and returning result'
        $output = Receive-Job -Job $job

        remove-job -job $job
        return $output   
    }   
}