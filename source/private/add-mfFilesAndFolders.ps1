function add-mfFilesAndFolders
{

    <#
        .SYNOPSIS
            Add the file and folder structure required by moduleForge
            
        .DESCRIPTION
            Create the folder structure as a scaffold,
            If a folder does not exist, create it.

            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                2024-07-22 - AA
                    - Refactored from Bartender
                    - Tried to make Operating Agnostic by using join-path
                    
    #>

    [CmdletBinding()]
    PARAM(
        #Root Path for module folder. Assume current working directory
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string]$moduleRoot = (Get-Item .).FullName #Use the fullname so that we don't have problems with PSDrive, symlinks, confusing bits etc
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $rootDirectories = @('documentation','source')
        $sourceDirectories = @('functions','enums','classes','filters','dscClasses','validationClasses','private','bin')
        $emptyFiles = @('.gitignore','.mfignore')
        
        
    }
    
    process{
        write-verbose 'Verifying base folder structure'
        
        

        $rootDirectories.foreach{
            $fullPath = Join-Path -path $moduleRoot -ChildPath $_
            if(test-path $fullPath)
            {
                write-verbose "Directory: $fullpath is OK"
            }else{
                write-warning "Directory: $fullpath not found. Will create"
                try{
                    $result = new-item -itemtype directory -Path $fullPath -ErrorAction Stop
                }catch{
                    throw "Unable to make new directory: $result. Please check permissions and conflicts"
                }
                
            }

            if($_ -eq 'source')
            {
                write-verbose 'Checking for subdirectories and files in source folder'
                $sourceDirectories.foreach{
                    $subdirectoryFullPath = join-path path $fullPath -childPath $_
                    if(test-path $subdirectoryFullPath)
                    {
                        write-verbose "Directory: $subdirectoryFullPath is OK"
                    }else{
                        write-warning "Directory: $subdirectoryFullPath not found. Will create"
                        try{
                            $result = new-item -itemtype directory -Path $subdirectoryFullPath -ErrorAction Stop
                        }catch{
                            throw "Unable to make new directory: $subdirectoryFullPath. Please check permissions and conflicts"
                        }
                        
                    }
                    $emptyFiles.ForEach{
                        $filePath = join-path $subdirectoryFullPath -childPath $_
                        if(test-path $filePath)
                        {
                            write-verbose "File: $filePath is OK"
                        }else{
                            write-warning "File: $filePath not found. Will create"
                            try{
                                $result = new-item -itemtype File -Path $filePath -ErrorAction Stop
                            }catch{
                                throw "Unable to make new directory: $filePath. Please check permissions and conflicts"
                            }
                            
                        }

                    }

                }

            }
        }
        
    }
    
}