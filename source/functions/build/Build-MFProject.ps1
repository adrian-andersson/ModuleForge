function Build-MFProject
{

    <#
        .SYNOPSIS
            Grab all the files from source, compile them into a single PowerShell module file, create a new module manifest.
            
        .DESCRIPTION
            Grab the content, functions, classes, validators etc from the .\source\ directory
            For all functions found in files in the .\source\functions directory, export them in the module manifest
            Add the contents of all scripts to a PSM1 file
            Add the contents of any Validators to a separate external ps1 file as a module dependency
            Create a new module manifest from the parameters saved with new-mfProject
            Tag as a pre-release if a semverPreRelease label is found

        .EXAMPLE
            Build-MFProject -Version '0.12.2-prerelease.1'
            
            #### DESCRIPTION
            Make a PowerShell module from the current folder, and mark it as a pre-release version
            
        .NOTES
            Author: Adrian Andersson
                    
    #>

    [CmdletBinding()]
    PARAM(
        #What version are we building?
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [semver]$Version,
        #Root path of the module. Uses the current working directory by default
        [Parameter()]
        [alias('Path')]
        [string]$ModulePath = $(get-location).path,
        #Path to the ModuleForge config file. Defaults to 'moduleForgeConfig.xml' in the module root
        [Parameter(DontShow)]
        [string]$ConfigFile = 'moduleForgeConfig.xml',
        #Use this flag to put any classes in ScriptsToProcess
        [Parameter()]
        [switch]$ExportClasses,
        #Use this flag to put any enums in ScriptsToProcess
        [Parameter()]
        [switch]$ExportEnums,
        #Use this to keep everything in a single module file. By default validators (and exported classes/enums) are written to separate scripts loaded via ScriptsToProcess so they resolve correctly; this switch inlines them into the module file instead
        [Parameter()]
        [switch]$NoExternalFiles,
        #Release notes to include in the module manifest and GitHub release output
        [Parameter()]
        [string]$ReleaseNotes,
        #If set, appends the release notes to the module description in the manifest
        [Parameter()]
        [switch]$IncludeReleaseNotesInDescription,
        #If set, omits the ModuleForge build provenance (the psm1 header marker and the ModuleForgeBuild* keys in
        #the manifest PrivateData). Provenance is on by default - the SHA256 hashes it records match the checksums
        #published on the ModuleForge release, so impacted builds can be traced if a vulnerability is found in the tooling
        [Parameter()]
        [switch]$NoBuildProvenance


    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        write-verbose 'Testing module path'
        try{
            $moduleTest = get-item $ModulePath -ErrorAction SilentlyContinue
        }catch{
            $moduleTest = $null
        }
        
        if(!$moduleTest){
            throw "Unable to read from $ModulePath"
        }

        $ModulePath = $moduleTest.FullName
        write-verbose "Building from: $ModulePath"

        #Read the config file
        write-verbose 'Importing config file'
        $configPath = join-path -path $ModulePath -ChildPath $ConfigFile

        if(!(test-path $configPath))
        {
            throw "Unable to find config file at: $configPath"
        }

        $config = import-clixml $configPath -erroraction stop

        if(!$config)
        {
            throw "Unable to import config file from: $configPath"
        }

        #Reference version as a string
        $VersionString = $Version.tostring()

        write-verbose 'Checking for a build and module folder'
        $buildFolder = join-path -path $ModulePath -childPath 'build'
        if(!(test-path $buildFolder))
        {
            write-verbose "Build folder not found at: $($buildFolder), creating"
            try{
                #Save to var to lose the output
                $null = new-item -ItemType Directory -Path $buildFolder -ErrorAction Stop
            }catch{
                throw 'Unable to create build folder'
            }
        }

        $moduleOutputFolder = join-path -path $buildFolder -ChildPath $($config.moduleName)

        if(!(test-path $moduleOutputFolder))
        {
            write-verbose "Module folder not found at: $($moduleOutputFolder), creating"
            try{
                $null = new-item -ItemType Directory -Path $moduleOutputFolder -ErrorAction Stop
            }catch{
                throw 'Unable to create Module folder'
            }
        }else{
            write-verbose "Module folder found at: $($moduleOutputFolder), need to replace"
            try{
                remove-item $moduleOutputFolder -force -Recurse
                #Windows can hold a brief lock on the folder after remove-item returns. Poll until it
                #clears (usually near-instant) rather than blindly sleeping a fixed couple of seconds.
                $waitUntil = (get-date).AddSeconds(5)
                while((test-path $moduleOutputFolder) -and (get-date) -lt $waitUntil)
                {
                    start-sleep -Milliseconds 100
                }
                #Save to var to lose the output. More efficient than |out-null
                $null = new-item -ItemType Directory -Path $moduleOutputFolder -ErrorAction Stop
            }catch{
                throw 'Unable to recreate Module folder'
            }
        }

        #Capture the ModuleForge version (including any prerelease label) and the SHA256 of the ModuleForge
        #psd1/psm1 used for this build. The prerelease label lives in PrivateData.PSData.Prerelease because a
        #manifest ModuleVersion cannot hold a SemVer prerelease tag, so get-module's .Version alone drops it.
        #The hashes provide build provenance - they match the SHA256 checksums published on the corresponding
        #ModuleForge GitHub release, letting a consumer verify which ModuleForge build produced this module.
        #Suppressed entirely (header and manifest keys) when -NoBuildProvenance is set.
        if($NoBuildProvenance)
        {
            write-verbose 'NoBuildProvenance set; skipping ModuleForge build provenance'
            $moduleHeader = $null
        }else{
            $moduleForgeDetails = (get-module 'ModuleForge' |Sort-Object -Property Version -Descending|select-object -First 1)
            if($moduleForgeDetails)
            {
                $mfVersion = $moduleForgeDetails.version.tostring()
                $mfPrerelease = $moduleForgeDetails.PrivateData.PSData.Prerelease
                if($mfPrerelease)
                {
                    $mfVersion = "$mfVersion-$mfPrerelease"
                }
                #Hash the ModuleForge psd1/psm1 from the loaded module base. Guard each so a hashing failure
                #(e.g. an unusual module layout) degrades to 'unknown' rather than failing the build.
                $mfPsd1Path = join-path -path $moduleForgeDetails.ModuleBase -ChildPath 'ModuleForge.psd1'
                $mfPsm1Path = join-path -path $moduleForgeDetails.ModuleBase -ChildPath 'ModuleForge.psm1'
                $mfPsd1Hash = if(test-path $mfPsd1Path){(Get-FileHash -Path $mfPsd1Path -Algorithm SHA256).Hash.ToLower()}else{'unknown'}
                $mfPsm1Hash = if(test-path $mfPsm1Path){(Get-FileHash -Path $mfPsm1Path -Algorithm SHA256).Hash.ToLower()}else{'unknown'}
            }else{
                $mfVersion = 'unknown'
                $mfPsd1Hash = 'unknown'
                $mfPsm1Hash = 'unknown'
            }

            #Single timestamp shared by the psm1 header and the manifest provenance block
            $mfBuildDate = get-date -format s
            $moduleHeader = "<#`nModule built with ModuleForge`n`t ModuleForge Version: $mfVersion`n`tModuleForge psd1 SHA256: $mfPsd1Hash`n`tModuleForge psm1 SHA256: $mfPsm1Hash`n`tBuildDate: $mfBuildDate`n#>"
        }
        $sourceFolder = join-path -path $ModulePath -childPath 'source'

        #What folders do we need to copy the files contents of
        [array]$copyFolders = @('resource','bin')

        $scriptsToProcess = New-Object System.Collections.Generic.List[string]
        $functionsToExport = New-Object System.Collections.Generic.List[string]
        #$DscResourcesToExport = New-Object System.Collections.Generic.List[string] #No Dsc Support presently

    }
    
    process{

        write-verbose "Attempt to build:`n`t`tmodule:$($config.moduleName)version:`n`t`t$VersionString"

        #References for our manifest and module root
        $moduleFileShortname = "$($config.moduleName).psm1"
        $moduleFile = join-path $moduleOutputFolder -ChildPath $moduleFileShortname
        $manifestFileShortname = "$($config.moduleName).psd1"
        $manifestFile = join-path $moduleOutputFolder -ChildPath $manifestFileShortname

        write-verbose "Will create module in:`n`t`t$moduleOutputFolder;`n`t`tModule Filename: $moduleFileShortname ;`n`t`tManifest Filename: $manifestFileShortname "

        #References for external files, if needed
        $classesFileShortname = "$($config.moduleName).Classes.ps1"
        $classesFile = join-path -path $moduleOutputFolder -ChildPath $classesFileShortname

        $validatorsFileShortname = "$($config.moduleName).Validators.ps1"
        $validatorsFile = join-path -path $moduleOutputFolder -ChildPath $validatorsFileShortname

        $enumsFileShortname = "$($config.moduleName).Enums.ps1"
        $enumsFile = join-path -path $moduleOutputFolder -ChildPath $enumsFileShortname

        
        #Start creating the moduleFile
        if($moduleHeader)
        {
            write-verbose 'Adding Header Comment'
            $moduleHeader|out-file $moduleFile -Force
        }else{
            #No provenance header (-NoBuildProvenance); still need to initialise/overwrite the module file
            write-verbose 'Skipping header comment; initialising empty module file'
            $null = new-item -Path $moduleFile -ItemType File -Force
        }


        
        #Do a check for DSC Resources because they change how we handle everything
        #Actually, for now lets not worry about DesiredStateConfig stuff - Future Release, 
        # - its a bit broken as of July 2024,
        # - It changes how we build modules because nestedmodules, scriptstoprocess dont work (From previous experience)
        # - I don't have any need to build DSC resources at this time, so my testing will be limited
        # - DSC Resources are being reworked by MicroSoft so this is a moving target anyway 
        write-verbose 'Checking for DSC Resources. DSC Resources add nuance to module build'
        $dscResourcesFolder = join-path -path $sourceFolder -ChildPath 'dscClasses'
        if(test-path $dscResourcesFolder)
        {
            $dscResourceFiles = get-mfFolderItems -path $dscResourcesFolder -psScriptsOnly
            if($dscResourceFiles.count -ge 1)
            {
                #write-warning 'DSC Resources Found - Ignoring Export Switches and Compiling to single module file'
                #$NoExternalFiles = $true
                #See above comments
                throw 'DSC is not supported in this version of moduleForge. Its on the roadmap'
            }else{
                write-verbose 'No DSC Resources found'
            }
        }else{
            #write-verbose 'No DSC folder found'
        }
        

        write-verbose 'Getting all the Script Details'
        $folderItemDetails = get-mfFolderItemDetails -path $sourceFolder
        Write-Information "File Dependency Tree:`n`n$($(get-mfdependencyTree ($folderItemDetails|Select-Object relativePath,dependencies)) -join "`n")`n" -tags 'DependencyTree'
        #Start compiling the module file and associated content
        write-verbose "`n`n`n==========================================`n`n"
        write-verbose 'Starting module Compile'
        write-debug 'Starting module Compile'
        foreach($item in $folderItemDetails)
        {
            switch($item.group)
            {
                'dscClasses' {
                    Write-Information "Processing $($item.name) as a DSCClass" -tags 'FilesProcessed'
                    write-verbose "Processing $($item.name) as a DSCClass"
                    throw 'DSC Classes currently not supported, sorry!'
                }

                'functions' {
                    Write-Information "Processing $($item.name) as a Function" -tags 'FilesProcessed'
                    write-verbose "Processing $($item.name) as a Function"

                    $item.content|out-file $moduleFile -Append
                    
                    $item.functionDetails.functionName.forEach{
                        write-verbose "Adding $_ as functionToExport"
                        $functionsToExport.add($_)
                    }

                }

                'enums' {
                    Write-Information "Processing $($item.name) as a Enum" -tags 'FilesProcessed'
                    write-verbose "Processing $($item.name) as an Enum"

                    if($ExportEnums -and !$NoExternalFiles){
                        write-verbose 'Exporting enum content to external enum file'
                        $item.content|Out-file $enumsFile -Append

                        if($enumsFileShortname -notIn $scriptsToProcess)
                        {
                            $scriptsToProcess.Add($enumsFileShortname)
                        }
                    }else{
                        write-verbose 'Exporting enum content to module file'
                        $item.content|out-file $moduleFile -Append

                    }
                }

                'validationClasses' {
                    Write-Information "Processing $($item.name) as a ValidationClass" -tags 'FilesProcessed'
                    write-verbose "Processing $($item.name) as ValidationClass"

                    if($NoExternalFiles)
                    {
                        write-verbose 'No ExternalFiles flag set'
                        write-warning 'By setting NoExternalFiles with files in the validationClasses folder, you run the risk of your validator class objects not loading correctly.'
                        write-warning 'If your module has DSC Classes, the NoExternalFiles switch will be forced. Avoid using custom validators with DSC Modules for predictable results'
                        write-verbose 'Exporting validator content to external module file'
                        $item.content|out-file $moduleFile -append
                    }else{
                        write-verbose 'Exporting validator content to external validators file'
                        $item.content|Out-file $validatorsFile -Append
                        if($validatorsFileShortname -notIn $scriptsToProcess)
                        {
                            $scriptsToProcess.Add($validatorsFileShortname)
                        }

                    }
                }

                'classes' {
                    Write-Information "Processing $($item.name) as a Class" -tags 'FilesProcessed'
                    write-verbose "Processing $($item.name) as Class"

                    if($ExportClasses -and !$NoExternalFiles){
                        write-verbose 'Exporting classes content to external classes file'
                        $item.content|Out-file $classesFile -Append

                        if($classesFileShortname -notIn $scriptsToProcess)
                        {
                            $scriptsToProcess.Add($classesFileShortname)
                        }

                    }else{
                        write-verbose 'Exporting classes content to external module file'
                        $item.content|out-file $moduleFile -append
                    }

                }

                'private' {
                    Write-Information "Processing $($item.name) as a Private (Non Exported) Function" -tags 'FilesProcessed'
                    write-verbose "Processing $($item.name) as a Private (Non Exported) Function"

                    $item.content|out-file $moduleFile -Append
                }

                Default {
                    write-warning "$($item.group) grouptype is unknown. Uncertain how to handle file: $($item.name). Will be skipped"
                }

            }
        }

        write-verbose 'Finished compiling module file'
        write-verbose "`n`n`n==========================================`n`n"



        foreach($folder in $copyFolders)
        {

            write-verbose "Processing folder for content copy: $folder"

            $fullFolderPath = join-path -path $sourceFolder -ChildPath $folder
            $folderItems = get-mfFolderItems -path $fullFolderPath
            if($folderItems.count -ge 1) #Now we are on PS7 we don't need to worry about measure-object
            {
                write-verbose "$($folderItems.Count) Files found, need to copy"
                $destinationFolder = join-path -path $moduleOutputFolder -childPath $folder
                write-verbose "Destination Path will be: $destinationFolder"
                if(!(test-path $destinationFolder))
                {
                    try{
                        $null = new-item -ItemType Directory -Path $destinationFolder -ErrorAction Stop
                        write-verbose 'Created Destination Folder'
                    }catch{
                        throw "Unable to make directory for: $destinationFolder"
                    }
                }
                #Make null = to suppress the object output
                $null = get-mfFolderItems -path $fullFolderPath -destination $destinationFolder -copy

                Write-Information "Copied $folder, containing $($folderItems.Count) items, to the module" -tags 'FoldersCopied'
            }
        }

        write-verbose 'Building Manifest'
        #Manifest Base
        $splatManifest = @{
            Path = $manifestFile
            RootModule = $moduleFileShortname
            Author = $($config.moduleAuthors -join ',')
            Copyright = "$(get-date -f yyyy)$(if($config.companyName){" $($config.companyName)"}else{" $($config.moduleAuthors -join ' ')"})"
            CompanyName = $config.companyName
            Description = $config.Description
            ModuleVersion = $VersionString
            Guid = $config.guid
            PowershellVersion = $config.minimumPsVersion.tostring()
            CmdletsToExport = [array]@()
        }

        if($ReleaseNotes)
        {
            #Add the release notes if they were included
            $splatManifest.releaseNotes = $ReleaseNotes
            if($IncludeReleaseNotesInDescription)
            {
                $splatManifest.Description = "$($config.Description)`n`n$($ReleaseNotes)"
            }
        }
        #Add the extra bits if present
        #Splatting really doesn't like nulls
        if($config.licenseUri)
        {
            $splatManifest.licenseUri = $config.licenseUri
        }
        if($config.projecturi){
            $splatManifest.projecturi = $config.projecturi
        }
        if($config.tags){
            $splatManifest.tags = $config.tags
        }
        if($config.iconUri){
            $splatManifest.iconUri = $config.iconUri
        }
        if($config.requiredModules){
            $splatManifest.requiredModules = $config.RequiredModules
        }
        if($config.ExternalModuleDependencies){
            $splatManifest.ExternalModuleDependencies = $config.ExternalModuleDependencies
        }
        if($config.DefaultCommandPrefix){
            $splatManifest.DefaultCommandPrefix = $config.DefaultCommandPrefix
        }
        if($config.PrivateData){
            #Recast to a clean hashtable. The value comes back from Import-Clixml as a deserialized hashtable
            #which New-ModuleManifest rejects with 'PrivateData ... must be a hash table' when Tags/ProjectUri/etc are also set
            $splatManifest.PrivateData = [hashtable]$config.PrivateData
        }elseif(!$NoBuildProvenance){
            $splatManifest.PrivateData = @{}
        }
        #ModuleForge build provenance. Added as flat scalar keys (not a nested hashtable) because
        #New-ModuleManifest stringifies a nested hashtable in custom PrivateData to 'System.Collections.Hashtable',
        #losing the values. Scalar keys serialise natively and sit alongside the PSData block the cmdlet generates.
        #These SHA256 hashes match the checksums published on the corresponding ModuleForge GitHub release,
        #so a consumer can verify which ModuleForge build produced this module. Skipped when -NoBuildProvenance is set.
        if(!$NoBuildProvenance)
        {
            $splatManifest.PrivateData.ModuleForgeBuildVersion    = $mfVersion
            $splatManifest.PrivateData.ModuleForgeBuildPsd1SHA256 = $mfPsd1Hash
            $splatManifest.PrivateData.ModuleForgeBuildPsm1SHA256 = $mfPsm1Hash
            $splatManifest.PrivateData.ModuleForgeBuildDate       = $mfBuildDate
        }

        #FunctionsToExport
        if($functionsToExport.count -ge 1)
        {

            write-verbose "Making these functions public: $($functionsToExport.ToArray() -join ',')"
            #I'm not sure why, but the export of this is not an actual array. In the PSD1 it wont have the @(). I tried to force it unsuccessfully
            [array]$splatManifest.FunctionsToExport = [array]$functionsToExport.ToArray()
        }else{
            write-warning 'No public functions'
            [array]$splatManifest.FunctionsToExport = [array]@()
        }

        #If we are exporting any of our enums, classes, validators into the Global Scope, we should do it here.
        # Ideally in the future a module manifest would have ClassesToExport, EnumsToExport - but I'm not gonna hold my breath for that
        if($scriptsToProcess.count -ge 1)
        {
            write-verbose "Scripts to process on module load: $($scriptsToProcess.ToArray() -join ',')"
            $splatManifest.ScriptsToProcess = [array]$scriptsToProcess.ToArray()
        }else{
            write-verbose 'No scripts to process on module load'
        }

        #This block should not trigger right now. Maybe we can add it in if we revisit DSC
        <#
        $DscResourcesToExport
        if($DscResourcesToExport.count -ge 1)
        {
            write-verbose "Included in dscResources: $($DscResourcesToExport.ToArray() -join ',')"
            $splatManifest.DscResourcesToExport = [array]$DscResourcesToExport.ToArray()

        }else{
            write-verbose 'No dsc Resources to include'
        }
        #>

        #Extra Stuff
        if($Version.PreReleaseLabel)
        {
            #Semver supplied had a pre-release label
            write-verbose 'Incrementing Prerelease Version'
            write-verbose "Setting Prerelease tag to: $($Version.PreReleaseLabel)"
            $splatManifest.Prerelease = $Version.PreReleaseLabel
            
        }

        $splatManifest.ModuleVersion = $Version
        New-ModuleManifest @splatManifest
        Write-Information 'Created Module Manifest' -tags 'CreatedModuleManifest'
    }
    
}