function Get-MFFolderItemDetails
{

    <#
        .SYNOPSIS
            This function analyses a PS1 file, returning its content, any functions, classes and dependencies, as well as a relative location

        .DESCRIPTION
            The `Get-MFFolderItemDetails` function takes a path to source folder

            It creates a job that generates a details about all found PS1 files,
            including: The content of PS1 files, the names of any functions, the names of any classes, and any inter-related dependencies

            This function uses a job to import all the ps1 items so that all types can be reflected correctly without having to load the module,
            So it works without having to build the manifest etc

            This function is primary used to build dependency trees and during build to get file contents

        ------------
        .EXAMPLE
            Get-MFFolderItemDetails .\source

        .INPUTS
            [STRING] - Path to Source Folder is accepted as Pipeline Input or direct assignment

        .OUTPUTS
            [Object[]] - Returns an array of objects with detailed file metadata, including:
                - **Name** (`[String]`) - Name of the file.
                - **Path** (`[String]`) - Full file path.
                - **FileSize** (`[Int]`) - File size in kilobytes.
                - **FunctionDetails** (`[Object[]]`) - Details of functions within the file.
                - **ClassDetails** (`[Object[]]`) - Details of classes within the file.
                - **Contents** (`[String]`) - Entire script content.
                - **Group** (`[String]`) - Subfolder grouping.
                - **Dependencies** (`[Object[]]`) - References to other files with name and full path.

            Child Object Details:
            #### FunctionDetails (`[Object]`)
                - **functionName** (`[String]`) - Name of the function.
                - **cmdLets** (`[Object]`) - Functions/cmdlets called, with name and usage count.
                - **types** (`[Object]`) - Classes referenced, with name and usage count.
                - **parameterTypes** (`[Object]`) - Enums used.
                - **Validators** (`[Object]`) - Validator classes used.
                - **Properties** (`[String[]]`) - Properties within the function.

            #### ClassDetails (`[Object]`)
                - **ClassName** (`[String]`) - Name of the class.
                - **Methods** (`[String]`) - Methods defined in the class.
                - **Properties** (`[String[]]`) - Properties within the class.


        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification='Plural Details reflects multiple attributes returned and improves clarity.')]
    PARAM(
        #Path to source folder.
        [Parameter(ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string]$Path = ((get-item 'source').fullname)
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        if($mockPsScriptRoot)
        {
            write-warning 'Assuming PSScriptRoot from $mockPsScriptRoot. This should only be done for testing'
            $resourceFolder = Join-Path $mockPsScriptRoot 'resource'
        }else{
            $resourceFolder = Join-Path $PSScriptRoot 'resource'
        }

        $scriptBlockPath = Join-Path -Path $resourceFolder -ChildPath 'scriptBlocks' -AdditionalChildPath 'Get-MFFolderItemDetails.scriptblock.ps1'
        if(!(Test-Path $scriptBlockPath))
        {
            throw "Unable to find scriptblock resource at: $scriptBlockPath"
        }
    }

    process{
        write-verbose 'Loading Scriptblock'
        [scriptblock]$sblock = [scriptblock]::Create((Get-Content $scriptBlockPath -Raw))

        write-verbose 'Getting Folder Items'
        [array]$folders = @('enums','validationClasses','classes','dscClasses','functions','private')
        $folderItems = $folders.ForEach{
            $folderPath = Join-Path $Path -ChildPath $_
            if(!(test-path $folderPath))
            {
                write-verbose "$folderPath not found. Skipping"
            }else{
                write-verbose "Getting items from $folderPath"
                get-mfFolderItems -path $folderPath -psScriptsOnly
            }
        }

        write-verbose "Starting Job; arguments `nPath:$($Path|out-string)`nFiles:`n$($folderItems.name|out-string))"
        $job = Start-Job -ScriptBlock $sblock -ArgumentList @($Path, $folderItems) -WorkingDirectory $Path
        $job|Wait-Job|out-null
        write-verbose 'Retrieving output and returning result'
        $output = Receive-Job -Job $job

        remove-job -job $job
        return $output
    }
}
