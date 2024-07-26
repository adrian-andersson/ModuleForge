function build-mfProjectAlt
{

    <#
        .SYNOPSIS
            Simple description
            
        .DESCRIPTION
            Detailed Description
            
        ------------
        .EXAMPLE
            verb-noun param1
            
            #### DESCRIPTION
            Line by line of what this example will do
            
            
            #### OUTPUT
            Copy of the output of this line
            
            
            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                yyyy-mm-dd - AA
                    - Changed x for y
                    
    #>

    [CmdletBinding()]
    PARAM(
        #What version are we building?
        [Parameter()]
        [version]$version = [version]::new('0.0.1'),
        #Root path of the module. Uses the current working directory by default
        [string]$modulePath = $(get-location).path,
        [Parameter(DontShow)]
        [string]$configFile = 'moduleForgeConfig.xml',
        [Parameter()]
        [switch]$exportClasses
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
        write-verbose 'Checking for a build and module folder'
        $buildFolder = join-path -path $modulePath -childPath 'build'
        if(!(test-path $buildFolder))
        {
            write-verbose "Build folder not found at: $($buildFolder), creating"
            try{
                #Save to var to loose the output
                $r = new-item -ItemType Directory -Path $buildFolder -ErrorAction Stop
            }catch{
                throw 'Unable to create build folder'
            }
        }



        $moduleOutputFolder = join-path -path $buildFolder -ChildPath $($config.moduleName)

        if(!(test-path $moduleOutputFolder))
        {
            write-verbose "Module folder not found at: $($moduleOutputFolder), creating"
            try{
                new-item -ItemType Directory -Path $moduleOutputFolder -ErrorAction Stop
            }catch{
                throw 'Unable to create Module folder'
            }
        }else{
            write-verbose "Module folder not found at: $($moduleOutputFolder), need to replace"
            try{
                remove-item $moduleOutputFolder -force -Recurse
                start-sleep -Seconds 2
                #Save to var to loose the output
                $r = new-item -ItemType Directory -Path $moduleOutputFolder -ErrorAction Stop
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
        #[array]$folders = @('enums','functions','filters','validationClasses','dscClasses','classes','private')
       
        #Better Order
        [array]$folders = @('enums','validationClasses','classes','dscClasses','functions','private','filters')


        $sourceFolder = join-path -path $modulePath -childPath 'source'

        <#
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

        
        #>



        $scriptsToProcess = New-Object System.Collections.Generic.List[string]
        $functionsToExport = New-Object System.Collections.Generic.List[string]
        $nestedModules = New-Object System.Collections.Generic.List[string]


    }
    
    process{

        write-verbose "Attempt to build: $versionString"


        $moduleFileShortname = "$($config.moduleName).psm1"
        $moduleFile = join-path $moduleOutputFolder -ChildPath $moduleFileShortname
        $manifestFile = join-path $moduleOutputFolder -ChildPath "$($config.moduleName).psd1"
        $classesFileShortname = "$($config.moduleName).classes.ps1"
        $classesFile = join-path -path $moduleOutputFolder -ChildPath $classesFileShortname
        write-verbose "Will create module in: $moduleOutputFolder; Module Filename: $($config.moduleName).psm1; Manifest Filename:$($config.moduleName).psd1"

        write-verbose 'Adding Header'
        $moduleHeader|out-file $moduleFile -Force


        

        write-verbose 'Checking for DSC Resources. DSC Resources add nuance to module build'
        $dscResourcesFolder = join-path -path $sourceFolder -ChildPath 'dscClasses'
        $dscResourceFiles = get-mfFolderItems -path $dscResourcesFolder -psScriptsOnly
        if($dscResourceFiles.count -ge 1)
        {
            write-warning 'DSC Resources Found'
            $dscResourcesFound = $true
        }else{
            write-verbose 'No DSC Resources found'
            $dscResourcesFound = $false
        }

        foreach($folder in $folders)
        {
            write-verbose "Processing folder: $folder"

            $fullFolderPath = join-path -path $sourceFolder -ChildPath $folder
            $folderItems = get-mfFolderItems -path $fullFolderPath -psScriptsOnly
            if($folderItems.count -ge 1) #Now we are on PS7 we don't need to worry about measure-object
            {
                write-verbose "$($folderItems.Count) Files found, getting content"
                
                switch ($folder) {
                    'enums' {
                        write-verbose 'Processing Enums'
                        if($dscResourcesFound)
                        {
                            "`n### Enums`n`n"|Out-File $moduleFile -Append
                            $folderItems.ForEach{
                                $content = get-mfScriptText -path $_.Path -scriptType other
                                $content.output|Out-File $moduleFile -Append
                            }
                        }else{
                            "`n### Enums`n`n"|Out-File $classesFile -Append
                            $folderItems.ForEach{
                                $content = get-mfScriptText -path $_.Path -scriptType other
                                $content.output|Out-File $classesFile -Append
                            }

                            if($classesFileShortname -notin $nestedModules)
                            {
                                $nestedModules.Add($classesFileShortname)
                            }
                            if($exportClasses -and $classesFileShortname -notIn $scriptsToProcess)
                            {
                                $scriptsToProcess.Add($classesFileShortname)
                            }
                        }
                    }
                    'validationClasses' {
                        write-verbose 'Processing validationClasses'

                        if($dscResourcesFound)
                        {
                            "`n### Validation Classes`n`n"|Out-File $moduleFile -Append

                            $folderItems.ForEach{
                                $content = get-mfScriptText -path $_.Path -scriptType other
                                $content.output|Out-File $moduleFile -Append
                            }
                        }else{
                            
                            "`n### Validation Classes`n`n"|Out-File $classesFile -Append
                            $folderItems.ForEach{
                                $content = get-mfScriptText -path $_.Path -scriptType other
                                $content.output|Out-File $classesFile -Append
                            }
                            if($classesFileShortname -notin $nestedModules)
                            {
                                $nestedModules.Add($classesFileShortname)
                            }
                        }
                    }
                    'classes' {
                        write-verbose 'Processing classes'

                        if($dscResourcesFound)
                        {
                            "`n### Classes`n`n"|Out-File $moduleFile -Append
                            $folderItems.ForEach{
                                $content = get-mfScriptText -path $_.Path -scriptType other
                                $content.output|Out-File $moduleFile -Append
                            }
                        }else{
                            
                            "`n### Classes`n`n"|Out-File $classesFile -Append
                            $folderItems.ForEach{
                                $content = get-mfScriptText -path $_.Path -scriptType other
                                $content.output|Out-File $classesFile -Append
                            }
                            if($classesFileShortname -notin $nestedModules)
                            {
                                $nestedModules.Add($classesFileShortname)
                            }
                            if($exportClasses -and $classesFileShortname -notIn $scriptsToProcess)
                            {
                                $scriptsToProcess.Add($classesFileShortname)
                            }
                        }
                    }
                    'dscClasses' {
                        write-verbose 'Processing DSCResources'
                        $content = get-mfScriptText -path $fullFolderPath -scriptType dscClass
                        "`n### dscClasses`n`n"|Out-File $moduleFile -Append
                        $folderItems.ForEach{
                            $content = get-mfScriptText -path $_.Path -scriptType other
                            $content.output|Out-File $moduleFile -Append
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
                        #Ok so we need to add the content to the module file
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

        write-verbose 'Building Manifest'
        #$config
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
            #FunctionsToExport = if($functionsToExport.count -ge 1){$functionsToExport.ToArray()}else{[array]@()}
            #ScriptsToProcess = if($exportClasses -and $scriptsToProcess.count -ge 1){$scriptsToProcess.ToArray()}else{[array]@()}
            #NestedModules = if($nestedModules.count -ge 1){$nestedModules.ToArray()}else{[array]@()}
            #Nested Modules When?
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

        #FunctionsToExport
        if($functionsToExport.count -ge 1)
        {

            write-verbose "Making these functions public: $($functionsToExport.ToArray() -join ',')"
            $splatManifest.FunctionsToExport = $functionsToExport.ToArray()
        }else{
            write-warning 'No public functions'
            $splatManifest.FunctionsToExport = [array]@()
        }

        #ScriptsToProcess
        if($exportClasses -and $scriptsToProcess.count -ge 1)
        {
            write-verbose "Scripts to process on module load: $($scriptsToProcess.ToArray() -join ',')"
            $splatManifest.ScriptsToProcess = $scriptsToProcess.ToArray()
        }else{
            write-verbose 'No scripts to process on module load'
        }

        #Nested Modules
        if($nestedModules.count -ge 1)
        {
            write-verbose "Included in modulesToProcess: $($nestedModules.ToArray() -join ',')"
            $splatManifest.NestedModules = $nestedModules.ToArray()

        }else{
            write-verbose 'Nothing to include in modulesToProcess'
        }

        New-ModuleManifest @splatManifest

    }
    
}