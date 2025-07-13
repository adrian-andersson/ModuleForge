function add-mfAzureDevOpsScaffold
{

    <#
        .SYNOPSIS
            Initialises a `.azuredevops` scaffold in a PowerShell module, including YAML Azure DevOps Pipelines for pester testing and build and release

            
        .DESCRIPTION
            This function will create a '.azuredevops' folder in the moduleforge root (if one does not exist).
            It will create 2 Azure DevOps Pipelines files, 1 for Pester testing, 1 for buildAndRelease
            It will create 1 Pull Request template.

            The buildAndRelease pipeline will use Git Tags to mark versions. If you stick with this template you should refrain from
            using tags for other purposes.
            
            The purpose of these workflows and templates is to get you started, creating a quick and easy workflow scaffold. 
            Please feel free to change the workflows and template to your own needs and preferences.
            
        .EXAMPLE
            add-mfAzureDevOpsScaffold

            #### DESCRIPTION
            Copies the `.azuredevops` folder from the module's `resource` directory to the current module, skipping existing files.

            #### OUTPUT
            Should have a .azuredevops folder, with pipelines and a PR template

        .EXAMPLE
            add-mfAzureDevOpsScaffold -Force

            #### DESCRIPTION
            Copies the `.azuredevops` scaffold and overwrites existing files in `.azuredevops` directory

            #### OUTPUT
            Should have a .azuredevops folder, with workflows and a PR template
            
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
        #Azure DevOps folder
        [Parameter(DontShow)]
        [string]$azdFolder = '.azuredevops',
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

        $resourceFolderAzd = join-path $resourceFolder 'azureDevOps'
        if(!(test-path  $resourceFolderAzd))
        {
            throw 'Err: Found resource folder, but not azureDevOps folder in ModuleForge module'
        }

        $mfConfigFile = join-path $modulePath $configFile
        if(!(test-path $mfConfigFile))
        {
            throw 'Err: No Moduleforge Config File found. Please check your module path'
        }

        $moduleAzdFolder = join-path $modulePath $azdFolder

    }
    
    process{
        if(!(test-path $moduleAzdFolder)){
            write-verbose "$moduleAzdFolder does not exist, creating"
            new-item -ItemType Directory -Path $moduleAzdFolder|out-null
        }else{
            write-verbose "$moduleAzdFolder already exists"
        }

        $childItemSource = get-childitem $resourceFolderAzd -Recurse
        $childItemSource.foreach{
            write-verbose "Checking file: $($_.name)`n Need to replace $resourceFolderAzd with $moduleAzdFolder"
            #Need to not use .replace method as it is case sensitive. 
            $destinationPath = $_.FullName -replace [regex]::Escape($resourceFolderAzd), $moduleAzdFolder
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
        $warning = "We've added the pipeline YAML files to your repo, however Azure DevOps will not automatically create the pipelines.`n`nYou will need to create the pipelines manually and point them to the provided YAML files.`n`nSee https://learn.microsoft.com/en-us/azure/devops/pipelines/create-first-pipeline or `nhttps://adrian-andersson.github.io/ModuleForge/tutorials/azureDevOps/tutorial.html for guidance"
        Write-Warning $warning 

    }
}