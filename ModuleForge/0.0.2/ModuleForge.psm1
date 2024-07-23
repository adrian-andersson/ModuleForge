<#
Module Mixed by BarTender
	A Framework for making PowerShell Modules
	Version: 6.2.0
	Author: Adrian.Andersson
	Copyright: 2020 Domain Group

Module Details:
	Module: ModuleForge
	Description: ModuleForge is a PowerShell scaffolding and build tool for creating other PowerShell modules. With ModuleForge, you can easily generate the foundational structure, boilerplate code, and github actions build techniques
	Revision: 0.0.1.1
	Author: Adrian Andersson
	Company:  

Check Manifest for more details
#>

function build-mfProject
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
        [Parameter(Hidden)]
        [string]$configFile = 'moduleForgeConfig.xml',
        [Parameter()]
        [switch]$exportClasses
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

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
                new-item -ItemType Directory -Path $buildFolder -ErrorAction Stop
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
                new-item -ItemType Directory -Path $moduleOutputFolder -ErrorAction Stop
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


        
        #>



        $scriptsToProcess = New-Object System.Collections.Generic.List[string]
        $functionsToExport = New-Object System.Collections.Generic.List[string]
        $nestedModules = New-Object System.Collections.Generic.List[string]


    }
    
    process{

        write-verbose "Attempt to build: $versionString"



        $moduleFile = join-path $moduleOutputFolder -ChildPath "$($config.moduleName).psm1"
        $manifestFile = join-path $moduleOutputFolder -ChildPath "$($config.moduleName).psd1"
        $classesFile = join-path -path $moduleOutputFolder -ChildPath "$($config.moduleName).classes.ps1"
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
            write-process "Processing folder: $folder"

            $fullFolderPath = join-path -path $sourceFolder -ChildPath $folder
            $folderItems = get-mfFolderItems -path $fullFolderPath -psScriptsOnly
            if($folderItems.count -gt 1) #Now we are on PS7 we don't need to worry about measure-object
            {
                write-verbose "$($folderItems.Count) Files found, getting content"
                
                switch ($folder) {
                    'enums' {
                        write-verbose 'Processing Enums'
                        $content = get-mfScriptText -path $fullFolderPath -scriptType other
                        
                        if($dscResourcesFound)
                        {
                            "`n### Enums`n`n"|Out-File $moduleFile -Append
                            $content.output|Out-File $moduleFile -Append
                        }else{
                            "`n### Enums`n`n"|Out-File $classesFile -Append
                            $content.output|out-file $classesFile -Append
                            if($classesFile -notin $nestedModules)
                            {
                                $nestedModules.Add($classesFile)
                            }
                            if($exportClasses -and $classesFile -notIn $scriptsToProcess)
                            {
                                $scriptsToProcess.Add($enumsFile)
                            }
                        }
                    }
                    'validationClasses' {
                        write-verbose 'Processing validationClasses'
                        $content = get-mfScriptText -path $fullFolderPath -scriptType other

                        if($dscResourcesFound)
                        {
                            "`n### Validation Classes`n`n"|Out-File $moduleFile -Append
                            $content.output|Out-File $moduleFile -Append
                        }else{
                            
                            "`n### Validation Classes`n`n"|Out-File $classesFile -Append
                            $content.output|out-file $classesFile -Append
                            if($classesFile -notin $nestedModules)
                            {
                                $nestedModules.Add($classesFile)
                            }
                        }
                    }
                    'classes' {
                        write-verbose 'Processing classes'
                        $content = get-mfScriptText -path $fullFolderPath -scriptType other

                        if($dscResourcesFound)
                        {
                            "`n### Classes`n`n"|Out-File $moduleFile -Append
                            $content.output|Out-File $moduleFile -Append
                        }else{
                            
                            "`n### Classes`n`n"|Out-File $classesFile -Append
                            $content.output|out-file $classesFile -Append
                            if($classesFile -notin $nestedModules)
                            {
                                $nestedModules.Add($classesFile)
                            }
                            if($exportClasses -and $classesFile -notIn $scriptsToProcess)
                            {
                                $scriptsToProcess.Add($enumsFile)
                            }
                        }
                    }
                    'dscClasses' {
                        write-verbose 'Processing DSCResources'
                        $content = get-mfScriptText -path $fullFolderPath -scriptType dscClass
                        "`n### dscClasses`n`n"|Out-File $moduleFile -Append
                        $content.output|Out-File $moduleFile -Append
                    }

                    'functions'  {
                        #Ok so we need to add the content to the module file
                        write-verbose 'Processing Public Functions'
                        $content = get-mfScriptText -path $fullFolderPath -scriptType function
                        $content.functionResources.foreach{$functionsToExport.add($_)}
                        "`n### Public/Non-Private Functions`n`n"|Out-File $moduleFile -Append
                        $content.output|Out-File $moduleFile -Append
                    }
                    
                    Default {
                        #So Private functions and filters should land in here
                        $content = get-mfScriptText -path $fullFolderPath -scriptType other
                        #Ok so we need to add the content to the module file
                        write-verbose "Processing $folder"
                        $content = get-mfScriptText -path $fullFolderPath -scriptType function
                        $content.functionResources.foreach{$functionsToExport.add($_)}
                        "`n### $folder `n`n"|Out-File $moduleFile -Append
                        $content.output|Out-File $moduleFile -Append
                    }
                }
            }

        }

        write-verbose 'Building Manifest'
        #$config
        $splatManifest = @{
            Path = $manifestFile
            RootModule = $config.name
            Author = $($config.name.moduleAuthors -join ',')
            Copyright = "$(get-date -f yyyy)$(if($companyName){" $($config.companyName)"}else{" $($config.name.moduleAuthors -join ' ')"})"
            CompanyName = $config.companyName
            Description = $config.Description
            ModuleVersion = $versionString
            Guid = $config.guid
            PowershellVersion = $config.minimumPsVersion.tostring()
            FunctionsToExport = if($functionsToExport.count -ge 1){$functionsToExport.ToArray()}else{[array]@()}
            ScriptsToProcess = if($exportClasses -and $scriptsToProcess.count -ge 1){$scriptsToProcess.ToArray()}else{[array]@()}
            NestedModules = if($nestedModules.count -ge 1){$nestedModules.ToArray()}else{[array]@()}
            CmdletsToExport = @()
            AliasesToExport = @()
            VariablesToExport = if($config.tags.count -gt 1){$config.tags}else{$null}
            licenseUri = if($config.licenseUri){$config.licenseUri}else{$null}
            projectUri = if($config.projectUri){$config.projectUri}else{$null}
            #Nested Modules When?
        }
        New-ModuleManifest @splatManifest

    }
    
}

function get-mfFolderItems
{
    <#
        .SYNOPSIS
            Get a list of files from a folder - whilst processing the .mfignore and .mforder files
            
        .DESCRIPTION
             Get the files out of a folder. Adds a bit of smarts to it such as:
             - Ignore anything in the .mfignore file
             - Filter out anything that isn't a PS1 file if, with a switch
             - Ignore files with .test.ps1 - These are assumed to be pester files
             - Ignore files with .skip.ps1 - These are assumed to be skippable

            
           

              Will always return a full path name
            
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
            
                2024-07-22 - AA
                    - Refactored from Bartender
                    
    #>

    [CmdletBinding(DefaultParameterSetName='Default')]
    PARAM(
        #Path to start in. Should be an FQDN
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName ='Default')]
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName ='Copy')]
        [string]$path,
        [parameter(ParameterSetName ='Default')]
        [parameter(ParameterSetName ='Copy')]
        [switch]$psScriptsOnly,
        [parameter(ParameterSetName ='Copy')]
        [string]$destination,
        [parameter(ParameterSetName ='Copy')]
        [switch]$copy

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"


        if($path[-1] -eq '\' -or $path[-1] -eq '/')
        {
            write-verbose 'Removing extra \ or / from path'
            $path = $path.Substring(0,$($path.length-1))
            write-verbose "New Path $path"
        }

        try{
            $folder = get-item $path -erroraction stop
            #Ensure we have the full path
            $folder = $folder.FullName

        }catch{
            throw "Unable to get folder at $path"
        }


        [System.Collections.Generic.List[string]]$excludeList = '.gitignore','.mfignore'


        if($destination)
        {
            if($destination[-1] -eq '\' -or $destination[-1] -eq '/')
            {
                write-verbose 'Removing extra \ or / from destination'
                $path = $path.Substring(0,$($destination.length-1))
                write-verbose "New destination $destination"
            }

            if(!(test-path $destination))
            {
                throw "Unable to resolve destination path: $destination"
            }


        }


        $fileListSelect = @(
            'Name'
            @{
                Name = 'Path'
                Expression = {$_.Fullname}
            }
            'RelativePath'
        )

        $fileListSelect2 = @(
            'Name'
            @{
                Name = 'Path'
                Expression = {$_.Fullname}
            }
            'RelativePath'
            'newPath'
            'newFolder'
        )


        
    }
    
    process{
        

        $mfIgnorePath = join-path -path $folder -childpath '.mfignore'
        if(test-path $mfIgnorePath)
        {
            write-verbose 'Getting ignore list from .mfignore'
            $content = (get-content $mfIgnorePath).where{$_.length -gt 1}
            $content.foreach{
                $excludeList.add($_.tolower())
            }
        }


        write-verbose "Full Exclude List: `n`n$($excludeList|format-list|Out-String)"
        

        


        write-verbose 'Getting Folder files'
        if($psScriptsOnly)
        {
            write-verbose 'Getting PS1 Files'
            $fileList = get-childitem -path $folder -recurse -filter *.ps1|where-object{$_.psIsContainer -eq $false -and $_.name.tolower() -notlike '*.test.ps1' -and $_.name.tolower() -notlike '*.skip.ps1' -and $_.Name.tolower() -notin $excludeList}
        }else{
            write-verbose 'Getting Folder files'
            $fileList = get-childitem -path $folder -recurse |where-object{$_.psIsContainer -eq $false -and $_.name.tolower() -notlike '*.test.ps1' -and $_.name.tolower() -notlike '*.skip.ps1' -and $_.Name.tolower() -notin $excludeList}
        }

        write-verbose 'Add custom member values'
        $fileList.foreach{
            $_|Add-Member -MemberType NoteProperty -Name 'RelativePath' -Value $($_.fullname.ToString()).replace("$($folder)$([IO.Path]::DirectorySeparatorChar)",".$([IO.Path]::DirectorySeparatorChar)")
            if($destination)
            {
                $_|add-member -MemberType NoteProperty -name 'newPath' -Value $($_.fullname.ToString()).replace($folder,$destination)
                $_|Add-Member -name 'newFolder' -memberType NoteProperty -value $($_.directory.ToString()).replace($folder,$destination)
            }
        }

        if($destination)
        {
            if($copy)
            {
                $fileList.foreach{
                    write-verbose "Copy file $($_.relativePath) to $($_.newFolder)"
                    if(!(test-path $_.newFolder))
                    {
                        write-verbose 'Destionation folder does not exist, attempt to create'
                        try{
                            $r = new-item -itemtype directory -path $_.newFolder -force -ErrorAction stop
                            write-verbose "Made new directory at: $($_.newFolder)"
                        }catch{
                            throw "Error making new directory at: $($_.newFolder)"
                        }
                    }
                    try{
                        write-verbose "Copying $($_.relativePath) to $($_.newPath)"
                        $r = copy-item -path ($_.fullname) -destination ($_.newPath) -force
                        write-verbose "Copied $($_.relativePath) to $($_.newFolder)"
                    }catch{
                        throw "Error with Copy: $($_.relativePath) to $($_.newFolder)"
                    }
                    
                }
            }
            $fileList|Select-Object $fileListSelect2
        }else{
            $fileList|Select-Object $fileListSelect
        }
        
    }
    
}

function get-mfScriptText
{

    <#
        .SYNOPSIS
            Get the text from a PS1 file, return it
            
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
        #PARAM DESCRIPTION
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string[]]$path,
        [Parameter()]
        [ValidateSet('function', 'dscClass', 'other')]
        [string]$scriptType = 'function',
        [Parameter()]
        [switch]$force
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $outputObject = @{
            output = [string]''
            functionResources = [System.Collections.Generic.List[string]](New-Object System.Collections.Generic.List[string])
            dscResources =[System.Collections.Generic.List[string]](New-Object System.Collections.Generic.List[string])
        }
        
    }
    
    process{
        foreach($item in $path)
        {
            write-verbose "Processing file: $item"
            $itemDetails = get-item $item
            if(!$itemDetails)
            {
                write-warning "Unable to get details for file: $item. Skipping"
                continue #Stop processing, go to next item
            }
            if($itemDetails.extension -ne '.ps1')
            {
                if(!$force)
                {
                    write-warning "File: $item is not a PS1 file. Skipping. Use -Force switch to ignore these warnings"
                    continue #Stop processing, go to next item
                }else{
                    write-warning "File: $item is not a PS1 file. -Force switch used. Proceeding with Warning"
                }
            }

            $content = get-content $itemDetails.FullName
            write-verbose 'Retrieved Content, Analyising'
            
            switch ($scriptType) {
                'dscClass' {
                    write-verbose 'Analysing as a DSC Class'
                    $lineNo = 1
                    $content.foreach{
                        if($_ -like 'class *')
                        {
                            write-verbose "Found class in: $($item) Line:$lineNo"
                            $className = ($_ -split 'class ')[1]
                            if($className -like '*{*')
                            {
                                #Remove the script-block if it was appended to the function line
                                $className = $($className -split '{')[0]
                            }
                            $className = $className.trim()
                            write-verbose "Adding $className to exportable dscResources"
                            $outputObject.dscResources.Add($className)

                        }

                        $lineNo++
                    }
                }
                'function' {
                    write-verbose 'Analysing as a Function file'
                    $lineNo = 1
                    $content.foreach{
                        if($_ -like 'function *')
                        {
                            write-verbose "Found Function in: $($item) Line:$lineNo"
                            $functionName = ($_ -split 'function ')[1]
                            #write-verbose "fnameBase: $functionName"
                            if($functionName -like '*{*')
                            {
                                #Remove the script-block if it was appended to the function line
                                $functionName = $($functionName -split '{')[0]
                            }
                            if($functionName -like '*(*')
                            {
                                #If we are dealing with a non-advanced powershell function, handle that as well
                                $functionName = $($functionName -split '(')[0]
                            }
                            $functionName = $functionName.trim()
                            write-verbose "Adding $functionName to exportable function resources"
                            $outputObject.functionResources.Add($functionName)
                        }

                        $lineNo++
                    }
                }
                default {
                    #write-verbose 'Analysing as Other file'
                }
                
            }
            write-verbose "Add content of $item"
            $outputObject.output = "$($outputObject.output)`n`n#FromFile: $($itemDetails.name)`n`n`n$($content|out-string)"
        }

        [PSCustomObject]$outputObject
        
    }
    
}

function new-mfProject
{

    <#
        .SYNOPSIS
            Capture some basic parameters, and create the scaffold file structure
            
        .DESCRIPTION
        The new-mfProject function streamlines the process of creating a scaffold (or basic structure) for a new PowerShell module.
        Whether you’re building a custom module for automation, administration, or any other purpose, this function sets up the initial directory structure, essential files, and variables and properties.
        Think of it as laying the foundation for your module project.
            
        ------------
        .EXAMPLE
            new-mfProject
            
            #### DESCRIPTION
            Line by line of what this example will do
            
            
            #### OUTPUT
            Copy of the output of this line
            
            
            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                2024-07-22 - AA
                    - Refactored from Bartender
                    
    #>

    [CmdletBinding()]
    PARAM(
        #The name of your module
        [Parameter(Mandatory)]
        [string]$ModuleName,
        #A description of your module. Is used as the descriptor in the module repository
        [Parameter(Mandatory)]
        [string]$description,
        #Minimum PowerShell version. Defaults to 7.2 as this is the current LTS version
        [Parameter()]
        [version]$minimumPsVersion = [version]::new('7.2.0'),
        #Who are the primary module authors. Can expand later with add-mfmoduleAuthors command
        [Parameter()]
        [string[]]$moduleAuthors,
        #Company Name. If you are building this module for your organisation, this is where it goes
        [Parameter()]
        [string]$companyName,
        #Module Tags. Used to help discoverability and compatibility in package repositories
        [Parameter()]
        [String[]]$moduleTags,
        #Root path of the module. Uses the current working directory by default
        [string]$modulePath = $(get-location).path,
        #Project URI. Will try and read from Git if your using a git repository.
        [Parameter()]
        [string]$projectUri = (try{git config remote.origin.url}catch{$null}),
        #URI to use for your projects license. Will try and use the license file if a projectUri is found
        [Parameter()]
        [string]$licenseUri,
        [Parameter(Hidden)]
        [string]$configFile = 'moduleForgeConfig.xml'

        #ToDo Later: Add Required Modules.




    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"


        #I'm not sure why I had this in here. Cannot remember.
        if($modulePath -like '*\' -or $modulePath -like '*/' )
        {
            Write-Verbose 'Superfluous \ or / character found at end of modulePath, removing'
            $modulePath = $modulePath.Substring(0,$($modulePath.Length-1))
            Write-Verbose "New path = $modulePath"
        }

        $configPath = join-path -path $modulePath -childpath $configFile

    }
    
    process{

        write-verbose 'Validating Module Path'
        if(!(test-path $modulePath))
        {
            throw "ModulePath: $modulePath not found"
        }

        write-verbose 'Checking for Existing Config'
        if(test-path $configPath)
        {
            throw "Config already found at: $configPath"
        }


        write-verbose 'Create Folder Scaffold'
        add-mfFilesAndFolders

       

        if($projectUri -and !$licenseUri)
        {
            if(test-path $(join-path -path $modulePath -childPath 'LICENSE'))
            {
                $licenseUri = "$projectUri\LICENSE"
            }
        }

        #Should we use JSON for this, or CLIXML.
        #The vote from the internet in July 2024 is stick to CLIXML for PowerShell centric projects. So we will do that
        write-verbose 'Create config file'
        $config = [psCustomObject]@{
            #The params set from this function
            moduleName = $ModuleName
            description = $description
            minimumPsVersion = $minimumPsVersion
            moduleAuthors = [array]$moduleAuthors
            companyName = $companyName
            tags = [array]$moduleTags
            #Some automatic variables
            projectUri = $projectUri
            licenseUri = $licenseUri
            guid = $(new-guid).guid
            moduleforgeVersion = $($mf = (get-module -listavailable microsoft.graph.*|Sort-Object version -Descending|Select-Object -First 1);if($mf){$mf.version})
        }

        write-verbose "Exporting config to: $configPath"
        try{
            $config|export-clixml $configPath
        }catch{
            throw 'Error exporting config'
        }
    }
}


function add-mfFilesAndFolders
{

    <#
        .SYNOPSIS
            Add the file and folder structure required by moduleForge
            
        .DESCRIPTION
            Create the folder structure as a scaffold,
            If a folder does not exist, create it.

            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                2024-07-22 - AA
                    - Refactored from Bartender
                    - Tried to make Operating Agnostic by using join-path
                    
    #>

    [CmdletBinding()]
    PARAM(
        #Root Path for module folder. Assume current working directory
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string]$moduleRoot = (Get-Item .).FullName #Use the fullname so that we don't have problems with PSDrive, symlinks, confusing bits etc
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $rootDirectories = @('documentation','source')
        $sourceDirectories = @('functions','enums','classes','filters','dscClasses','validationClasses','private','bin')
        $emptyFiles = @('.gitignore','.mfignore')
        
        
    }
    
    process{
        write-verbose 'Verifying base folder structure'
        
        

        $rootDirectories.foreach{
            $fullPath = Join-Path -path $moduleRoot -ChildPath $_
            if(test-path $fullPath)
            {
                write-verbose "Directory: $fullpath is OK"
            }else{
                write-warning "Directory: $fullpath not found. Will create"
                try{
                    $result = new-item -itemtype directory -Path $fullPath -ErrorAction Stop
                }catch{
                    throw "Unable to make new directory: $result. Please check permissions and conflicts"
                }
                
            }

            if($_ -eq 'source')
            {
                write-verbose 'Checking for subdirectories and files in source folder'
                $sourceDirectories.foreach{
                    $subdirectoryFullPath = join-path path $fullPath -childPath $_
                    if(test-path $subdirectoryFullPath)
                    {
                        write-verbose "Directory: $subdirectoryFullPath is OK"
                    }else{
                        write-warning "Directory: $subdirectoryFullPath not found. Will create"
                        try{
                            $result = new-item -itemtype directory -Path $subdirectoryFullPath -ErrorAction Stop
                        }catch{
                            throw "Unable to make new directory: $subdirectoryFullPath. Please check permissions and conflicts"
                        }
                        
                    }
                    $emptyFiles.ForEach{
                        $filePath = join-path $subdirectoryFullPath -childPath $_
                        if(test-path $filePath)
                        {
                            write-verbose "File: $filePath is OK"
                        }else{
                            write-warning "File: $filePath not found. Will create"
                            try{
                                $result = new-item -itemtype File -Path $filePath -ErrorAction Stop
                            }catch{
                                throw "Unable to make new directory: $filePath. Please check permissions and conflicts"
                            }
                            
                        }

                    }

                }

            }
        }
        
    }
    
}

function get-mfScriptFunctionNames
{

    <#
        .SYNOPSIS
            Retrieves the names of powershell functions from PowerShell script files.
            
        .DESCRIPTION
            Basically, a get-command type function for scripts you haven't dotSourced or imported yet.
            
        ------------
        .EXAMPLE
            get-mfScriptFunctionNames example.ps1
            
            #### DESCRIPTION
            Get the names of any functions in the example.ps1 file           
            
            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                2024-07-22 - AA
                    - Recreated from bartender
                    - Added more verbosity
                    - Simplified
                    - Added extension checks
                    
    #>

    [CmdletBinding()]
    PARAM(
        #PS1 / PowerShell Script file to check
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string]$path,
        #Ignore extension name
        [Parameter()]
        [switch]$ignoreFileExtension
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $powershellExtensions = @(
            '.ps1'
            '.psm1'
        )
        
    }
    
    process{
        $item = get-item $path
        
        if(test-path $item)
        {
            write-verbose "Found item at $path"

            if($item.extension -notin $powershellExtensions)
            {
                if(!$ignoreFileExtension)
                {
                    Throw 'File extension is not a PowerShell script filefile'
                }else{
                    write-warning 'File extension is not a PowerShell file. Ignore switch supplied so proceeding with warning'
                }
            }
            write-verbose 'Reading contents and finding function names'
            $contents = get-contents $item
            $contents.foreach{
                if($_ -like 'function *')
                {
                    write-verbose 'Function Found'
                    $($_ -split 'function ')[0]
                }
            }
        }else{
            throw "Error finding file: $path"
        }        
    }
}

