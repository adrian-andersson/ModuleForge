function get-mfDependencyTree
{

    <#
        .SYNOPSIS
            Check the source file for dependency items. Try and make a manifest of dependencies
            
        .DESCRIPTION
            When testing out how best to do Pester Tests with dependencies (Such as private functions, enums etc), I discovered that getting good code coverage was a challenge.
            Considered doing the tests with the ModuleScope pester argument, but that means you don't get code coverage.
            Tried to do it with Using but that was messy and inconsistent.
            Discovered that the best way is to dotSource the files you might need or mock your functions is the best option.

            If you are going to dot source the files, you need to find the dependencies.
            This function comes from that requirement.

            In testing, I have already superceded it with the job one. I think this version should probably go
            
        ------------
        .EXAMPLE
            get-mfDependencyTree
            
            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                2024-07-27 - AA
                    - First Attempt
                    
    #>

    [CmdletBinding()]
    PARAM(
        #Path to start in
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$path = $($(get-item .).fullname |join-path -ChildPath 'source')
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        
    }
    
    process{

        write-verbose "Checking: $path"
        if(!(test-path $path))
        {
            throw "Unable to find path: $path"
        }
        
        $folderItems = get-mfFolderItems -path $path -psScriptsOnly

        $privateMatch = "*$([IO.Path]::DirectorySeparatorChar)private$([IO.Path]::DirectorySeparatorChar)*"
        $functionMatch = "*$([IO.Path]::DirectorySeparatorChar)functions$([IO.Path]::DirectorySeparatorChar)*"

        write-verbose "PrivateMatchString : $privateMatch"
        write-verbose "FunctionMatchString : $functionMatch"

        $itemDetails = $folderItems.ForEach{
            if($_.RelativePath -like $privateMatch -or $_.RelativePath -like $functionMatch)
            {   
                write-verbose "$($_.Path) matched on type: Function"
                Get-mfScriptDetails -Path $_.Path -RelativePath $_.RelativePath -type Function
            }else{
                write-verbose "$($_.Path) matched on type: Class"
                Get-mfScriptDetails -Path $_.Path -RelativePath $_.RelativePath -type Class
            }
            
        }

        write-verbose 'Return items in Context'
        $inContextList =New-Object System.Collections.Generic.List[string]
        $filenameReference = @{}

        $itemDetails.foreach{
            $relPath = $_.relativePath
            write-verbose "Getting details for $($_.name)"
            $_.FunctionDetails.Foreach{
                $inContextList.add($_.functionName)
                $filenameReference.add($_.functionName,$relPath)
            }
            $_.ClassDetails.Foreach{
                $inContextList.add($_.className)
                $filenameReference.add($_.className,$relPath)
            }
        }

        $global:dbgItemDetails = $itemDetails
        
        #$inContextList
        $global:dbgfilenameReference = $filenameReference
        $checklist = $filenameReference.GetEnumerator().name
        #write-verbose "Checklist: $checklist"
        #foreach($item in $dbgitemDetails){$item.name;$item.ClassDetails.methods.name + $item.FunctionDetails.cmdlets.name + $item.FunctionDetails.types.Name + $item.FunctionDetails.validators.name}
        foreach($item in $itemDetails)
        {
            write-verbose "Checking dependencies for file: $($item.name)"
            $compareList =New-Object System.Collections.Generic.List[string]
            $item.ClassDetails.methods.name.foreach{$compareList.add($_)}
            $item.FunctionDetails.cmdlets.name.foreach{$compareList.add($_)}
            $item.FunctionDetails.types.Name.foreach{$compareList.add($_)}
            $item.FunctionDetails.validators.name.foreach{$compareList.add($_)}
            $global:dbgCompareList = $compareList
            #$compareList = $item.ClassDetails.methods.name + $item.FunctionDetails.cmdlets.name + $item.FunctionDetails.types.Name + $item.FunctionDetails.validators.name
            foreach($c in $compareList)
            {
                write-verbose "Checking dependency of $c"
                if($c -in $checklist)
                {
                    write-verbose "$c found in checklist"
                    if($item.relativePath -ne $filenameReference["$c"])
                    {
                        write-verbose "$c found in checklist"
                        write-warning "File:$($item.Name) depends on $($filenameReference["$c"]) for function or type $c"
                    }else{
                        write-verbose "$c found in checklist - but in same file, ignoring"
                    }
                    
                }
            }

        }

        
    }
    
}