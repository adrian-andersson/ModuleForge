function Resolve-MFModuleCase
{

    <#
        .SYNOPSIS
            Nuget specs enforce all lowercase. Pwsh specs recommend pascal case for module names.
            This is fine until you install a module from Nuget 2+ on a *NIX platform
            It will install fine, but the folder case will be lowercase, and the manifest will be whatever the module name is
            This means discoverability (Get-Module, Import-Module) are effectively broken
            This function attempts to fix that discrepency by renaming the module folder to the same as the manifest
            
        .DESCRIPTION
            Try and find a module folder based on a module name
            If module folders are found, for each one, try and find the latest Semver version
            If Semvers are identified, choose the latest
            If the latest version folder (As identified above) has a manifest, get the manifest name
            Case-Compare the manifest name with the folder name. 
            If the name does not match, try and rename the folder
            On rename, sleep for 4 seconds, then proceed to other found locations and repeat if necessary
            
        ------------
        .EXAMPLE
            Resolve-MFModuleCase -ModuleName moduleforgecasetest -Verbose
            
            #### DESCRIPTION
            VERBOSE: ===========Executing Resolve-MFModuleCase===========
            VERBOSE: Found 1 locations. Getting latest manifest
            VERBOSE: Checking folder C:\Users\example\Documents\PowerShell\Modulesmmoduleforgecasetest
            VERBOSE: Found latest version of: 1.0.1
            VERBOSE: Found Manifest name with: ModuleForgeCaseTest
            WARNING: Case mismatch between module folder moduleforgecasetest and ModuleForgeCaseTest
            VERBOSE: Attempt to rename folder to manifest basename to correct for casing
            VERBOSE: Folder Rename attempted

        .OUTPUTS
            [PSCustomObject] - Returns a result object per module location found, containing FolderFullName, FolderBaseName, ManifestName, RenameAttempt, and ManifestAndFolderMatch

        .NOTES
            Author: Adrian Andersson

    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    PARAM(
        #Name of the Module to resolve
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$ModuleName,
        #ModuleFolder to use. If you want to override the module locations manually, use this
        [Parameter()]
        [string[]]$ModuleFolder

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $folderVersionSelect = @(
            'FullName'
            'Name'
            @{
                Name = 'Semver'
                Expression = {
                    try {
                        [semver]"$($_.Name)"
                    }catch {
                        $null
                    }
                }
            }
        )
        
    }
    
    process{
        #Hold any module candidates in a collection
        $moduleCandidates = [System.Collections.Generic.List[string]]::new()
        if($ModuleFolder)
        {
            write-verbose "Checking defined folder: $ModuleFolder"
            $foundItems = Get-ChildItem -Path $ModuleFolder -Recurse -Filter $ModuleName -Directory
            $foundItems.foreach{
                $moduleCandidates.Add($_.FullName)
            }
        }else{
            $locations = $env:PSModulePath -split [IO.Path]::PathSeparator
            $locations.Foreach{
                try{
                    $foundItems = Get-ChildItem -Path $_ -Recurse -Filter $ModuleName -Directory -ErrorAction Ignore
                    $foundItems.foreach{
                        $moduleCandidates.Add($_.FullName)
                    }
                }catch{
                    Write-Warning "Skipping path $_ due to read or permission errors"
                }
                
            }
        }
        $moduleCandidates = $moduleCandidates.ToArray()
        Write-Verbose "Found $($moduleCandidates.count) locations."
        if(!$moduleCandidates -or $moduleCandidates.Count -lt 1)
        {
            Write-Warning "No module folders found for module: $ModuleName"
        }
        $moduleCandidates.forEach{
            $moduleFolderBasename = $(Get-Item $_).BaseName
            Remove-Variable latestVersion,modManifest,BaseFolderRefresh -ErrorAction Ignore
            #Whilst risky, this seems a good compromise. We need to find the latest version somehow
            Write-Verbose "Checking folder $_ for latest module version"
            $latestVersion = $(Get-ChildItem -path $_|Select-Object $folderVersionSelect).where{$_.Semver}|Sort-Object -Property Semver -Descending|Select-Object -First 1
            if($latestVersion)
            {
                Write-Verbose "Found latest version of: $($latestVersion.Name)"
                $modManifest = $(Get-ChildItem -Path $latestVersion.FullName).where{$_.name -eq  "$ModuleName.psd1"}|Select-Object -first 1
                Write-Verbose "Found Manifest name with: $($modManifest.basename)"
                If($(Get-Item $_).BaseName -cne $modManifest.basename)
                {
                    Write-Warning "Case mismatch between module folder $moduleFolderBasename and $($modManifest.basename)"
                    write-verbose "Attempt to rename folder to manifest basename to correct for casing"
                    try{
                        Rename-Item -path $_ -NewName $modManifest.BaseName -Force -Erroraction Stop
                        #Small 4 second sleep for IOPS
                        Start-Sleep -Seconds 4
                        Write-Verbose 'Folder Rename attempted'
                    }catch{
                        write-warning 'Error renaming folder'
                        
                    }
                    #We need to do it this way, because we just renamed our folder, and that matters on linux
                    $Parent = Split-Path $_ -Parent
                    $NewFullPath = Join-Path $Parent $modManifest.BaseName
                    try{
                        #Try and get the new item
                        $BaseFolderRefresh = Get-Item $NewFullPath
                    }catch{
                        #If that fails, go and get the old item
                        $BaseFolderRefresh = Get-Item $_
                    }
                    
                    [PSCustomObject]@{
                        FolderFullName = $BaseFolderRefresh.FullName
                        FolderBaseName = $BaseFolderRefresh.BaseName
                        ManifestName = $modManifest.BaseName
                        RenameAttempt = $true
                        ManifestAndFolderMatch = if($BaseFolderRefresh.BaseName -ceq $modManifest.BaseName){$true}else{$false}
                    }
                }else{
                    Write-Verbose "Case match between module folder $moduleFolderBasename and $($modManifest.basename) - All Ok"
                    [PSCustomObject]@{
                        FolderFullName = $_
                        FolderBaseName = $moduleFolderBasename
                        ManifestName = $modManifest.BaseName
                        RenameAttempt = $false
                        ManifestAndFolderMatch = if($moduleFolderBasename -ceq $modManifest.BaseName){$true}else{$false}
                    }
                }
                Write-Verbose "Finished checking folder $_"
            }else{
                Write-Warning "No module versions found for $modulename in folder $_"
            }
        }
    }
}