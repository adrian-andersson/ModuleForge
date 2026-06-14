function Add-MFProjectScripts
{

    <#
        .SYNOPSIS
            Adds a scripts scaffold to a ModuleForge project.

        .DESCRIPTION
            Copies script templates from ModuleForge's resource\scripts folder into a scripts
            subfolder at the project root. Skips existing files by default.

            Includes Invoke-MFPester.ps1  - a standalone Pester runner that does not depend on
            the ModuleForge module, safe for use in clean CI environments.

            This function is also called automatically by Add-MFFilesAndFolders during project
            creation, at which point moduleForgeConfig.xml may not yet exist. A warning is
            emitted in that case but the copy proceeds normally.

        .EXAMPLE
            Add-MFProjectScripts

            #### DESCRIPTION
            Copies script templates into the scripts folder, skipping any that already exist.

        .EXAMPLE
            Add-MFProjectScripts -Force

            #### DESCRIPTION
            Copies script templates and overwrites any existing files in the scripts folder.

        .NOTES
            Author: Adrian Andersson

    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseSingularNouns", "", Justification = "Plural 'Scripts' reflects that the function copies multiple script templates into the project.")]
    PARAM(
        #Root path of the module. Uses the current working directory by default
        [Parameter()]
        [alias('Path')]
        [string]$ModulePath = $(Get-Location).path,
        #Module Config reference
        [Parameter(DontShow)]
        [string]$ConfigFile = 'moduleForgeConfig.xml',
        #Scripts folder name
        [Parameter(DontShow)]
        [string]$ScriptsFolder = 'scripts',
        #Should we overwrite if files exist?
        [switch]$Force
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        $skipProcess = $false
        if($mockPsScriptRoot)
        {
            write-warning 'Assuming PSScriptRoot from $mockPsScriptRoot. This should only be done for testing'
            $resourceFolder = Join-Path $mockPsScriptRoot 'resource'
        }else{
            $resourceFolder = Join-Path $PSScriptRoot 'resource'
        }
        write-verbose "ResourceFolder: $resourceFolder"

        if(!(Test-Path $resourceFolder))
        {
            Write-Warning 'Add-MFProjectScripts: resource folder not found in ModuleForge module  - skipping script scaffold'
            $skipProcess = $true
        }

        if(!$skipProcess)
        {
            $resourceFolderScripts = Join-Path $resourceFolder 'scripts'
            if(!(Test-Path $resourceFolderScripts))
            {
                Write-Warning 'Add-MFProjectScripts: scripts folder not found in ModuleForge resource  - skipping script scaffold'
                $skipProcess = $true
            }
        }

        if(!$skipProcess)
        {
            $mfConfigFile = Join-Path $ModulePath $ConfigFile
            if(!(Test-Path $mfConfigFile))
            {
                Write-Warning 'No ModuleForge config file found. Ensure this is a ModuleForge project.'
            }
            $moduleScriptsFolder = Join-Path $ModulePath $ScriptsFolder
        }
    }

    process{
        if($skipProcess){ return }
        if(!(Test-Path $moduleScriptsFolder)){
            write-verbose "$moduleScriptsFolder does not exist, creating"
            $null = New-Item -ItemType Directory -Path $moduleScriptsFolder
        }else{
            write-verbose "$moduleScriptsFolder already exists"
        }

        $childItemSource = Get-ChildItem $resourceFolderScripts -Recurse
        $childItemSource.foreach{
            $destinationPath = $_.FullName -replace [regex]::Escape($resourceFolderScripts), $moduleScriptsFolder
            write-verbose "DestinationPath: $destinationPath"
            if($destinationPath -eq $_.FullName)
            {
                throw "Destination path matches original file path. Replace has not worked `n$($destinationPath) -> $($_.FullName)"
            }
            if(Test-Path $destinationPath){
                if($Force)
                {
                    if($_.PSIsContainer){
                        Write-Verbose "Skipping directory: $($_.FullName)"
                    }else{
                        write-warning "Overwrite $destinationPath"
                        Copy-Item -Path $_.FullName -Destination $destinationPath -Force
                    }
                }else{
                    write-warning "Skipping $destinationPath as it exists"
                }
            }else{
                write-verbose "Copying $($_) to $destinationPath"
                Copy-Item -Path $_.FullName -Destination $destinationPath
            }
        }
    }

}