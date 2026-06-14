function Add-MFFilesAndFolders
{

    <#
        .SYNOPSIS
            Add the file and folder structure required by moduleForge
            
        .DESCRIPTION
            Creates the ModuleForge source folder structure (source\functions, enums, classes,
            validationClasses, private, bin, resource) and seeds .gitignore and .mfignore placeholder
            files in each source subfolder. Existing folders and files are left untouched. Finally calls
            Add-MFProjectScripts to copy the script templates into the project.


        .NOTES
            Author: Adrian Andersson
            
    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseSingularNouns", "", Justification = "Plural 'FilesAndFolders' reflects that the function creates multiple files and folders.")]
    PARAM(
        #Root path for the new module. Defaults to the current working directory
        [Parameter(ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string]$ModuleRoot = (Get-Item .).FullName #Use the fullname so that we don't have problems with PSDrive, symlinks, confusing bits etc
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $rootDirectories = @('source')
        $sourceDirectories = @('functions','enums','classes','validationClasses','private','bin','resource')
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
                write-information "Directory: $fullpath not found. Will create" -tags 'FileCreation'
                try{
                    $result = new-item -itemtype directory -Path $fullPath -ErrorAction Stop
                }catch{
                    throw "Unable to make new directory: $result. Please check permissions and conflicts"
                }
            }

           

            if($_ -eq 'source')
            {
                write-verbose 'Source Folder: Checking for subdirectories and files in source folder'
                $sourceDirectories.foreach{
                    $subdirectoryFullPath = join-path -path $fullPath -childPath $_
                    
                    if(test-path $subdirectoryFullPath)
                    {
                        write-verbose "Directory: $subdirectoryFullPath is OK"
                    }else{
                        write-information "Directory: $subdirectoryFullPath not found. Will create" -tags 'FileCreation'
                        try{
                            $null = new-item -itemtype directory -Path $subdirectoryFullPath -ErrorAction Stop
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
                            write-information "File: $filePath not found. Will create" -tags 'FileCreation'
                            try{
                                $null = new-item -itemtype File -Path $filePath -ErrorAction Stop
                            }catch{
                                throw "Unable to make new directory: $filePath. Please check permissions and conflicts"
                            }
                            
                        }

                    }

                }

            }
        }

        Add-MFProjectScripts -ModulePath $moduleRoot -WarningAction SilentlyContinue

    }

}