function add-mfGithubScaffold
{

    <#
        .SYNOPSIS
            Initialises a `.GitHub` scaffold in a PowerShell module.

            
        .DESCRIPTION
            This function copies the `.GitHub` folder from a module's resource directory to a target module path.
            It maintains the directory structure and only overwrites existing files if the `-Force` switch is provided.
            This is useful for setting up GitHub workflows, PR templates, and other repository configurations.


            
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
        }

        $childItemSource = get-childitem $resourceFolderGithub -Recurse
        $childItemSource.foreach{
            $destinationPath = $_.FullName.replace($resourceFolderGithub,$moduleGitFolder)
            if(test-path $destinationPath){
                if($force)
                {
                    write-warning "Overwrite $destinationPath"
                    copy-item -Path $_.FullName -Destination $destinationPath -Force
                }else{
                    write-warning "Skipping $destinationPath as it exists"
                }
            }else{
                write-verbose "Copying destinationPath"
                copy-item -Path $_.FullName -Destination $destinationPath
            }
        }
    }
    
}