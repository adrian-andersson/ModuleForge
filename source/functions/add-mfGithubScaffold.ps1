function add-mfGithubScaffold
{

    <#
        .SYNOPSIS
            Initialises a `.GitHub` scaffold in a PowerShell module, including GH Actions workflows for pester testing and build and release

            
        .DESCRIPTION
            This function will create a '.github' folder in the moduleforge root (if one does not exist).
            It will create 2 github actions workflows, 1 for Pester testing, 1 for buildAndRelease
            It will create 1 Pull Request template.

            The buildAndRelease template will use Git Tags to mark versions. If you stick with this template you should refrain from
            using tags for other purposes.
            
            The purpose of these workflows and templates is to get you started, creating a quick and easy workflow scaffold. 
            Please feel free to change the workflows and template to your own needs and preferences.
            
        .EXAMPLE
            Add-mfGithubScaffold

            #### DESCRIPTION
            Copies the `.GitHub` folder from the module's `resource` directory to the current module, skipping existing files.

            #### OUTPUT
            Should have a .github folder, with workflows and a PR template

        .EXAMPLE
            Add-mfGithubScaffold -Force

            #### DESCRIPTION
            Copies the `.GitHub` scaffold and overwrites existing files in `.github` directory

            #### OUTPUT
            Should have a .github folder, with workflows and a PR template
            
        .NOTES
            Author: Adrian Andersson
            
    #>

    [CmdletBinding()]
    PARAM(
        #Root path of the module. Uses the current working directory by default. Aliased path, but use modulePath as paramname to avoid confusion
        [Parameter()]
        [alias('path')]
        [string]$modulePath = $(get-location).path,
        #Module Config reference
        [Parameter(DontShow)]
        [string]$configFile = 'moduleForgeConfig.xml',
        #githubFolder
        [Parameter(DontShow)]
        [string]$githubFolder = '.github',
        #Should we overwrite if files exist?
        [switch]$force
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        if($mockPsScriptRoot)
        {
            #Assume we are in pester test, and use the $mockPsScriptRoot param
            write-warning 'Assuming PSScriptRoot from $mockPsScriptRoot. This should only be done for testing'
            $resourceFolder = Join-Path $mockPsScriptRoot 'resource'
            
        }else{
            $resourceFolder = Join-Path $PSScriptRoot 'resource'
        }
        write-verbose "ResourceFolder:  $resourceFolder"
        
        if(!(test-path  $resourceFolder))
        {
            throw 'Err: Unable to find resource folder in ModuleForge module'
        }

        $resourceFolderGithub = join-path $resourceFolder 'github'
        if(!(test-path  $resourceFolderGithub))
        {
            throw 'Err: Found resource folder, but not Github folder in ModuleForge module'
        }

        $mfConfigFile = join-path $modulePath $configFile
        if(!(test-path $mfConfigFile))
        {
            throw 'Err: No Moduleforge Config File found. Please check your module path'
        }

        $moduleGitFolder = join-path $modulePath $githubFolder

    }
    
    process{
        if(!(test-path $moduleGitFolder)){
            write-verbose "$moduleGitFolder does not exist, creating"
            new-item -ItemType Directory -Path $moduleGitFolder
        }else{
            write-verbose "$moduleGitFolder already exists"
        }

        $childItemSource = get-childitem $resourceFolderGithub -Recurse
        $childItemSource.foreach{
            write-verbose "Checking file: $($_.name)`n Need to replace $resourceFolderGithub with $moduleGitFolder"
            #Need to not use .replace method as it is case sensitive. 
            $destinationPath = $_.FullName -replace [regex]::Escape($resourceFolderGithub), $moduleGitFolder
            write-verbose "DestinationPath: $destinationPath"
            if($destinationPath -eq $_.FullName)
            {
                throw "Destination path matches original file path. Replace has not worked `n$($destinationPath) -> $($_.FullName)"
            }else{
                write-verbose "DestinationPath: $destinationPath"
            }
            if(test-path $destinationPath){
                if($force)
                {
                    if ($_.PSIsContainer) {
                        Write-Verbose "Skipping directory: $($_.FullName)"
                    }else{
                        write-warning "Overwrite $destinationPath"
                        copy-item -Path $_.FullName -Destination $destinationPath -Force
                    }
                }else{
                    write-warning "Skipping $destinationPath as it exists"
                }
            }else{
                write-verbose "Copying $($_) to $destinationPath"
                copy-item -Path $_.FullName -Destination $destinationPath
            }
        }
    }
    
}