function Add-MFGithubScaffold
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
            Add-MFGithubScaffold

            #### DESCRIPTION
            Copies the `.GitHub` folder from the module's `resource` directory to the current module, skipping existing files.

            #### OUTPUT
            Should have a .github folder, with workflows and a PR template

        .EXAMPLE
            Add-MFGithubScaffold -Force

            #### DESCRIPTION
            Copies the `.GitHub` scaffold and overwrites existing files in `.github` directory

            #### OUTPUT
            Should have a .github folder, with workflows and a PR template
            
        .NOTES
            Author: Adrian Andersson
            
    #>

    [CmdletBinding()]
    PARAM(
        #Root path of the module. Uses the current working directory by default
        [Parameter()]
        [alias('Path')]
        [string]$ModulePath = $(get-location).path,
        #Module Config reference
        [Parameter(DontShow)]
        [string]$ConfigFile = 'moduleForgeConfig.xml',
        #githubFolder
        [Parameter(DontShow)]
        [string]$GithubFolder = '.github',
        #Should we overwrite if files exist?
        [switch]$Force
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

        $mfConfigFile = join-path $ModulePath $ConfigFile
        if(!(test-path $mfConfigFile))
        {
            throw 'Err: No Moduleforge Config File found. Please check your module path'
        }

        $moduleGitFolder = join-path $ModulePath $GithubFolder

    }
    
    process{
        if(!(test-path $moduleGitFolder)){
            write-verbose "$moduleGitFolder does not exist, creating"
            $null = new-item -ItemType Directory -Path $moduleGitFolder
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
                if($Force)
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
        $warning = "We've added the GitHub Actions workflows and PR template to your repo. GitHub will pick these up automatically once you push to GitHub.`n`nYou may need to enable workflow permissions (read/write) and configure any required secrets for the build and release workflow to run.`n`nSee https://docs.github.com/actions or `nhttps://adrian-andersson.github.io/ModuleForge/ for guidance, examples and tutorials"
        Write-Warning $warning

    }

}