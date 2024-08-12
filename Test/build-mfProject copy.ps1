function build-mfProject
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
            build-mfProject -version '0.12.2-prerelease.1'
            
            #### DESCRIPTION
            Make a PowerShell module from the current folder, and mark it as a pre-release version
            
            
            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                2024-07-26 - AA
                    - Refactored from Bartender
                    - Added necessary joining functions
                    - Minimum Parameters
                    - Test with no externals
                
                2024-07-29 - AA
                    - Test with all classes,enums,validators as external
                    - Revert to just Validators as external after testing
                    - Expand parameters
                    - Make Pre-release work
                    - Decided that short-term, DSC modules are not supported

                2024-08-12 - AA
                    - Change the way we handle prereleases, get it from the supplied semver
                        - Will allow easier passing through of get-mfNextSemver output
                    - Change the way we get script details
                    
    #>

    [CmdletBinding()]
    PARAM(
        #What version are we building?
        [Parameter(Mandatory)]
        [semver]$version,
        #Root path of the module. Uses the current working directory by default
        [Parameter()]
        [string]$modulePath = $(get-location).path,
        [Parameter(DontShow)]
        [string]$configFile = 'moduleForgeConfig.xml',
        #Use this flag to put any classes in ScriptsToProcess
        [Parameter()]
        [switch]$exportClasses,
        #Use this flag to put any enums in ScriptsToProcess
        [Parameter()]
        [switch]$exportEnums,
        #Use this flag to put any validators in ScriptsToProcess
        [Parameter()]
        [switch]$exportValidators,
        #Use this to not put anything in nestedmodules, making everything a single file. By default validators are put in a separate nestedmodule script to ensure they are loaded properly
        [Parameter()]
        [switch]$noExternalFiles

        
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        write-verbose 'Testing module path'
        $moduleTest = get-item $modulePath
        if(!$moduleTest){
            throw "Unable to read from $modulePath"
        }

        $modulePath = $moduleTest.FullName
        write-verbose "Building from: $modulePath"

        #Read the config file
        write-verbose 'Importing config file'
        $configPath = join-path -path $modulePath -ChildPath $configFile

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
        $versionString = $version.tostring()


        #Ok so we need:
        # - A folder to build in
        # - Build folder will need a subfolder named after the module
        # - That subfolder then needs a version name? Or does it?
        # - For now, put into build folder, actual versions should be handled in a package repository or copied to a storage location
        write-verbose 'Checking for a build and module folder'
        $buildFolder = join-path -path $modulePath -childPath 'build'
        if(!(test-path $buildFolder))
        {
            write-verbose "Build folder not found at: $($buildFolder), creating"
            try{
                #Save to var to loose the output
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
            write-verbose "Module folder not found at: $($moduleOutputFolder), need to replace"
            try{
                remove-item $moduleOutputFolder -force -Recurse
                start-sleep -Seconds 2
                #Save to var to loose the output. More efficient than |out-null
                $null = new-item -ItemType Directory -Path $moduleOutputFolder -ErrorAction Stop
            }catch{
                throw 'Unable to recreate Module folder'
            }
        }


        $moduleForgeDetails = (get-module 'ModuleForge' |Sort-Object -Property Version -Descending|select-object -First 1)
        if($moduleForgeDetails)
        {
            $mfVersion = $moduleForgeDetails.version.tostring()
        }else{
            $mfVersion = 'unknown'
        }

        $moduleHeader = "<#`nModule created by ModuleForge`n`t ModuleForge Version: $mfVersion`n`tBuildDate: $(get-date -format s)`n#>"


        #Reference to source folders, and specific order
       
        #Better Order
        [array]$folders = @('enums','validationClasses','classes','dscClasses','functions','private','filters')


        $sourceFolder = join-path -path $modulePath -childPath 'source'

        <# THIS NEEDS TO MOVE OUT OF A COMMENT BLOCK: IT CAN LIVE HERE FOR NOW
        Ok so what do we need to achieve here? 
            - If DSC Resources are involved, scripts to process doesn't happen and nested modules don't load in time
                - Since Enums are critical for DSC Resources, they need to go at the top of the module
            - If NO DSC resources are involved, then Classes, Enums etc need to load first
                - Doing this with ScriptsToProcess makes them available on the terminal scope, but not in the module scope.
                - Doing this in the module file works, but also does not expose outside the module scope
                - Doing this with nested-modules works mostly the same as putting in the module file - makes it available on the module-scope, but not the terminal scope.
                - Doing it in both ScriptsToProcess and nested-modules fixes both scenarios, and means there is no duplicated code.
                - This is how we did it in Bartender, but now I think it's not the best way
                - Doing it in both the Module file AND the scriptstoprocess _IF REQUIRED_ might be the best approach

            - OK Testing things and now I think, as per this https://stackoverflow.com/questions/31051103/how-to-export-a-class-in-a-powershell-v5-module
                - Add a switch to export functions
                - Add all the enums, validations, classes etc to a separate file
                - Add those as part of nestedModules together
                - IF the switch is set, also export to scriptsToProcess and save the files there

            - Ok Further Testing
                - Seems like nestedModules is also hit/miss
                - Keep the same, but export to the main psm1 file as well, and don't worry about nested modules

            - OK so VALIDATOR CLASSES
                - Seems like keeping them in the module results in an error, pretty much this one: https://github.com/PowerShell/PowerShell/issues/1762
                - I _believe_ putting these in a nested module will work though
                - This seems to work, but I would NOT recommend using this with dsc modules


            - ENUMS
                - Seems like the module will _NOT_ import correctly _if_ the ENUMS are loaded in a nested module
                - This is so very frustrating, and counter to how VALIDATORS work.
                - Putting them in the base module works... But then how do we test? Maybe we don't need to, they will abstractly be tested otherwise

            - New Theory
                - Loading more than 1 NestedModule causes problems
        
        #>

        #What folders do we need to copy the files directly in
        [array]$copyFolders = @('resource','bin')

        $scriptsToProcess = New-Object System.Collections.Generic.List[string]
        $functionsToExport = New-Object System.Collections.Generic.List[string]
        $nestedModules = New-Object System.Collections.Generic.List[string]

        $DscResourcesToExport = New-Object System.Collections.Generic.List[string]

        $fileList = New-Object System.Collections.Generic.List[string]


    }
    
    process{

        write-verbose "Attempt to build: $versionString"

        #References for our manifest and module root
        $moduleFileShortname = "$($config.moduleName).psm1"
        $moduleFile = join-path $moduleOutputFolder -ChildPath $moduleFileShortname
        $fileList.Add($moduleFileShortname)
        $manifestFileShortname = "$($config.moduleName).psd1"
        $manifestFile = join-path $moduleOutputFolder -ChildPath $manifestFileShortname
        $fileList.Add($manifestFileShortname)

        write-verbose "Will create module in: $moduleOutputFolder; Module Filename: $moduleFile ; Manifest Filename: $manifestFileShortname "

        #References for external files, if needed
        $classesFileShortname = "$($config.moduleName).Classes.ps1"
        $classesFile = join-path -path $moduleOutputFolder -ChildPath $classesFileShortname


        $validatorsFileShortname = "$($config.moduleName).Validators.ps1"
        $validatorsFile = join-path -path $moduleOutputFolder -ChildPath $validatorsFileShortname

        $validatorsFileShortname = "$($config.moduleName).Validators.ps1"
        $validatorsFile = join-path -path $moduleOutputFolder -ChildPath $validatorsFileShortname

        $enumsFileShortname = "$($config.moduleName).Enums.ps1"
        $enumsFile = join-path -path $moduleOutputFolder -ChildPath $enumsFileShortname

        
        #Start creating the moduleFile
        write-verbose 'Adding Header'
        $moduleHeader|out-file $moduleFile -Force


        
        #Do a check for DSC Resources because they change how we handle everything
        #Actually, for now lets not worry about DesiredStateConfig, 
        # - its a bit broken as of July 2024,
        # - It changes how we build modules because nestedmodules, scriptstoprocess dont work (From previous experience)
        # - I don't have any need to build DSC resources at this time, so my testing will be limited
        # - DSC Resources are being reworked by MicroSoft so this is a moving target at the moment 
        write-verbose 'Checking for DSC Resources. DSC Resources add nuance to module build'
        $dscResourcesFolder = join-path -path $sourceFolder -ChildPath 'dscClasses'
        $dscResourceFiles = get-mfFolderItems -path $dscResourcesFolder -psScriptsOnly
        if($dscResourceFiles.count -ge 1)
        {
            write-warning 'DSC Resources Found - Ignoring Export Switches and Compiling to single module file'
            #See above comments
            throw 'DSC is not supported in this version of moduleForge. Its on the roadmap'
            $noExternalFiles = $true
        }else{
            write-verbose 'No DSC Resources found'
        }

        #Start getting our data
        foreach($folder in $folders)
        {
            write-verbose "Processing folder: $folder"

            $fullFolderPath = join-path -path $sourceFolder -ChildPath $folder
            $folderItems = get-mfFolderItems -path $fullFolderPath -psScriptsOnly
            if($folderItems.count -ge 1) #Now we are on PS7 we don't need to worry about measure-object
            {
                write-verbose "$($folderItems.Count) Files found, getting content"

                #Primarily done for DSC, which we don't care about at the moment anyway
                #But its nice to have options, and something to revisit later
                if($noExternalFiles){
                    write-warning 'Compiling into single file'
                    switch ($folder) {
                        
                        'dscClasses' {
                            write-verbose 'Processing DSCResources'
                            "`n### dscClasses`n`n"|Out-File $moduleFile -Append
                            $folderItems.ForEach{
                                $content = get-mfScriptText -path $_.Path -scriptType dscClass
                                $content.output|Out-File $moduleFile -Append
                                foreach($dr in $content.dscResources)
                                {
                                    write-verbose "Need to export function: $dr"
                                    $DscResourcesToExport.add($dr)
                                }

                                
                            }
                        }
    
                        'functions'  {
                            #Ok so we need to add the content to the module file
                            write-verbose 'Processing Public Functions'
                            
                            
                            "`n### Public/Non-Private Functions`n`n"|Out-File $moduleFile -Append
                            $folderItems.ForEach{
                                #write-verbose "Getting content for $($_.name)"
                                $content = get-mfScriptText -path $_.Path -scriptType function
                                #$global:dbgContent = $content
                                $content.output|Out-File $moduleFile -Append
                                foreach($fr in $content.functionResources)
                                {
                                    write-verbose "Need to export function: $fr"
                                    $functionsToExport.add($fr)
                                }
                            }
                        }
                        
                        Default {
                            #So Private functions and filters should land in here
                            #In theory we can do all the file types except functions and DSC Resources here (Which need to add to export)
                            #Since we are not exposing them in nested modules or scriptsToProcess
                            
                            write-verbose "Processing $folder"
                            
                            "`n### $folder `n`n"|Out-File $moduleFile -Append
                            $folderItems.ForEach{
                                write-verbose "$($folder): Getting content for $($_.name)"
                                $content = get-mfScriptText -path $_.Path -scriptType other
                                $content.output|Out-File $moduleFile -Append
                            }
                        }
                    }

                }else{
                    write-verbose 'No DSC Resources Found - Compiling Normally'
                    switch ($folder) {
                        'enums' {
                            # I tried putting the ENUMS in there own file, but it cant find the types when you do that
                            write-verbose 'Processing Enums'
                            "`n### Enums`n`n"|Out-File $moduleFile -Append
                            #"`n### Enums`n`n"|Out-File $enumsFile -Append
                            $folderItems.ForEach{
                                $content = get-mfScriptText -path $_.Path -scriptType other
                                $content.output|Out-File $moduleFile -Append
                                #$content.output|Out-file $enumsFile -Append
                                <#
                                if($enumsFileShortname -notIn $nestedModules)
                                {
                                    $nestedModules.Add($enumsFileShortname)
                                }
                                #>
                                if($exportEnums){
                                    if($enumsFileShortname -notIn $scriptsToProcess)
                                    {
                                        $content.output|Out-file $enumsFile -Append
                                        $scriptsToProcess.Add($enumsFileShortname)
                                    }

                                    if($enumsFileShortname -notIn $fileList)
                                    {
                                        $fileList.Add($enumsFileShortname)
                                    }
                                }
                            }
                        }
                        'validationClasses' {
                            # Validators seem to have the opposite behaviour to ENUMS - If they arent in nested module, they dont load in time
                            write-verbose 'Processing validationClasses'
    
                           "`n### Validation Classes`n`n"|Out-File $validatorsFile -Append
    
                            $folderItems.ForEach{
                                $content = get-mfScriptText -path $_.Path -scriptType other
                                $content.output|Out-File $validatorsFile -Append
                                if($validatorsFileShortname -notIn $nestedModules)
                                {
                                    $nestedModules.Add($validatorsFileShortname)
                                }
                                if($exportValidators -and $validatorsFileShortname -notIn $scriptsToProcess){
                                    $scriptsToProcess.Add($validatorsFileShortname)
                                }

                                if($validatorsFileShortname -notIn $fileList)
                                {
                                    $fileList.Add($validatorsFileShortname)
                                }
                            }
                        }
                        'classes' {
                            # Classes could probably be external, but lets treat them the same as enums
                            write-verbose 'Processing Classes'
                            #"`n### Classes`n`n"|Out-File $classesFile -Append
                            "`n### Classes`n`n"|Out-File $moduleFile -Append
                            $folderItems.ForEach{
                                $content = get-mfScriptText -path $_.Path -scriptType other
                                #$content.output|Out-File $classesFile -Append
                                $content.output|Out-File $moduleFile -Append
                                <#
                                if($classesFileShortname -notIn $nestedModules)
                                {
                                    $nestedModules.Add($classesFileShortname)
                                }
                                #>
                                if($exportClasses){
                                    $content.output|Out-File $classesFile -Append
                                    if($classesFileShortname -notIn $scriptsToProcess)
                                    {
                                        $scriptsToProcess.Add($classesFileShortname)
                                    }

                                    if($classesFileShortname -notIn $fileList)
                                    {
                                        $fileList.Add($classesFileShortname)
                                    }
                                }
                            }
                        }
    
                        'functions'  {
                            #Ok so we need to add the content to the module file
                            write-verbose 'Processing Public Functions'
                            
                            
                            "`n### Public/Non-Private Functions`n`n"|Out-File $moduleFile -Append
                            $folderItems.ForEach{
                                #write-verbose "Getting content for $($_.name)"
                                $content = get-mfScriptText -path $_.Path -scriptType function
                                #$global:dbgContent = $content
                                $content.output|Out-File $moduleFile -Append
                                foreach($fr in $content.functionResources)
                                {
                                    write-verbose "Need to export function: $fr"
                                    $functionsToExport.add($fr)
                                }
                            }
                        }
                        
                        Default {
                            #So Private functions and filters should land in here
                            write-verbose "Processing $folder"
                            
                            "`n### $folder `n`n"|Out-File $moduleFile -Append
                            $folderItems.ForEach{
                                write-verbose "$($folder): Getting content for $($_.name)"
                                $content = get-mfScriptText -path $_.Path -scriptType other
                                $content.output|Out-File $moduleFile -Append
                            }
                        }
                    }
                }
                
                
            }

        }

        foreach($folder in $copyFolders)
        {
            write-verbose "Processing folder: $folder"

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

                <# Ideally we add all the copied items to the filelist param in the module manifest
                #But since we are putting them in a child folder, I've got concerns
                #Like the relativename is there, and it works, but the folder divider wont be a \ on non-windows
                #Probably safer to leave this out for the time being
                # Also worth noting, I don't think I've ever seen a manifest have a file list


                $folderItems.ForEach{
                    if($_.name -notIn $fileList)
                    {
                        $fileList.Add($_.name)
                    }
                }
                #>

                
            }
        }


        write-verbose 'Building Manifest'
        #Manifest Base
        $splatManifest = @{
            Path = $manifestFile
            RootModule = $moduleFileShortname
            Author = $($config.name.moduleAuthors -join ',')
            Copyright = "$(get-date -f yyyy)$(if($config.companyName){" $($config.companyName)"}else{" $($config.name.moduleAuthors -join ' ')"})"
            CompanyName = $config.companyName
            Description = $config.Description
            ModuleVersion = $versionString
            Guid = $config.guid
            PowershellVersion = $config.minimumPsVersion.tostring()
            CmdletsToExport = [array]@()
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
            $splatManifest.PrivateData = $config.PrivateData
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

        #See my comment in on validators in the switch statement
        if($nestedModules.count -ge 1)
        {
            write-verbose "Included in modulesToProcess: $($nestedModules.ToArray() -join ',')"
            [array]$splatManifest.NestedModules = [array]$nestedModules.ToArray()

        }else{
            write-verbose 'Nothing to include in modulesToProcess'
        }

        #This block should not trigger right now
        $DscResourcesToExport
        if($DscResourcesToExport.count -ge 1)
        {
            write-verbose "Included in dscResources: $($DscResourcesToExport.ToArray() -join ',')"
            $splatManifest.DscResourcesToExport = [array]$DscResourcesToExport.ToArray()

        }else{
            write-verbose 'No dsc Resources to include'
        }

        #Extra Stuff
        if($version.PreReleaseLabel)
        {
            #Semver supplied had a pre-release label
            write-verbose 'Incrementing Prerelease Version'
            #$preReleaseSplit = $version.PreReleaseLabel.Split('.')
            #$preReleaseLabel = $currentPreReleaseSplit[0]
            
            write-verbose "Setting Prerelease tag to: $($version.PreReleaseLabel)"

            $splatManifest.Prerelease = $version.PreReleaseLabel
            
        }

        $splatManifest.ModuleVersion = $version

        #Currently not adding anything to file list, will leave this code here in case we revisit later
        if($fileList.count -ge 1)
        {
            write-verbose "Included in fileList: $($fileList.ToArray() -join ',')"
            [array]$splatManifest.fileList = [array]$fileList.ToArray()
        }

        New-ModuleManifest @splatManifest

    }
    
}