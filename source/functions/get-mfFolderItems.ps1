function get-mfFolderItems
{
    <#
        .SYNOPSIS
            Get a list of files from a folder - whilst processing the .mfignore and .mforder files
            
        .DESCRIPTION
             Get the files out of a folder. Adds a bit of smarts to it such as:
             - Ignore anything in the .mfignore file
             - Filter out anything that isn't a PS1 file if, with a switch
             - Ignore files with .test.ps1 - These are assumed to be pester files
             - Ignore files with .skip.ps1 - These are assumed to be skippable

            
           

              Will always return a full path name
            
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
            
                2024-07-22 - AA
                    - Refactored from Bartender
                    
    #>

    [CmdletBinding(DefaultParameterSetName='Default')]
    PARAM(
        #Path to start in. Should be an FQDN
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName ='Default')]
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName ='Copy')]
        [string]$path,
        [parameter(ParameterSetName ='Default')]
        [parameter(ParameterSetName ='Copy')]
        [switch]$psScriptsOnly,
        [parameter(ParameterSetName ='Copy')]
        [string]$destination,
        [parameter(ParameterSetName ='Copy')]
        [switch]$copy

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"


        if($path[-1] -eq '\' -or $path[-1] -eq '/')
        {
            write-verbose 'Removing extra \ or / from path'
            $path = $path.Substring(0,$($path.length-1))
            write-verbose "New Path $path"
        }

        try{
            $folder = get-item $path -erroraction stop
            #Ensure we have the full path
            $folder = $folder.FullName

        }catch{
            throw "Unable to get folder at $path"
        }


        [System.Collections.Generic.List[string]]$excludeList = '.gitignore','.mfignore'


        if($destination)
        {
            if($destination[-1] -eq '\' -or $destination[-1] -eq '/')
            {
                write-verbose 'Removing extra \ or / from destination'
                $path = $path.Substring(0,$($destination.length-1))
                write-verbose "New destination $destination"
            }

            if(!(test-path $destination))
            {
                throw "Unable to resolve destination path: $destination"
            }


        }


        $fileListSelect = @(
            'Name'
            @{
                Name = 'Path'
                Expression = {$_.Fullname}
            }
            'RelativePath'
        )

        $fileListSelect2 = @(
            'Name'
            @{
                Name = 'Path'
                Expression = {$_.Fullname}
            }
            'RelativePath'
            'newPath'
            'newFolder'
        )


        
    }
    
    process{
        

        $mfIgnorePath = join-path -path $folder -childpath '.mfignore'
        if(test-path $mfIgnorePath)
        {
            write-verbose 'Getting ignore list from .mfignore'
            $content = (get-content $mfIgnorePath).where{$_.length -gt 1}
            $content.foreach{
                $excludeList.add($_.tolower())
            }
        }


        write-verbose "Full Exclude List: `n`n$($excludeList|format-list|Out-String)"
        

        


        write-verbose 'Getting Folder files'
        if($psScriptsOnly)
        {
            write-verbose 'Getting PS1 Files'
            $fileList = get-childitem -path $folder -recurse -filter *.ps1|where-object{$_.psIsContainer -eq $false -and $_.name.tolower() -notlike '*.test.ps1' -and $_.name.tolower() -notlike '*.skip.ps1' -and $_.Name.tolower() -notin $excludeList}
        }else{
            write-verbose 'Getting Folder files'
            $fileList = get-childitem -path $folder -recurse |where-object{$_.psIsContainer -eq $false -and $_.name.tolower() -notlike '*.test.ps1' -and $_.name.tolower() -notlike '*.skip.ps1' -and $_.Name.tolower() -notin $excludeList}
        }

        write-verbose 'Add custom member values'
        $fileList.foreach{
            $_|Add-Member -MemberType NoteProperty -Name 'RelativePath' -Value $($_.fullname.ToString()).replace("$($folder)$([IO.Path]::DirectorySeparatorChar)",".$([IO.Path]::DirectorySeparatorChar)")
            if($destination)
            {
                $_|add-member -MemberType NoteProperty -name 'newPath' -Value $($_.fullname.ToString()).replace($folder,$destination)
                $_|Add-Member -name 'newFolder' -memberType NoteProperty -value $($_.directory.ToString()).replace($folder,$destination)
            }
        }

        if($destination)
        {
            if($copy)
            {
                $fileList.foreach{
                    write-verbose "Copy file $($_.relativePath) to $($_.newFolder)"
                    if(!(test-path $_.newFolder))
                    {
                        write-verbose 'Destionation folder does not exist, attempt to create'
                        try{
                            $r = new-item -itemtype directory -path $_.newFolder -force -ErrorAction stop
                            write-verbose "Made new directory at: $($_.newFolder)"
                        }catch{
                            throw "Error making new directory at: $($_.newFolder)"
                        }
                    }
                    try{
                        write-verbose "Copying $($_.relativePath) to $($_.newPath)"
                        $r = copy-item -path ($_.fullname) -destination ($_.newPath) -force
                        write-verbose "Copied $($_.relativePath) to $($_.newFolder)"
                    }catch{
                        throw "Error with Copy: $($_.relativePath) to $($_.newFolder)"
                    }
                    
                }
            }
            $fileList|Select-Object $fileListSelect2
        }else{
            $fileList|Select-Object $fileListSelect
        }
        
    }
    
}