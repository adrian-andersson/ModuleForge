function write-mfModuleDocs
{

    <#
        .SYNOPSIS
            Generates and updates function documentation using PlatyPS, and creates an index for module functions.

        .DESCRIPTION
            This function automates documentation generation based on module functions, leveraging PlatyPS to create and update Markdown help files.
            It also builds an `index.md` file for organizing documentation, making it easier to integrate with GitHub Pages or other documentation platforms.
            Additionally, if specified, it includes a changelog based on Git commits.

        .EXAMPLE
            write-mfModuleDocs -ModuleName 'MyCustomModule' -includeChangeLog

            #### DESCRIPTION
            Builds documentation for `MyCustomModule` and includes a full Git-based changelog (`changeLog.md`) alongside function help files.

        .EXAMPLE
            write-mfModuleDocs -ModuleName 'MyCustomModule' -skipIndex

            #### DESCRIPTION
            Generates function documentation without updating `index.md`.

        .INPUTS
            [string] - Path is accepted as pipeline input or via direct assignment. It has a defaulf value and does not need to be set

        .NOTES
            Author: Adrian Andersson
            
    #>

    [CmdletBinding()]
    PARAM(
        #The root path where documentation should be stored. Defaults to the current directory.
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [alias('modulePath')]
        [string]$Path = $(get-item .).fullname,
        #The name of the PowerShell module for which documentation should be generated.
        [Parameter(Mandatory)]
        [alias('module')]
        [ValidateScript({ Get-Module -Name $_ -ErrorAction SilentlyContinue })]
        [string]$ModuleName,
        #Specifies the subfolder within `docsFolder` where function-specific documentation should be stored. Defaults to `functions`.
        [Parameter()]
        [alias('docsPath')]
        [string]$docsFolder = 'docs',
        #Specifies the subfolder within `docsFolder` where function-specific documentation should be stored. Defaults to `functions`.
        [Parameter()]
        [alias('functionsPath')]
        [string]$functionsFolder = 'functions',
        #If specified, retrieves and includes a Markdown changelog based on Git commit history.
        [Parameter()]
        [switch]$includeChangeLog,
        #If specified, skips creating or updating the `index.md` file.
        [Parameter()]
        [switch]$skipIndex
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $platyPs = (get-module -Name PlatyPS -ListAvailable|Sort-Object -Property version -Descending|select-object -first 1)
        if($platyPs)
        {
            write-verbose "Build Function Documentation with PlatyPS Version $($platyPs.version)"
        }else{
            throw "This function relies on module PlatyPS. Please install it from the PSGallery"
        }

        $module = (get-module -Name $ModuleName|Sort-Object -Property version -Descending|select-object -first 1)
        if($module)
        {
            write-verbose "Build Function Documentation for Module $ModuleName - version: $($module.version)"
        }else{
            throw "Module is not pre-loaded. Please import the module first"
        }

        $customFolderSelect = @(
            'name'
            'basename'
            @{
                name = 'baseFolder'
                expression = {$($_.Directory.FullName.replace($DocsFullPath,''))}
            }
            @{
                name = 'leaf'
                expression = {$(split-path -path $_.Directory.FullName -leaf)}
            }
            @{
                name = 'relLink'
                expression = {("./$($($_.Directory.FullName.replace($DocsFullPath,'')).replace('\','/'))/$($_.name)").replace('//','/')}
            }
            @{
                name = 'subjectGroup'
                expression = {("$($($_.Directory.FullName.replace($DocsFullPath,'')).replace('\','/'))").replace('//','/').trimStart('/')}
            }
        )

        
    }
    
    process{
        #Checks and parses
        write-verbose "In path $path"
        $DocsFullPath = join-path -Path $Path -ChildPath $docsFolder
        if(!(test-path $DocsFullPath))
        {
            write-verbose 'Need to make docs folder as it does not exist'
            New-Item -ItemType Directory -Path $DocsFullPath
        }

        $functionsFullPath = join-path -Path $DocsFullPath -ChildPath $functionsFolder
        if(!(test-path $functionsFullPath))
        {
            write-verbose 'Need to make functions folder as it does not exist'
            New-Item -ItemType Directory -Path $functionsFullPath
        }else{
            write-verbose 'Recreating Functions Folder'
            try{
                remove-item $functionsFullPath -ErrorAction Stop -Force -Recurse
            }catch{
                throw 'Error cleaning up existing functions folder'
            }
            New-Item -ItemType Directory -Path $functionsFullPath
        }
        
        #Actual Process
        write-verbose 'Create markdown help from module help'
        New-MarkdownHelp -Module $module.Name -Force -OutputFolder $functionsFullPath

        if($includeChangeLog)
        {
            write-verbose 'Creating releaseNotes file'
            $changeLog = get-mfGitChangeLog -all
            write-verbose "ChangeLog: `n$($changeLog)"
            if($changeLog)
            {
                $changeLogPath = Join-Path $DocsFullPath -ChildPath 'changeLog.md'
                $changeLog | Out-File -FilePath $changeLogPath -Force 
            }else{
                write-warning 'changeLog notes were not captured as none existed, or something went wrong'
            }
        }

        if($skipIndex){
            Write-Verbose 'Skipping Index File'
        }else{
            $indexContent = [System.Collections.Generic.List[string]]::new()
            $indexContent.add("# Documentation Index`n")
            $folderContent = Get-ChildItem -Path  $DocsFullPath -Filter '*.md' -Recurse|Select-Object $customFolderSelect
            $folderGroup = $folderContent|Group-Object -Property 'subjectGroup'
            ($folderGroup.where{$_.'name' -eq ''}.group).foreach{
                if($_.'basename' -ne 'index')
                {
                    $indexContent.add("- [$($_.baseName)]($($_.relLink))")
                }
    
            }
            $folderGroup.where{$_.'name' -ne ''}.forEach{

                $indexContent.add("`n## $($_.'name')`n")
                $_.group.foreach{
                    $indexContent.add("- [$($_.baseName)]($($_.relLink))")
                }
            }
            write-verbose 'Create Index File'
            $indexPath = Join-Path $DocsFullPath -ChildPath 'index.md'
            $indexContent -join "`n"|out-file $indexPath -Force
        }
        
    }
    
}