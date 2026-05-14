function Resolve-MFModuleCase
{

    <#
        .SYNOPSIS
            Nuget specs enforce all lowercase. Pwsh specs recommend pascal case for module names.
            This is fine until you install a module from Nuget 2+ on a *NIX platform
            It will install fine, but the folder case will be lowercase, and the manifest will be whatever the module name is
            This means discoverability (Get-Module, Import-Module) are effectively broken
            
        .DESCRIPTION
            1. Tries to find a module with Get-Module -listavailable
            2. If it cannot find the module, iterate all the module paths and try and case-insensitive match
            3. If found at step 2, compare the folder name to the manifest basename
            4. If the Case issue is identified, warn, and try and rename. Throw on rename error
            5. Do a final check with Get-Module -listavailable (which should now work after a rename). Throw if fail
            
        ------------
        .EXAMPLE
            Verb-Noun Param1
            
            #### DESCRIPTION
            Line by line of what this example will do
            
            
            #### OUTPUT
            Copy of the output of this line

        .OUTPUTS
            [PSModuleInfo[]] - Should return a PSModule on success
                
        .NOTES
            Author: Adrian Andersson
            
    #>

    [CmdletBinding()]
    PARAM(
        #Name of the Module to resolve
        [Parameter(Mandatory)]
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
        
    }
    
    process{
        write-verbose "Checking for module $ModuleName via Get-Module -ListAvailable" 
        $module = Get-Module -ListAvailable -ErrorAction SilentlyContinue| Where-Object { $_.Name -ieq $ModuleName }
        if ($module) {
            Write-Verbose "Module already discoverable. No casing fix required."
            return $module
        }

        Write-Verbose "Module not discoverable. Searching module paths for case-insensitive match…"
        if($ModuleFolder)
        {
            Write-Verbose "Module path override set to: $ModuleFolder"
            $modulePaths = $ModuleFolder
        }else{
            Write-Verbose 'Retrieving Module paths from $env:PSModulePath'
            $modulePaths = $env:PSModulePath -split [IO.Path]::PathSeparator
        }
        $moduleCandidates = [System.Collections.Generic.List[object]]::new()

        $modulePaths.ForEach{
            remove-variable Folder -ErrorAction Ignore
            Write-Verbose "Checking Module Path: $($_)"
            if(!(Test-Path $_)){
                Write-Warning "Module Path:$($_) Not Found - Skipping"
                continue
            }
            $Folder = $(Get-ChildItem -Path $_ -Directory -ErrorAction SilentlyContinue).where{
                $_.Name -ieq $ModuleName 
            } | Select-Object -First 1
                
            if($Folder)
            {
                Write-Verbose "Potential Candidate located at $($Folder).FullName"
                $moduleCandidates.Add($Folder)
            }
        }

        $moduleCandidatesArr = $moduleCandidates.ToArray()
        if($moduleCandidatesArr.count -lt 1)
        {
            throw "Module [$ModuleName] not found in any PSModulePath location"
        }

        Write-Verbose "Found $($moduleCandidatesArr.count) Module Candidates"

        Write-Verbose "Checking manifest and basenames to ensure correct casing"
        $moduleCandidatesArr.ForEach{
            remove-variable manifest,folderName,manifestName -ErrorAction Ignore
            $manifest = Get-ChildItem -Path $_.FullName -Recurse -Filter *.psd1 | Select-Object -First 1
            if(!$manifest)
            {
                Write-Warning "Manifest not found at $($_.FullName)"
            }else{
                #Apparently renaming folders on linux when case is the same is problematic
                #And the solution is a 2 step rename
                #I'm dubious, but I'll try it
                $folderName = $_.BaseName
                $manifestName = $manifest.BaseName
                $tempName = 'tempName'
                $tempPath = Join-Path $_.Directory.FullName $tempName
                Write-Verbose "Comparing folder name: $folderName with manifest name: $manifestName"
                if($folderName -cne $manifestName){
                    Write-Warning "Casing mismatch detected: folder $folderName vs manifest $manifestName"
                    Write-Verbose "Attempting rename…"
                    try {
                        Rename-Item -Path $_.FullName -NewName $tempName -Force -ErrorAction Stop
                        Start-Sleep -Seconds 5
                        Rename-Item -Path $tempPath -NewName $manifestName -Force -ErrorAction Stop
                    }catch{
                        throw "Failed to rename module folder: $_"
                    }
                }else{
                    Write-Verbose "Folder and manifest names already match. No rename needed."
                }
            }
        }
        Write-Verbose 'Pausing for 5 seconds to allow IO-ops to finish'
        Start-Sleep -Seconds 5 
        write-verbose "Rechecking for module $ModuleName via Get-Module -ListAvailable" 
        $module = Get-Module -ListAvailable -ErrorAction SilentlyContinue| Where-Object { $_.Name -ieq $ModuleName }
        if ($module) {
            Write-Verbose "Module Discovered"
            return $module
        }else{
            throw "Module $ModuleName still not discoverable after casing correction"
        }       
    }
    
}