function Get-MFFolderItems
{
    <#
        .SYNOPSIS
            Retrieves a filtered list of files from a specified folder, processing '.mfignore' and '.mforder' rules.
            
        .DESCRIPTION
            The 'Get-MFFolderItems' function scans a folder and applies filtering rules to return a curated list of files. It offers additional filtering logic, such as:
            - Ignoring entries specified in `.mfignore`.
            - Filtering out non-PS1 files using a switch (`-psScriptsOnly`).
            - Excluding test-related files (`*.test.ps1`, `*.tests.ps1`, `*.skip.ps1`).
            - Handling optional file copying (`-destination` and `-copy` parameters).

            The function ensures all returned paths are fully qualified.
            This function is primarily used to assist the get-mfFolderItemDetails as well as build-mfProject.
            The -copy switch is added to cleanly copy resources and binaries with build-mfProject
            
        .EXAMPLE
            Get-MFFolderItems -Path '.\source\functions' -PSScriptsOnly
            
            #### DESCRIPTION
            Scans `.\source\functions`, retrieves only `.ps1` files, and excludes files matching `.mfignore` rules.

        .EXAMPLE
            Get-MFFolderItems -Path '.\source\functions' -Destination '.\build\functions' -Copy

            #### DESCRIPTION
            Scans `.\source\functions`, retrieves filtered files, and copies them to `.\build\functions`.

        .INPUTS
            [String] - Accepts a folder path via parameter or pipeline (`ValueFromPipelineByPropertyName`).

        OUTPUTS
            [Object[]] - Returns an array of objects containing:
                - **Name** (`[String]`) - Name of the file.
                - **Path** (`[String]`) - Full file path.
                - **RelativePath** (`[String]`) - Path relative to the source folder.
                - **Folder** (`[String]`) - Name of the source folder.
                - **(Optional) newPath** (`[String]`) - Destination path if copying.
                - **(Optional) newFolder** (`[String]`) - Destination folder name if copying.
            
        .NOTES
            Author: Adrian Andersson
                    
    #>

    [CmdletBinding(DefaultParameterSetName='Default')]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseSingularNouns", "", Justification = "Plural 'Items' reflects nature of function and improves clarity.")]
    PARAM(
        #Path to get items from
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ValueFromPipeline,ParameterSetName ='Default')]
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ValueFromPipeline,ParameterSetName ='Copy')]
        [string]$Path,
        #Flag to copy scripts only
        [parameter(ParameterSetName ='Default')]
        [parameter(ParameterSetName ='Copy')]
        [switch]$PSScriptsOnly,
        #Flag to copy scripts only
        [parameter(ParameterSetName ='Copy')]
        [string]$Destination,
        #Flag to actually copy files and not just output
        [parameter(ParameterSetName ='Copy')]
        [switch]$Copy

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        write-verbose "ParameterSet: $($PSCmdlet.ParameterSetName)"

        $fileListSelect = @(
            'Name'
            @{
                Name = 'Path'
                Expression = {$_.Fullname}
            }
            'RelativePath'
            @{
                Name = 'Folder'
                Expression = {$folderShortName}
            }
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
            @{
                Name = 'Folder'
                Expression = {$folderShortName}
            }
        )


        
    }
    
    process{

        #Check the Parameters and do some lite parsing
        write-verbose "Path set to: $Path"
        
        if($Path[-1] -eq '\' -or $Path[-1] -eq '/')
        {
            write-verbose 'Removing extra \ or / from path'
            $Path = $Path.Substring(0,$($Path.length-1))
            write-verbose "New Path $Path"
        }

        try{
            $folderItem = get-item $Path -erroraction stop
            #Ensure we have the full path

            $folder = $folderItem.FullName
            write-verbose "Folder Fullname: $folder"
            $folderShortName = $folderItem.Name
            write-verbose "Folder Shortname: $folderShortName"

        }catch{
            throw "Unable to get folder at $Path"
        }


        #Include the older bartender bits so we have backwards compatibility
        [System.Collections.Generic.List[string]]$excludeList = '.gitignore','.mfignore','.btorderEnd','.btorderStart','.btignore'

        if($Destination)
        {
            if($Destination[-1] -eq '\' -or $Destination[-1] -eq '/')
            {
                write-verbose 'Removing extra \ or / from destination'
                $Path = $Path.Substring(0,$($Destination.length-1))
                write-verbose "New destination $Destination"
            }

            if(!(test-path $Destination))
            {
                throw "Unable to resolve destination path: $Destination"
            }


        }

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

        #Actual processing
        
        write-verbose 'Getting Folder files'
        if($PSScriptsOnly)
        {
            write-verbose 'Getting PS1 Files'
            $fileList = get-childitem -path $folder -recurse -filter *.ps1|where-object{$_.psIsContainer -eq $false -and $_.name.tolower() -notlike '*.test.ps1' -and $_.name.tolower() -notlike '*.tests.ps1' -and $_.name.tolower() -notlike '*.skip.ps1' -and $_.Name.tolower() -notin $excludeList}
        }else{
            write-verbose 'Getting Folder files'
            $fileList = get-childitem -path $folder -recurse |where-object{$_.psIsContainer -eq $false -and $_.name.tolower() -notlike '*.test.ps1' -and $_.name.tolower() -notlike '*.tests.ps1' -and $_.name.tolower() -notlike '*.skip.ps1' -and $_.Name.tolower() -notin $excludeList}
        }

        write-verbose 'Add custom member values'
        $fileList.foreach{
            $_|Add-Member -MemberType NoteProperty -Name 'RelativePath' -Value $($_.fullname.ToString()).replace("$($folder)$([IO.Path]::DirectorySeparatorChar)",".$([IO.Path]::DirectorySeparatorChar)")
            if($Destination)
            {
                $_|add-member -MemberType NoteProperty -name 'newPath' -Value $($_.fullname.ToString()).replace($folder,$Destination)
                $_|Add-Member -name 'newFolder' -memberType NoteProperty -value $($_.directory.ToString()).replace($folder,$Destination)
            }
        }

        if($Destination)
        {
            if($Copy)
            {
                $fileList.foreach{
                    write-verbose "Copy file $($_.relativePath) to $($_.newFolder)"
                    if(!(test-path $_.newFolder))
                    {
                        write-verbose 'Destination folder does not exist, attempt to create'
                        try{
                            $null = new-item -itemtype directory -path $_.newFolder -force -ErrorAction stop
                            write-verbose "Made new directory at: $($_.newFolder)"
                        }catch{
                            throw "Error making new directory at: $($_.newFolder)"
                        }
                    }
                    try{
                        write-verbose "Copying $($_.relativePath) to $($_.newPath)"
                        $null = copy-item -path ($_.fullname) -destination ($_.newPath) -force
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