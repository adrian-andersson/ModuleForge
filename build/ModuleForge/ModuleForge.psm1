<#
Module created by ModuleForge
	 ModuleForge Version: 1.2.0
	BuildDate: 2025-07-13T23:15:42
#>
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
function add-mfGithubScaffold
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
    }
    
}
function add-mfRepositoryXmlData
{

    <#
        .SYNOPSIS
            Uncompress a nuspec (Which is just a zip with a different extension), parse the XML, add the URL element for the repository, recreate the ZIP file.

            
        .DESCRIPTION
            Some Nuget Package Providers (such as Github Package Manager) require a repository element with a URL attribute in order to be published correctly,
            For Githup Packages, this is so it can tie the package back to the actual repository.

            At present (March 2024), new-moduleManifest and publish-psresource do not have parameter options that works for this.
            This function provides a work-around
            
        ------------
        .EXAMPLE
            add-repositoryXmlData -RepositoryUri 'https://github.com/gituser/example' -NugetPackagePath = 'c:\example\module.1.2.3-beta.4.nupkg -branch 'main' -commit '1234123412341234Y'
            
            #### DESCRIPTION
            Unpack module.1.2.3-beta.4.nupkg to a temp location, open the NUSPEC xml and append a repository element with URL, Type, Branch and Commit attributes, repack the nupkg
            
        .INPUTS
            [String] - This function accepts string values for `repositoryUri` and `NugetPackagePath` via pipeline input by property name.

        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding()]
    PARAM(
        #RepositoryUri
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string]$repositoryUri,
        #Path to the actual file in the repository, should be something like C:\Users\{UserName}\AppData\Local\Temp\LocalTestRepository\{ModuleName}.{ModuleVersion}.nupkg
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string]$NugetPackagePath,
        #TempExtractionPath
        [Parameter()]
        $ExtractionPath = $(join-path -path ([System.IO.Path]::GetTempPath()) -childpath 'tempUnzip'),
        #Use force to ignore remove prompt
        [Parameter()]
        [switch]$force,
        #What branch to add to NUSPEC (Optional)
        [Parameter()]
        [string]$branch,
        [Parameter()]
        #What commit to add to NUSPEC (Optional)
        [string]$commit
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        
    }
    
    process{
        #Check we have valid NuSpec
        $nuPackage = get-item $NugetPackagePath
        if(!$nuPackage)
        {
            throw "Unable to find: $NugetPackagePath"
        }

        if($nuPackage.Extension -ne '.nupkg')
        {
            throw "$NugetPackagePath not a .nupkg file"
        }

        write-verbose "Found nupkg file at: $($nuPackage.fullname)"

        #Get a clean extraction folder
        if(!(test-path $ExtractionPath))
        {
            write-verbose 'Creating Extraction Path'
            New-Item -Path $ExtractionPath -ItemType Directory
        }else{
            Write-warning "Extraction Path will be removed and recreated`nPath: $($ExtractionPath)"
            if(!$force)
            {
                $action = Read-Host 'Are you sure you want to continue with this action? (y/n)'
                if ($action -eq 'y') {
                    # Insert the risky action here
                    Write-warning 'Continuing with the action...'
                } else {
                    throw 'Action cancelled'
                }
            }
            if($action -eq 'y' -or $force -eq $true)
            {
                #Probably dont need this IF statement, just a sanity check we have permission to destroy folder
                get-item -Path $ExtractionPath |remove-item -recurse -force
                New-Item -Path $ExtractionPath -ItemType Directory
            }
            
        }

        write-verbose 'Extracting NuSpec Archive'
        expand-archive -path $nuPackage.FullName -DestinationPath $ExtractionPath
        write-verbose 'Searching for NuSpec file'
        $nuSpec = Get-ChildItem -Path $ExtractionPath -Filter *.nuspec
        if($nuSpec.count -eq 1)
        {
            write-verbose 'Loading XML'

            

            $nuSpecXml = new-object -TypeName XML
            $nuSpecXml.Load($nuSpec.FullName)

            #Repository Element
            $newElement = $nuSpecXml.CreateElement("repository",$nuSpecXml.package.namespaceURI)
            write-verbose 'Adding Repository Type Attribute'
            $newElement.SetAttribute('type','git')
            write-verbose 'Adding Repository URL Attribute'
            $newElement.SetAttribute('url',$repositoryUri)

            if($branch)
            {
                write-verbose 'Adding Repository Branch Attribute'
                $newElement.SetAttribute('branch',$branch)
            }


            if($commit)
            {
                write-verbose 'Adding Repository commit Attribute'
                $newElement.SetAttribute('commit',$commit)
            }

            write-verbose 'Appending Element to XML'
            $nuSpecXml.package.metadata.AppendChild($newElement)

            
            #Save, close XML and repackage


            write-verbose 'Saving the NUSPEC'
            $nuSpecXml.Save($nuspec.FullName)
            remove-variable nuSpecXml
            start-sleep -seconds 2 #Mini pause to let the save complete

            write-verbose 'Repacking the nuPkg'
            $repackPath = join-path $ExtractionPath -ChildPath '*'
            write-verbose "Repack Path:$repackPath"
            compress-archive -Path $repackPath -DestinationPath $nuPackage.FullName -Force
            write-verbose 'Finished Repack'

        }else{
            throw 'Error finding NuSpec'
        }

        
    }
    
}
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
                    
    #>

    [CmdletBinding()]
    PARAM(
        #What version are we building?
        [Parameter(Mandatory)]
        [semver]$version,
        #Root path of the module. Uses the current working directory by default
        [Parameter()]
        [alias('ModulePath')]
        [string]$path = $(get-location).path,
        [Parameter(DontShow)]
        [string]$configFile = 'moduleForgeConfig.xml',
        #Use this flag to put any classes in ScriptsToProcess
        [Parameter()]
        [switch]$exportClasses,
        #Use this flag to put any enums in ScriptsToProcess
        [Parameter()]
        [switch]$exportEnums,
        #Use this to not put anything in nestedmodules, making everything a single file. By default validators are put in a separate nestedmodule script to ensure they are loaded properly
        [Parameter()]
        [switch]$noExternalFiles,
        [Parameter()]
        [string]$releaseNotes,
        [Parameter()]
        [switch]$includeReleaseNotesInDescription

        
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        write-verbose 'Testing module path'
        try{
            $moduleTest = get-item $path -ErrorAction SilentlyContinue
        }catch{
            $moduleTest = $null
        }
        
        if(!$moduleTest){
            throw "Unable to read from $path"
        }

        $path = $moduleTest.FullName
        write-verbose "Building from: $path"

        #Read the config file
        write-verbose 'Importing config file'
        $configPath = join-path -path $path -ChildPath $configFile

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

        write-verbose 'Checking for a build and module folder'
        $buildFolder = join-path -path $path -childPath 'build'
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
        $sourceFolder = join-path -path $path -childPath 'source'

        #What folders do we need to copy the files contents of
        [array]$copyFolders = @('resource','bin')

        $scriptsToProcess = New-Object System.Collections.Generic.List[string]
        $functionsToExport = New-Object System.Collections.Generic.List[string]
        $nestedModules = New-Object System.Collections.Generic.List[string]
        #$DscResourcesToExport = New-Object System.Collections.Generic.List[string] #No Dsc Support presently

        $fileList = New-Object System.Collections.Generic.List[string]

    }
    
    process{

        write-verbose "Attempt to build:`n`t`tmodule:$($config.moduleName)version:`n`t`t$versionString"

        #References for our manifest and module root
        $moduleFileShortname = "$($config.moduleName).psm1"
        $moduleFile = join-path $moduleOutputFolder -ChildPath $moduleFileShortname
        $fileList.Add($moduleFileShortname)
        $manifestFileShortname = "$($config.moduleName).psd1"
        $manifestFile = join-path $moduleOutputFolder -ChildPath $manifestFileShortname
        $fileList.Add($manifestFileShortname)

        write-verbose "Will create module in:`n`t`t$moduleOutputFolder;`n`t`tModule Filename: $moduleFileShortname ;`n`t`tManifest Filename: $manifestFileShortname "

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
        write-verbose 'Adding Header Comment'
        $moduleHeader|out-file $moduleFile -Force


        
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
                #$noExternalFiles = $true
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

                    if($exportEnums -and !$noExternalFiles){
                        write-verbose 'Exporting enum content to external enum file'
                        $item.content|Out-file $enumsFile -Append

                        if($enumsFileShortname -notIn $scriptsToProcess)
                        {
                            $scriptsToProcess.Add($enumsFileShortname)
                        }

                        if($enumsFileShortname -notIn $fileList)
                        {
                            $fileList.Add($enumsFileShortname)
                        }
                    }else{
                        write-verbose 'Exporting enum content to module file'
                        $item.content|out-file $moduleFile -Append

                    }
                }

                'validationClasses' {
                    Write-Information "Processing $($item.name) as a ValidationClass" -tags 'FilesProcessed'
                    write-verbose "Processing $($item.name) as ValidationClass"

                    if($noExternalFiles)
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

                        if($validatorsFileShortname -notIn $fileList)
                        {
                            $fileList.Add($validatorsFileShortname)
                        }

                    }
                }

                'classes' {
                    Write-Information "Processing $($item.name) as a Class" -tags 'FilesProcessed'
                    write-verbose "Processing $($item.name) as Class"

                    if($exportClasses -and !$noExternalFiles){
                        write-verbose 'Exporting classes content to external classes file'
                        $item.content|Out-file $classesFile -Append

                        if($classesFileShortname -notIn $scriptsToProcess)
                        {
                            $scriptsToProcess.Add($classesFileShortname)
                        }

                        if($classesFileShortname -notIn $fileList)
                        {
                            $fileList.Add($classesFileShortname)
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

                    Write-Information "Copied $folder, containing $($folderItems.Count) items, to the module" -tags 'FoldersCopied'
                    
                }
                #Make null = to suppress the object output
                $null = get-mfFolderItems -path $fullFolderPath -destination $destinationFolder -copy

                
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
            ModuleVersion = $versionString
            Guid = $config.guid
            PowershellVersion = $config.minimumPsVersion.tostring()
            CmdletsToExport = [array]@()
        }

        if($releaseNotes)
        {
            #Add the release notes if they were included
            $splatManifest.releaseNotes = $releaseNotes
            if($includeReleaseNotesInDescription)
            {
                $splatManifest.Description = "$($config.Description)`n`n$($releaseNotes)"
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
        if($version.PreReleaseLabel)
        {
            #Semver supplied had a pre-release label
            write-verbose 'Incrementing Prerelease Version'
            write-verbose "Setting Prerelease tag to: $($version.PreReleaseLabel)"
            $splatManifest.Prerelease = $version.PreReleaseLabel
            
        }

        $splatManifest.ModuleVersion = $version
        New-ModuleManifest @splatManifest
        Write-Information 'Created Module Manifest' -tags 'CreatedModuleManifest'
    }
    
}
function get-mfDependencyTree
{

    <#
        .SYNOPSIS
            Generate a dependency tree of ModuleForge PowerShell scripts, either in terminal or a mermaid flowchart
            
        .DESCRIPTION
            The `get-mfDependencyTree` function processes an array of objects representing PowerShell scripts and their dependencies.
            It generates a visual representation of the dependency tree, either as a text-based tree in the terminal or as a Mermaid diagram.
            This function helps in understanding the relationships and dependencies between different scripts and modules in a project.
            
        ------------
        .EXAMPLE
            $folderItemDetails = get-mfFolderItemDetails -path (get-item .\source).fullname
            get-mfDependencyTree ($folderItemDetails|Select-Object relativePath,dependencies)
            
            #### DESCRIPTION
            Show files and any dependencies

        .INPUTS
            [OBJECT[]] - ReferenceData Object Array (Resulting from get-mfFolderItemDetails) accepted as pipeline input

        .OUTPUTS
            [STRING] - Returns a formatted string representing the dependency tree, Output format can be:
                        - Multi-line string expected to print to terminal (Default Behaviour)
                        - A mermaid chart (If specified with Output Type 'Mermaid') 
                        - A mermaid chart encapsulated in a markdown code block ('MermaidMarkdown')
            
        .NOTES
            Author: Adrian Andersson
                        
    #>

    [CmdletBinding()]
    PARAM(
        #What Reference Data are we looking at. See function example for how to retrieve
        [Parameter(ValueFromPipeline)]
        [object[]]$referenceData = (get-mfFolderItemDetails -path (get-item source).fullname),
        [Parameter()]
        [ValidateSet('Mermaid','MermaidMarkdown','Terminal')]
        [string]$outputType = 'Terminal'
    )
    begin {
        # Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        # Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        
        $dependencies = New-Object System.Collections.Generic.List[object]
    }
    
    process {
        foreach ($ref in $referenceData) {
            $relativePath = $ref.relativePath
            foreach ($dep in $ref.dependencies) {
                $dependencies.add(
                    [PSCustomObject]@{
                        Parent = $relativePath
                        Child  = $dep.ReferenceFile
                    }
                )
            }
        }

        $output = New-Object System.Collections.Generic.List[string]
        if ($outputType -eq 'Mermaid' -or $outputType -eq 'MermaidMarkdown') {
            if ($outputType -eq 'MermaidMarkdown') {
                $output.add('```mermaid')
            }
            $output.add('flowchart TD')
            foreach ($dep in $dependencies) {
                $output.add("'$($dep.Parent)' --> '$($dep.Child)'")
            }
            if ($outputType -eq 'MermaidMarkdown') {
                $output.add('```')
            }
            
            $output -join "`n"
        } else {
            $tree = @{}
            foreach ($dep in $dependencies) {
                write-verbose "In: $dep dependencyCheck"
                if (-not $tree.ContainsKey($dep.Parent)) {
                    write-verbose "Need to add: $($dep.Parent) As ParentRef"
                    $tree[$dep.Parent] = New-Object System.Collections.Generic.List[string]
                }

                write-verbose "Need to add $($dep.Child) as child of $($dep.Parent)"
                $tree[$dep.Parent].add($dep.Child)
            }

            $rootNodes = $referenceData.where{$_.Dependencies.Count -gt 0}.relativePath
            $rootNodes.foreach{
                write-output $_
                if ($tree.ContainsKey($_)) {
                    foreach ($child in $tree[$_]) {
                        printTree -node $child -level 1
                    }
                }
            }
        }
    }
}
function get-mfFolderItemDetails
{

    <#
        .SYNOPSIS
            This function analyses a PS1 file, returning its content, any functions, classes and dependencies, as well as a relative location
            
        .DESCRIPTION
            The `get-mfFolderItemDetails` function takes a path to source folder
            
            It creates a job that generates a details about all found PS1 files,
            including: The content of PS1 files, the names of any functions, the names of any classes, and any inter-related dependencies

            This function uses a job to import all the ps1 items so that all types can be reflected correctly without having to load the module,
            So it works without having to build the manifest etc

            This function is primary used to build dependency trees and during build to get file contents
            
        ------------
        .EXAMPLE
            get-mfFolderItemDetails .\source
        
        .INPUTS
            [STRING] - Path to Source Folder is accepted as Pipeline Input or direct assignment

        .OUTPUTS
            [Object[]] - Returns an array of objects with detailed file metadata, including:
                - **Name** (`[String]`) - Name of the file.
                - **Path** (`[String]`) - Full file path.
                - **FileSize** (`[Int]`) - File size in kilobytes.
                - **FunctionDetails** (`[Object[]]`) - Details of functions within the file.
                - **ClassDetails** (`[Object[]]`) - Details of classes within the file.
                - **Contents** (`[String]`) - Entire script content.
                - **Group** (`[String]`) - Subfolder grouping.
                - **Dependencies** (`[Object[]]`) - References to other files with name and full path.

            Child Object Details:
            #### FunctionDetails (`[Object]`)
                - **functionName** (`[String]`) - Name of the function.
                - **cmdLets** (`[Object]`) - Functions/cmdlets called, with name and usage count.
                - **types** (`[Object]`) - Classes referenced, with name and usage count.
                - **parameterTypes** (`[Object]`) - Enums used.
                - **Validators** (`[Object]`) - Validator classes used.
                - **Properties** (`[String[]]`) - Properties within the function.

            #### ClassDetails (`[Object]`)
                - **ClassName** (`[String]`) - Name of the class.
                - **Methods** (`[String]`) - Methods defined in the class.
                - **Properties** (`[String[]]`) - Properties within the class.

            
        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseSingularNouns", "", Justification = "Plural 'Details' reflects multiple attributes returned and improves clarity.")]
    PARAM(
        #Path to source folder.
        [Parameter(ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string]$path = ((get-item 'source').fullname)
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }
    
    process{

        write-verbose 'Creating Scriptblock'
        [scriptblock]$sblock = {
            param($path,$folderItems)
 
            function Get-mfScriptDetails {
                param(
                    [Parameter(Mandatory)]
                    [string]$Path,
                    [Parameter()]
                    [string]$RelativePath,
                    [ValidateSet('Class','Function','All')]
                    [Parameter()]
                    [string]$type = 'All',
                    [Parameter()]
                    [string]$folderGroup
                )
                begin{
                    write-verbose 'Checking Item'
                    if($path[-1] -eq '\' -or $path[-1] -eq '/')
                    {
                        write-verbose 'Removing extra \ or / from path'
                        $path = $path.Substring(0,$($path.length-1))
                        write-verbose "New Path $path"
                    }
                    $file = get-item $Path
                    if(!$file)
                    {
                        throw "File not found at: $path"
                    }
                }
                process{
                    $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
                    
                    
                    #$Functions = $AST.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
                    #The above was the original way to do this
                    #However it was so efficient it also returned subfunctions AND functions in scriptblocks
                    #Since we don't want to do that, we cycle through and look at the start and end line numbers and only return top-level functions
                    #Leaving it here as a reminder 

                    $AllFunctions = $AST.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
                    $TopLevelFunctions = New-Object System.Collections.Generic.List[Object]
                    foreach($func in $allFunctions){
                        $isNested = $false
                        foreach($parentFunc in $allFunctions)
                        {
                            if($func -ne $parentFunc -and $func.Extent.StartLineNumber -ge $parentFunc.Extent.StartLineNumber -and $func.Extent.EndLineNumber -le $parentFunc.Extent.EndLineNumber)
                            {
                                $isNested = $true
                                break
                            }
                        }
                        if(-not $isNested) {
                            $TopLevelFunctions.add($func)
                        }
                    }
                    
                    $Classes = $AST.FindAll({ $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] }, $true)
                    if($type -eq 'All' -or $type -eq 'Function')
                    {
                        $functionDetails = foreach ($Function in $TopLevelFunctions) {
                            $cmdletDependenciesList = New-Object System.Collections.Generic.List[string]
                            $typeDependenciesList = New-Object System.Collections.Generic.List[string]
                            $paramTypeDependenciesList = New-Object System.Collections.Generic.List[string]
                            $validatorTypeDependenciesList = New-Object System.Collections.Generic.List[string]
                            $FunctionName = $Function.Name
                            $Cmdlets = $Function.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)
                            foreach($c in $Cmdlets)
                            {
                                $cmdletDependenciesList.add($c.GetCommandName())
                            }
                            $TypeExpressions = $Function.FindAll({ $args[0] -is [System.Management.Automation.Language.TypeExpressionAst] }, $true)
                            $TypeExpressions.TypeName.FullName.foreach{
                                $tname = $_
                                [string]$tnameReplace = $($tname.Replace('[','')).replace(']','')
                                $typeDependenciesList.add($tnameReplace)
                            }
                            $Parameters = $Function.Body.ParamBlock.Parameters
                            $Parameters.StaticType.Name.foreach{$paramTypeDependenciesList.add($_)}
                            $attributes = $Parameters.Attributes
                            foreach($att in $attributes)
                            {
                                $refType = $att.TypeName.GetReflectionType()
                                if($refType -and ($refType.IsSubclassOf([System.Management.Automation.ValidateArgumentsAttribute]) -or [System.Management.Automation.ValidateArgumentsAttribute].IsAssignableFrom($refType))) {
                                    [string]$tname = $Att.TypeName.FullName
                                    [string]$tname = $($tname.Replace('[','')).replace(']','')
                                    $validatorTypeDependenciesList.Add($tname)
                                }
                            }
                    
                            [psCustomObject]@{
                                functionName = $FunctionName
                                cmdLets = $cmdletDependenciesList|group-object|Select-Object Name,Count
                                types = $typeDependenciesList|group-object|Select-Object Name,Count
                                parameterTypes = $paramTypeDependenciesList|group-object|Select-Object name,count
                                Validators = $validatorTypeDependenciesList|Group-Object|Select-Object name,count
                            }
                        }
                    }
                    if($type -eq 'all' -or $type -eq 'Class')
                    {
                        $classDetails = foreach ($Class in $Classes) {
                            $className = $Class.Name
                            $classMethodsList = New-Object System.Collections.Generic.List[string]
                            $classPropertiesList = New-Object System.Collections.Generic.List[string]
                            $Methods = $Class.Members | Where-Object { $_ -is [System.Management.Automation.Language.FunctionMemberAst] }
                            foreach($m in $Methods)
                            {
                                $classMethodsList.add($m.Name)
                            }
                            $Properties = $Class.Members | Where-Object { $_ -is [System.Management.Automation.Language.PropertyMemberAst] }
                            foreach($p in $Properties)
                            {
                                $classPropertiesList.add($p.Name)
                            }
                            [psCustomObject]@{
                                className = $className
                                methods = $classMethodsList|group-object|Select-Object Name,Count
                                properties = $classPropertiesList|group-object|Select-Object Name,Count
                            }
                        }
                    }
                    $objectHash = @{
                        Name = $file.Name
                        Path = $file.FullName
                        FileSize = "$([math]::round($file.length / 1kb,2)) kb"
                        FunctionDetails = $functionDetails
                        ClassDetails = $classDetails
                        Content = $AST.ToString()
                    }
                    if($RelativePath)
                    {
                        $objectHash.relativePath = $RelativePath
                    }
                    if($folderGroup)
                    {
                        $objectHash.group = $folderGroup
                    }
                    [psCustomObject]$objectHash
                }
            }
            
            $privateMatch = "*$([IO.Path]::DirectorySeparatorChar)private$([IO.Path]::DirectorySeparatorChar)*"
            $functionMatch = "*$([IO.Path]::DirectorySeparatorChar)functions$([IO.Path]::DirectorySeparatorChar)*"

            $folderItems.ForEach{
                
                if($_.path -notlike $privateMatch -and $_.path -notlike $functionMatch)
                {
                    #Need to dot source the files to make sure all the types are loaded
                    #Only needs to happen for non-function files
                    . $_.Path
                }
            }

            $thisPath = (Get-Item $path)
            $relPathBase = ".$([IO.Path]::DirectorySeparatorChar)$($thisPath.name)"
            
            $itemDetails = $folderItems.ForEach{
                $folderPath = join-path -path $_.folder -childpath $_.RelativePath.Substring(1)
                $relPath = join-path -path $relPathBase -childpath $folderPath
                if($_.path -like $privateMatch -or $_.path -like $functionMatch -or $_.folder -eq $functionMatch -or $_.folder -eq $privateMatch)
                {   
                    write-verbose "$($_.Path) matched on type: Function"
                    Get-mfScriptDetails -Path $_.Path -RelativePath $relPath -type Function -folderGroup $_.folder
                }else{
                    write-verbose "$($_.Path) matched on type: Class"
                    Get-mfScriptDetails -Path $_.Path -RelativePath $relPath -type Class -folderGroup $_.folder
                }
                
            }
    
            write-verbose 'Return items in Context'
            $inContextList =New-Object System.Collections.Generic.List[string]
            $filenameReference = @{}
            $filenameRelativeReference = @{}
    
            $itemDetails.foreach{
                $fullPath = $_.path
                $relPath = $_.relativePath
                write-verbose "Getting details for $($_.name)"
                $_.FunctionDetails.Foreach{
                    $inContextList.add($_.functionName)
                    $filenameReference.add($_.functionName,$fullPath)
                    $filenameRelativeReference.Add($_.functionName,$relPath)
                }
                $_.ClassDetails.Foreach{
                    $inContextList.add($_.className)
                    $filenameReference.add($_.className,$fullPath)
                    $filenameRelativeReference.Add($_.className,$relPath)
                }
            }

            $checklist = $filenameReference.GetEnumerator().name

            foreach($item in $itemDetails)
            {
                write-verbose "Checking dependencies for file: $($item.name)"
                $compareList =New-Object System.Collections.Generic.List[string]
                $item.ClassDetails.methods.name.foreach{$compareList.add($_)}
                $item.FunctionDetails.cmdlets.name.foreach{$compareList.add($_)}
                $item.FunctionDetails.types.Name.foreach{$compareList.add($_)}
                $item.FunctionDetails.validators.name.foreach{$compareList.add($_)}
                $item.FunctionDetails.parameterTypes.name.foreach{$compareList.add($_)}

                $dependenciesList =New-Object System.Collections.Generic.List[object]

                foreach($c in $compareList)
                {
                    write-verbose "Checking dependency of $c"
                    if($c -in $checklist)
                    {
                        write-verbose "$c found in checklist"
                        if($item.path -ne $filenameReference["$c"])
                        {
                            write-verbose "$c found in checklist"

                            $dependenciesList.add([psCustomObject]@{Reference=$c;ReferenceFile=$filenameRelativeReference["$c"]})
                            
                        }else{
                            write-verbose "$c found in checklist - but in same file, ignoring"
                        }
                    }                  
                }
                
                #Add dependencies as an item
                $item|add-member -MemberType NoteProperty -Name 'Dependencies' -Value $dependenciesList
                $item
            }
        }

        write-verbose 'Getting Folder Items'

        [array]$folders = @('enums','validationClasses','classes','dscClasses','functions','private')
        $folderItems = $folders.ForEach{
            $folderPath = Join-Path $path -ChildPath $_
            if(!(test-path $folderPath))
            {
                write-verbose "$folderPath not found. Skipping"
            }else{
                write-verbose "Getting items from $folderPath"
                get-mfFolderItems -path $folderPath -psScriptsOnly
            }
        }

        write-verbose "Starting Job; arguments `nPath:$($path|out-string)`nFiles:`n$($folderItems.name|out-string))"
        $job = Start-Job -ScriptBlock $sblock -ArgumentList @($path, $folderItems) -WorkingDirectory $path
        $job|Wait-Job|out-null
        write-verbose 'Retrieving output and returning result'
        $output = Receive-Job -Job $job

        remove-job -job $job
        return $output   
    }   
}
function get-mfFolderItems
{
    <#
        .SYNOPSIS
            Retrieves a filtered list of files from a specified folder, processing '.mfignore' and '.mforder' rules.
            
        .DESCRIPTION
            The 'get-mfFolderItems' function scans a folder and applies filtering rules to return a curated list of files. It offers additional filtering logic, such as:
            - Ignoring entries specified in `.mfignore`.
            - Filtering out non-PS1 files using a switch (`-psScriptsOnly`).
            - Excluding test-related files (`*.test.ps1`, `*.tests.ps1`, `*.skip.ps1`).
            - Handling optional file copying (`-destination` and `-copy` parameters).

            The function ensures all returned paths are fully qualified.
            This function is primarily used to assist the get-mfFolderItemDetails as well as build-mfProject.
            The -copy switch is added to cleanly copy resources and binaries with build-mfProject
            
        .EXAMPLE
            get-mfFolderItems -path '.\source\functions' -psScriptsOnly
            
            #### DESCRIPTION
            Scans `.\source\functions`, retrieves only `.ps1` files, and excludes files matching `.mfignore` rules.

        .EXAMPLE
            get-mfFolderItems -path '.\source\functions' -destination '.\build\functions' -copy

            #### DESCRIPTION
            Scans `.\source\functions`, retrieves filtered files, and copies them to `.\build\functions`.

        .INPUTS
            [String] - Accepts a folder path via parameter or pipeline (`ValueFromPipelineByPropertyName`).

        OUTPUTS
            [Object[]] - Returns an array of objects containing:
                - **Name** (`[String]`) - Name of the file.
                - **Path** (`[String]`) - Full file path.
                - **RelativePath** (`[String]`) - Path relative to the source folder.
                - **Folder** (`[String]`) - Name of the source folder.
                - **(Optional) newPath** (`[String]`) - Destination path if copying.
                - **(Optional) newFolder** (`[String]`) - Destination folder name if copying.
            
        .NOTES
            Author: Adrian Andersson
                    
    #>

    [CmdletBinding(DefaultParameterSetName='Default')]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseSingularNouns", "", Justification = "Plural 'Items' reflects nature of function and improves clarity.")]
    PARAM(
        #Path to get items from
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ValueFromPipeline,ParameterSetName ='Default')]
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ValueFromPipeline,ParameterSetName ='Copy')]
        [alias('s')]
        [string]$path,
        #Flag to copy scripts only
        [parameter(ParameterSetName ='Default')]
        [parameter(ParameterSetName ='Copy')]
        [switch]$psScriptsOnly,
        #Flag to copy scripts only
        [parameter(ParameterSetName ='Copy')]
        [string]$destination,
        #Flag to actually copy files and not just output
        [parameter(ParameterSetName ='Copy')]
        [switch]$copy

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        write-verbose "ParameterSet: $($PSCmdlet.ParameterSetName)"

        $fileListSelect = @(
            'Name'
            @{
                Name = 'Path'
                Expression = {$_.Fullname}
            }
            'RelativePath'
            @{
                Name = 'Folder'
                Expression = {$folderShortName}
            }
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
            @{
                Name = 'Folder'
                Expression = {$folderShortName}
            }
        )


        
    }
    
    process{

        #Check the Parameters and do some lite parsing
        write-verbose "Path set to: $path"
        
        if($path[-1] -eq '\' -or $path[-1] -eq '/')
        {
            write-verbose 'Removing extra \ or / from path'
            $path = $path.Substring(0,$($path.length-1))
            write-verbose "New Path $path"
        }

        try{
            $folderItem = get-item $path -erroraction stop
            #Ensure we have the full path

            $folder = $folderItem.FullName
            write-verbose "Folder Fullname: $folder"
            $folderShortName = $folderItem.Name
            write-verbose "Folder Shortname: $folderShortName"

        }catch{
            throw "Unable to get folder at $path"
        }


        #Include the older bartender bits so we have backwards compatibility
        [System.Collections.Generic.List[string]]$excludeList = '.gitignore','.mfignore','.btorderEnd','.btorderStart','.btignore'

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

        #Actual processing
        
        write-verbose 'Getting Folder files'
        if($psScriptsOnly)
        {
            write-verbose 'Getting PS1 Files'
            $fileList = get-childitem -path $folder -recurse -filter *.ps1|where-object{$_.psIsContainer -eq $false -and $_.name.tolower() -notlike '*.test.ps1' -and $_.name.tolower() -notlike '*.tests.ps1' -and $_.name.tolower() -notlike '*.skip.ps1' -and $_.Name.tolower() -notin $excludeList}
        }else{
            write-verbose 'Getting Folder files'
            $fileList = get-childitem -path $folder -recurse |where-object{$_.psIsContainer -eq $false -and $_.name.tolower() -notlike '*.test.ps1' -and $_.name.tolower() -notlike '*.tests.ps1' -and $_.name.tolower() -notlike '*.skip.ps1' -and $_.Name.tolower() -notin $excludeList}
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
                        write-verbose 'Destination folder does not exist, attempt to create'
                        try{
                            $null = new-item -itemtype directory -path $_.newFolder -force -ErrorAction stop
                            write-verbose "Made new directory at: $($_.newFolder)"
                        }catch{
                            throw "Error making new directory at: $($_.newFolder)"
                        }
                    }
                    try{
                        write-verbose "Copying $($_.relativePath) to $($_.newPath)"
                        $null = copy-item -path ($_.fullname) -destination ($_.newPath) -force
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
function get-mfGitChangeLog
{
<#
    .SYNOPSIS
        Generates a markdown changelog from Git commit messages between the latest and previous tags.

    .DESCRIPTION
        This function retrieves Git commit messages between the latest and previous tags, categorizes them based on predefined types, and formats them into a markdown changelog. It ensures the Git environment is correctly set up and handles errors if Git is not recognized or tags are not found.

    .EXAMPLE
        get-mfGitChangeLog
    
        DESCRIPTION
        Call the `get-mfGitChangeLog` function with default change Log Types. The function will generate a markdown changelog that can be sent to release or artifact notes.
        
        #### OUTPUT
        # Change Log
        Version: v1.0.0 --> v1.1.0
        ## New Features
        - Added new authentication module
        ## Bug Fixes
        - Fixed issue with user login

    .EXAMPLE
        get-mfGitChangeLog -changeLogTypes @{
        'feat' = 'New Features'
        'fix' = 'Bug Fixes'
        'chore' = 'Chore and Pipeline work'
        'test' = 'Test Changes'
        }
        
        DESCRIPTION
        This example demonstrates how to call the `get-mfGitChangeLog` function with a custom set of changelog types, in case you want to control your own

        #### OUTPUT
        # Change Log
        Version: v1.0.0 --> v1.1.0
        ## New Features
        - Added new authentication module
        ## Bug Fixes
        - Fixed issue with user login
        ## Chore and Pipeline work
        - Updated GH Pipeline AutoBuildv3
        ## Test Changes
        - Added test to user login function

    .EXAMPLE
        get-mfGitChangeLog -All

        DESCRIPTION
        Generates a full markdown changelog with all versions.

        #### OUTPUT
        # Change Log
        ## Version: v1.0.0 --> v1.1.0
        ### New Features
        - Added new authentication module
        ### Bug Fixes
        - Fixed issue with user login
        ### Chore and Pipeline work
        - Updated GH Pipeline AutoBuildv3
        ### Test Changes
        - Added test to user login function
        ## Version: v1.0.0-prev001 --> v1.1.0
        ### New Features
        - Added function

    .EXAMPLE
        get-mfGitChangeLog -fromLastTag

        DESCRIPTION
        Generates markdown changelog from commit messages from the last tag until now (Head)

        #### OUTPUT
        # Change Log

        ### New Features
        - Added new authentication module
        ### Bug Fixes
        - Fixed issue with user login
        ### Chore and Pipeline work
        - Updated GH Pipeline AutoBuildv3
        ### Test Changes
        - Added test to user login function

    .INPUTS
        [hashtable] - Accepts changeLogTypes hashtable via parameter or pipeline

    .OUTPUTS
        [STRING] - Returns a Markdown Compatible string output that can be redirected to a file

    .NOTES
        Author: Adrian Andersson
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([string])]
    PARAM(
        #Change Logs Types and corresponding Heading. Hashtable/Key Value Pair expected. Key = git type; Value = Heading
        [Parameter(ValueFromPipeline, ParameterSetName = 'Default')]
        [Parameter(ValueFromPipeline, ParameterSetName = 'All')]
        [Parameter(ValueFromPipeline, ParameterSetName = 'FromLastTag')]
        [hashtable]$changeLogTypes = @{
            'feat' = 'New Features'
            'fix' = 'Bug Fixes'
            'docs' = 'Documentation Changes'
            'refactor' = 'Code Rewrite/Refactor'
            'perf' = 'Performance Improvements'
            #'chore' = 'Chore and Pipeline work'
            #'test' = 'Testing'
        },
        #Switch to get a full changelog for ALL tags
        [Parameter(ParameterSetName = 'All', Mandatory)]
        [switch]$all,
        #Switch to get the changelog from the last tag until this point.
        [Parameter(ParameterSetName = 'FromLastTag', Mandatory)]
        [switch]$fromLastTag
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        $markDown = [System.Collections.Generic.List[string]]::new()
        $markDown.add("# Change Log`n")
    }
    
    process{
        write-verbose 'Check git commandline and directory is going to work the way we expect it to. Throw if it does not'
        try{
            $gitVer = git --version
            $gitFolder = git rev-parse --is-inside-work-tree
            $gitFolder = $gitFolder.trim()
            
        }catch{
            throw 'Error getting Git Version or working directory.'
        }

        if(!$gitVer)
        {
            throw 'Git Version undetermined'
        }
        if(!$gitFolder -or $gitFolder -notlike '*true*')
        {
            throw 'Git not recognised as inside work tree'
        }

        write-verbose 'Get the Git Tags. Use the count of tags to determine if we are bundling for a release'
        #If you run this after tests and build, then creating a new release w/ tag, then you will KNOW that the tag is the new version
        $tags = @(git tag --sort=-creatordate)
        $tagCount  = $tags.count
        write-verbose "Got $tagCount total tags; ($($tags -join ','))"
        if($tagCount -gt 1 -and -not $fromLastTag)
        {
            if($all)
            {
                write-verbose 'AllFlag set. Getting complete Change Log'
                $tagRef = 1 #We need a marker to know what the next tag is. Since we start at 0, the ref should start at 1
                
                $tags.foreach{
                    write-verbose "Getting contents for $_. Reference: $tagRef"
                    $t1 = $_
                    $markDown.add("## Version: $t1`n")
                    if($tagRef -eq $tagCount){
                        write-verbose 'Last Entry?'
                        write-verbose "git log `"$($t1)`" --pretty=format:`"%s`""
                        $commitMessages = git log "$($t1)" --pretty=format:"%s"
                    }else{
                        $t2 = $tags[$tagRef]
                        write-verbose "git log `"$($t2)..$($t1)`" --pretty=format:`"%s`""
                        $commitMessages = git log "$($t2)..$($t1)" --pretty=format:"%s"
                    }
                        
                    $commitObjects = $commitMessages.forEach{if($_ -like '*:*'){$s = $_.split(":");[PSCustomObject]@{Type = $s[0].trim();Message = $s[1].trim()}}}
                    $grouped = $commitObjects.where{$_.type -in $changeLogTypes.getEnumerator().name} | group-object -property 'type'
                    $grouped.forEach{
                        $markDown.Add("`n### $($changeLogTypes.$($_.name))`n")
                        $_.group.Message.ForEach{
                            $markDown.Add("- $_")
                        }
                        $markDown.Add("`n")
                    }
                    
                    $tagRef++
                }
            }else{
                #Only get between the latest and previous release based on tag
                write-verbose "Found $tagCount total tags. Sorting to get latest and previous"
                $commitMessages = git log "$($tags[1])..$($tags[0])" --pretty=format:"%s"
                $markDown.add("## Version: $($tags[1]) --> $($tags[0])`n")
            }
        }elseIf($fromLastTag -and $tagCount -gt 0){
                write-verbose "fromLastTag set. Getting changelog from the last tagging event until now"
                write-verbose "Found $tagCount total tags. Sorting to get latest and previous"
                $commitMessages = git log "$($tags[0])..HEAD" --pretty=format:"%s"
        }else{
            #Get all and assume this is the first tag
            write-verbose 'Either Single Tag found or no tags found. Get all Commit messages to this point'
            $commitMessages = git log --pretty=format:"%s"
        }

        if(!$all -and $commitMessages)
        {
            write-verbose 'Getting Commit Objects, grouping and parsing based on changeLogTypes variable'
            $commitObjects = $commitMessages.forEach{if($_ -like '*:*'){$s = $_.split(":");[PSCustomObject]@{Type = $s[0].trim();Message = $s[1].trim()}}}
            $grouped = $commitObjects.where{$_.type -in $changeLogTypes.getEnumerator().name} | group-object -property 'type'
            $grouped.forEach{
                $markDown.Add("`n## $($changeLogTypes.$($_.name))`n")
                $_.group.Message.ForEach{
                    $markDown.Add("- $_")
                }
            }    
        }
        
        write-verbose 'Converting to Markdown String'
        $markDownText = $markDown -join "`n" 
        write-verbose "markDownLines = $($markDown.count)"
        #Check we have enough relevant commit messages to return a changelog
        #Basically, markDown should be gt 1, as the first line will be # changeLog.
        if($markDownText -and $markDown.count -gt 1){
            return $markDownText
        }else{
            return "# No relevant commit messages to convert to changelog"
        }
    }
}
function get-mfGitLatestVersion
{

    <#
        .SYNOPSIS
            Retrieves the latest Git tag version in semantic version format.
            
        .DESCRIPTION
            This function queries Git for available tags and processes them as semantic versions.
            If no tags are found, it initializes a new version starting from `1.0.0`.
            If Git is unavailable or returns an error, a warning is displayed, and processing continues gracefully.
            
        ------------
        .EXAMPLE
            get-mfGitLatestVersion

            #### DESCRIPTION
            Queries the current Git repository for version tags, identifies the latest version,
            and returns it in `major.minor.patch` format.

            #### OUTPUT
            1.2.3
            (Example: If Git tags include `v1.0.0`, `v1.2.3`, `v1.1.0`, the function returns `1.2.3` as the latest.)

        .EXAMPLE
            get-mfGitLatestVersion -Verbose

            #### DESCRIPTION
            Runs the function with verbose output, providing detailed debugging information
            about the Git command execution and version determination.

            #### OUTPUT
            ```
            ===========Executing get-mfGitLatestVersion===========
            Got VersionTags: v1.0.0 v1.2.3 v1.1.0
            Latest Tag Version: 1.2.3
            ```
        .OUTPUTS
            [semver] - Returns a Semantec Version object
            
        .NOTES
            Author: Adrian Andersson
            
    #>

    [CmdletBinding()]
    PARAM(

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        
    }
    
    process{
        try{
            $versionTags = git tag --list 2>&1
            if ($LASTEXITCODE -ne 0 -or $versionTags -match "fatal:") {
                throw "Git Error: $versionTags"
            }
        }catch{
            Write-Warning "Error with git command: $_"
            $versionTags = $null
        }
        
        write-verbose "Got VersionTags: $versionTags"
        if($versionTags) {
        $versions = $versionTags.ForEach{[semver]::new($_.TrimStart("v"))}
            $latest = ($versions | Sort-Object -Descending | Select-Object -First 1)
        Write-Verbose "Latest Tag Version: $($latest.tostring())"
        } else {
        Write-Verbose 'Generating new version from scratch at 1'
            $latest = [semver]::new(1,0,0)
        }
        return $latest
    }
    
}
function get-mfLatestSemverFromBuildManifest
{

    <#
        .SYNOPSIS
            If you are manually building, and you have access to the \build folder, you can use this to get the next semver
            
        .DESCRIPTION
            Detailed Description
            
        ------------
        .EXAMPLE
            get-mfLatestSemverFromBuildManifest
            
            #### DESCRIPTION
            Import build\module\modulemanifest.psd1
            Find the prerelease tag(if present) and module version. I.e. module version 1.1.0 prerelease tag prev003 = 1.1.0-prrev003
            
            
            #### OUTPUT
            Major  Minor  Patch  PreReleaseLabel BuildLabel
            -----  -----  -----  --------------- ----------
            1      1      0      prev003
            
        .OUTPUTS
            [semver] - Returns a Semantec Version object    
            
        .NOTES
            Author: Adrian Andersson
            
    #>

    [CmdletBinding()]
    [OutputType([semver])]
    PARAM(
        #Root path of the module. Uses the current working directory by default
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [alias('modulePath')]
        [string]$path  = $(get-location).path,
        [Parameter(DontShow)]
        [string]$configFile = 'moduleForgeConfig.xml',
        [Parameter(DontShow)]
        [string]$moduleNameOverride


    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }
    
    process{
        #Do some checks and parsing
        if(! $moduleNameOverride)
        {
            #Read the config file
            write-verbose 'Importing config file'
            $configPath = join-path -path $path -ChildPath $configFile

            if(!(test-path $configPath))
            {
                throw "Unable to find config file at: $configPath"
            }
            $config = import-clixml $configPath -erroraction stop
            $moduleName = $config.moduleName
        }else{
            $moduleName = $moduleNameOverride
        }
        
        
        $buildFolder = Join-Path $path 'build'
        write-verbose "build folder: $buildFolder"
        $moduleFolder = join-path $buildFolder $moduleName
        $manifestFile = get-childItem -Path $moduleFolder -Filter "$moduleName.psd1"
        if(!$manifestFile){
            throw 'Manifest file not found in build folder'
        }else{
            write-verbose "Found manifest at $($manifestFile.FullName)"
            $ManifestPath = $manifestFile.fullname
        }

        #Actual processing

        write-verbose 'Try and import manifest as datafile'
        try{
            $manifest = Import-PowerShellDataFile -Path $ManifestPath
        }catch{
            throw 'Manifest was found but unable to import as PSDataFile'
        }

        write-verbose 'Get Module Version'
        $moduleVersion = $manifest.ModuleVersion
        if(!$moduleVersion){
            throw 'Err: Unable to get moduleVersion'
        }else{
            write-verbose "Found Version: $moduleVersion"
        }

        write-verbose 'Check for PreRelease'
        $preRelease = $manifest.PrivateData.PSData.Prerelease
        if($preRelease)
        {
            write-verbose "Found Prerelease tag: $($preRelease)"
            $versionString = "$($moduleVersion)-$($preRelease)"
        }else{
            write-verbose 'No Prerelease was found'
            $versionString = $moduleVersion
        }

        write-verbose 'Attempt to make semver from string'
        try{
            [semver]::new($versionString)
        }catch{
            throw "Err: Could not convert $versionString to semver object"
        }
    }
    
}
function get-mfNextSemver
{

    <#
    .SYNOPSIS
        Increments the version of a Semantic Version (SemVer) object.

    .DESCRIPTION
        The `get-mfNextSemver` function takes a Semantic Version (SemVer) object as input and increments the version based on the 'increment' parameter. 
        It can handle major, minor, and patch increments. 
        The function also handles pre-release versions and allows the user to optionally override the pre-release label.

    .EXAMPLE
        $version = [SemVer]::new('1.0.0')
        get-mfNextSemver -version $version -increment 'Minor' -prerelease

        #### DESCRIPTION
        This example takes a SemVer object with version '1.0.0', increments the minor version, and adds a pre-release tag. The output will be '1.1.0-prerelease.1'.

        #### OUTPUT
        '1.1.0-prerelease.1'

    .EXAMPLE
        $version = [SemVer]::new('2.0.0-prerelease.1')
        get-mfNextSemver -version $version -increment 'Major'

        #### DESCRIPTION
        This example takes a SemVer object with version '2.0.0-prerelease.1', increments the major version, and removes the pre-release tag because the 'prerelease' switch is not set. The output will be '3.0.0'.

        #### OUTPUT
        '3.0.0'

    .INPUTS
        [semver] - Will accept a Semver from pipeline or via direct assignment

    .OUTPUTS
        [semver] - Returns a Semantec Version object that should increment, based on the other parameters, the input semver

    .NOTES
        Author: Adrian Andersson
    #>

    [CmdletBinding(DefaultParameterSetName='default')]
    PARAM(
        #Semver Version
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName,ParameterSetName='default')]
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName,ParameterSetName='preRelease')]
        [SemVer]$version,

        #What are we incrementing
        [Parameter(ParameterSetName='default')]
        [Parameter(ParameterSetName='preRelease')]
        [ValidateSet('Major','Minor','Patch')]
        [string]$increment,

        #Is this a prerelease
        [Parameter(ParameterSetName='preRelease')]
        [switch]$prerelease,

        #Is this a prerelease
        [Parameter(ParameterSetName='default')]
        [switch]$stableRelease,

        #Optional override the prerelease label. If not supplied will use 'prerelease'
        [Parameter(ParameterSetName='preRelease')]
        [Parameter(ParameterSetName='Initial')]
        [string]$preReleaseLabel,

        #Is this the initial prerelease
        [Parameter(ParameterSetName='Initial')]
        [switch]$initialPreRelease

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        #Making the default preReleaase label to be lower case. This addresses a problem with psResourceGet and AzureDevOps repositories specifically (Issue #1787)
        $defaultPrereleaseLabel = 'pre' 

        if (-not $increment -and -not $prerelease -and -not $initialPreRelease -and -not $stableRelease) {
            throw 'At least one of "increment", parameter or "stableRelease", "prerelease", "initialPreRelease" switch should be supplied.'
        }
    }
    
    process{
        # Increment the version based on the 'increment' parameter
        switch ($increment) {
            'Major' { 
                #$nextVersion = $version.IncrementMajor()
                $nextVersion = [semver]::new($version.Major+1,0,0)
                write-verbose "Incrementing Major Version to: $($nextVersion.tostring())"
             }
            'Minor' { 
                $nextVersion = [semver]::new($version.Major,$version.minor+1,0)
                write-verbose "Incrementing Minor Version to: $($nextVersion.tostring())"
            }
            'Patch' { 
                $nextVersion = [semver]::new($version.Major,$version.minor,$version.Patch+1)
                write-verbose "Incrementing Patch Version to: $($nextVersion.tostring())"
            }
        }

        # Handle pre-release versions
        if($prerelease -and !$nextVersion -and $version.PreReleaseLabel)
        {
            #This scenario indicates version supplied is already a prerelease, and what we want to do is increment the prerelease version
            write-verbose 'Incrementing Prerelease Version'
            $currentPreReleaseSplit = $version.PreReleaseLabel.Split('v')
            $currentpreReleaseLabel = $currentPreReleaseSplit[0]
            write-verbose "Current PreRelease Label: $currentpreReleaseLabel"
            if(!$preReleaseLabel -or ($currentpreReleaseLabel -ceq $preReleaseLabel)){
                if($currentpreReleaseLabel -eq $preReleaseLabel)
                {
                    write-warning 'It appears the prerelease casing has changed, but the label has not. This may cause unexpected ordering results.'
                }
                write-verbose 'No change to prerelease label'
                $nextPreReleaseLabel = $currentpreReleaseLabel
                $currentPreReleaseInt = [int]$currentPreReleaseSplit[1]
                $nextPrerelease = $currentPreReleaseInt+1
                

            }else{
                write-verbose 'Prerelease label changed. Resetting prerelease version to 1'
                $nextPreReleaseLabel = $preReleaseLabel
                $nextPreRelease = 1
            }
            
            $nextVersionString = "$($version.major).$($version.minor).$($version.patch)-$($nextPreReleaseLabel)v$('{0:d3}' -f $nextPrerelease)"
            $nextVersion = [semver]::New($nextVersionString)
            write-verbose "Next Prerelease will be: $($nextVersion.ToString())"
            
        }elseIf($prerelease -and $nextVersion)
        {
            write-verbose 'Need to tag incremented version as PreRelease'
            #This scenario indicates we have incremented a major,minor or patch, and need to start a fresh prerelease
            if(!$preReleaseLabel){
                $nextPreReleaseLabel = $defaultPrereleaseLabel
            }else{
                $nextPreReleaseLabel = $preReleaseLabel
            }

            $nextVersionString = "$($nextVersion.major).$($nextVersion.minor).$($nextVersion.patch)-$($nextPreReleaseLabel)v001"
            $nextVersion = [semver]::New($nextVersionString)
            write-verbose "Next Prerelease will be: $($nextVersion.ToString())"
        }elseIf($prerelease){
            #This is a strange scenario. Indicates that we have prerelease switch,but the version supplied wasn't a prerelease already. And we didn't increment anything.
            #Are we supposed to go backwards

            #throw 'Unsure on version scenario. Prerelease wanted but version provided was not a pre-release. Please provide a version with existing prerelease, or include an increment'
            
            #I think what we do, is we increment patch by 1 and then tag as pre-release
            write-warning 'Unspecified version increment. Will increment Patch. If this is not what you meant, please try again'

            if(!$preReleaseLabel){
                $nextPreReleaseLabel = $defaultPrereleaseLabel
            }else{
                $nextPreReleaseLabel = $preReleaseLabel
            }

            $nextVersionString = "$($version.major).$($version.minor).$($version.patch+1)-$($nextPreReleaseLabel)v001"
            $nextVersion = [semver]::New($nextVersionString)
        }elseIf($initialPreRelease){
            if(!$preReleaseLabel){
                $nextPreReleaseLabel = $defaultPrereleaseLabel
            }else{
                $nextPreReleaseLabel = $preReleaseLabel
            }
            write-verbose 'Start at v1 prerelease v001'
            $nextVersionString = "1.0.0-$($nextPreReleaseLabel)v001"
            $nextVersion = [semver]::New($nextVersionString)
        }elseIf($stableRelease)
        {
            write-verbose 'Mark release as stable'
            #This scenario is for when we have a pre-release tag and we want to drop it for a stable release version
            if(!($version.PreReleaseLabel))
            {
                throw 'version supplied does not contain a prerelease'
            }

            $nextVersionString = "$($version.major).$($version.minor).$($version.patch)"
            $nextVersion = [semver]::New($nextVersionString)
            write-verbose "Stable Release Version: $($nextVersion.tostring())"

        }

        return $nextVersion

    }
    
}
function get-mfScriptAnalyzerSummary
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
            
    #>

    [CmdletBinding()]
    PARAM(
        #PARAM DESCRIPTION
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("p1")]
        [string]$sourcePath = $(join-path $(join-path '.' -childPath 'source') -childPath functions),
        [parameter()]
        [string[]]$severity = @('Error','Warning','Information'),
        [Parameter(dontshow)]
        [hashtable]$weights = @{
            Error = 50
            Warning = 15
            Information = 1
        },
        [Parameter()]
        [switch]$suppressOutput,
        [Parameter()]
        [string[]]$excludeRules = @(
            'PSAvoidTrailingWhitespace' #Noisy rule. Preference script readability over strict whitespace adherance
        )
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $psScriptAnalyzerSplat = @{
            severity = $severity
            ExcludeRule = $excludeRules
        }

        if(!(get-module -ListAvailable 'PSScriptAnalyzer')){
            throw 'PSScriptAnalyzer module must be present on this system for this function to work'
        }
        
    }
    
    process{
        $functionFiles = Get-ChildItem -Recurse -Include '*.ps1' -Exclude '*.Tests.ps1' -Path $sourcePath 
        #Use a GenList to avoid iterative arrays
        $capture = [System.Collections.Generic.List[object]]::new()
        write-verbose 'Try w a ArrayList'
        $functionFiles.foreach{
            remove-variable invokeResult -errorAction ignore
            if($suppressOutput)
            {
                $invokeResult = Invoke-ScriptAnalyzer -path $_.fullname @psScriptAnalyzerSplat
            }else{
                Invoke-ScriptAnalyzer -path $_.fullname @psScriptAnalyzerSplat|tee-object -variable invokeResult
            }
            $invokeResult.foreach{$capture.add($_)}
        }
        
        if($capture)
        {
            #Transform from GenList to array for better compatibility
            $capture = $capture.ToArray()
            $TopErrors = $capture.where{$_.Severity -eq 'Error'}|group-object -property 'RuleName' |Sort-Object -property 'Count' -Descending|Select-Object 'Name','Count' -first 5
            $TopWarnings = $capture.where{$_.Severity -eq 'Warning'}|group-object -property 'RuleName' |Sort-Object -property 'Count' -Descending|Select-Object 'Name','Count' -first 5
            $TopInfos = $capture.where{$_.Severity -eq 'Information'}|group-object -property 'RuleName' |Sort-Object -property 'Count' -Descending|Select-Object 'Name','Count' -first 5

            $ScriptNameGroup = $capture|group-object -property 'ScriptName'
            $ScriptNameWeighted = $ScriptNameGroup.ForEach{
                $fileFlagsGrouped = $_.Group|group-object -property 'Severity'|Select-Object 'Name','Count'
                $Errors = [int]($fileFlagsGrouped.Where{$_.Name -eq 'Error'}|Select-Object -property 'Count').count
                $Warnings = [int]($fileFlagsGrouped.Where{$_.Name -eq 'Warning'}|Select-Object -property 'Count').count
                $Informations = [int]($fileFlagsGrouped.where{$_.Name -eq 'Information'}|Select-Object -Property 'count').count
                [PSCustomObject]@{
                    ScriptName = $_.Name
                    Counter = "E:$Errors W:$Warnings I:$Informations"
                    Weight = [int]($($weights.Error * $Errors) +$($weights.Warning * $Warnings) +$($weights.Information * $Informations))
                }
            }

            $ScriptNameWeightedSelect = if($ScriptNameWeighted){
                $ScriptNameWeighted|sort-object -property weight -Descending|Select-Object -first 5
            }else{$null}

            [PSCustomObject]@{
                Errors = $($capture.where{$_.severity -eq 'Error'}.count)
                Warnings = $($capture.where{$_.severity -eq 'Warning'}.count)
                Informational = $($capture.where{$_.severity -eq 'Information'}.count)
                TopErrors = $TopErrors
                TopWarnings = $TopWarnings
                TopInformational = $TopInfos
                TopFlaggedFiles = $ScriptNameWeightedSelect 
            }
        }
        
    }
    
}
function new-mfProject
{
    <#
        .SYNOPSIS
            Capture some basic parameters, and create the scaffold file structure
            
        .DESCRIPTION
            The new-mfProject function streamlines the process of creating a scaffold (or basic structure) for a new PowerShell module.
            Whether you're building a custom module for automation, administration, or any other purpose, this function sets up the initial directory structure, essential files, and variables and properties.
            Think of it as laying the foundation for your module project.
            
        ------------
        .EXAMPLE
            new-mfProject -ModuleName "MyModule" -description "A module for automating tasks" -moduleAuthors "John Doe" -companyName "MyCompany" -moduleTags "automation", "tasks" -projectUri "https://github.com/username/repo" -iconUri "https://example.com/icon.png" -licenseUri "https://example.com/license" -RequiredModules @("Module1", "Module2") -ExternalModuleDependencies @("Dependency1", "Dependency2") -DefaultCommandPrefix "MyMod" -PrivateData @{}

            #### DESCRIPTION
            This example demonstrates how to use the 'new-mfProject' function to create a scaffold for a new PowerShell module named "MyModule". 
            It includes a description, authors, company name, tags, project URI, icon URI, license URI, required modules, external module dependencies, default command prefix, and private data.

            #### OUTPUT
            The function will create the directory structure and essential files for the new module "MyModule" in the current working directory. 
            It will also set up the specified metadata and dependencies.
            
        .NOTES
            Author: Adrian Andersson
            
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
        [alias('modulePath')]
        [string]$path = $(get-location).path,
        #Project URI. Will try and read from Git if your using a git repository.
        [Parameter()]
        [string]$projectUri = $(try{git config remote.origin.url}catch{$null}),
        # A URL to an icon representing this module.
        [Parameter()]
        [string]$iconUri,
        #URI to use for your projects license. Will try and use the license file if a projectUri is found
        [Parameter()]
        [string]$licenseUri,
        [Parameter(DontShow)]
        [string]$configFile = 'moduleForgeConfig.xml',
        #Modules that must be imported into the global environment prior to importing this module
        [Parameter()]
        [Object[]]$RequiredModules,
        #Modules that must be imported into the global environment prior to importing this module
        [Parameter()]
        [String[]]$ExternalModuleDependencies,
        [Parameter()]
        [String]$DefaultCommandPrefix,
        [Parameter()]
        [object[]]$PrivateData

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"


        #I'm not sure why I had this in here. Cannot remember.
        if($path -like '*\' -or $path -like '*/' )
        {
            Write-Verbose 'Superfluous \ or / character found at end of modulePath, removing'
            $path = $path.Substring(0,$($path.Length-1))
            Write-Verbose "New path = $path"
        }

        $configPath = join-path -path $path -childpath $configFile

    }
    
    process{

        write-verbose 'Validating Module Path'
        if(!(test-path $path))
        {
            throw "ModulePath: $path not found"
        }

        write-verbose 'Checking for Existing Config'
        if(test-path $configPath)
        {
            throw "Config already found at: $configPath"
        }


        write-verbose 'Create Folder Scaffold'
        add-mfFilesAndFolders -moduleRoot $path


        #Should we use JSON for this, or CLIXML.
        #The vote from the internet in July 2024 is stick to CLIXML for PowerShell centric projects. So we will do that
        $moduleForgeReference = get-module 'ModuleForge'|Sort-Object version -Descending|Select-Object -First 1
        if(! $moduleForgeReference)
        {
            $moduleForgeReference = get-module -listavailable 'ModuleForge'|Sort-Object version -Descending|Select-Object -First 1
        }

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
            moduleforgeVersion = $(if($moduleForgeReference){ $moduleForgeReference.Version.ToString()}else{'n/a'})
            iconUri = $iconUri
            requiredModules = $RequiredModules
            ExternalModuleDependencies = $ExternalModuleDependencies
            DefaultCommandPrefix = $DefaultCommandPrefix
            PrivateData = $PrivateData

        }

        

        write-verbose "Exporting config to: $configPath"
        try{
            $config|export-clixml $configPath
        }catch{
            throw 'Error exporting config'
        }
    }
}
function register-mfLocalPsResourceRepository
{

    <#
        .SYNOPSIS
            Add a local file-based PowerShell repository into the systems temp location
            
        .DESCRIPTION
            Allows you to test psresourceGet, as well as directly manipulate the nuget package,
            for example, to add git data to the nuspec

        .EXAMPLE
            register-mfLocalPsResourceRepository            
            #### DESCRIPTION
            Create a powershell file repository using default values.

            Repository will be called: LocalTestRepository
            Path will be where-ever [System.IO.Path]::GetTempPath() points
            
            
        .NOTES
            Author: Adrian Andersson
                    
    #>

    [CmdletBinding()]
    PARAM(
        #Name of the repository
        [Parameter()]
        [string]$repositoryName = 'LocalTestRepository',
        #Root path of the module. Uses Temp Path by default
        [Parameter()]
        [string]$path = [System.IO.Path]::GetTempPath()

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $psResourceGet = @{
            name = 'Microsoft.PowerShell.PSResourceGet'
            version = [version]::new('1.0.4')
        }

        $psResourceGetRef = get-module $psResourceGet.name -ListAvailable|Sort-Object -Property Version -Descending|Select-Object -First 1

        
        if(!$psResourceGetRef -or $psResourceGetRef.Version -lt $psResourceGet.version)
        {
            throw "Module dependancy Name: $($psResourceGet.Name) minver:$($psResourceGet.version) Not found. Please install from the PSGallery"
        }

        $repositoryLocation = join-path $path -ChildPath $repositoryName

    }
    
    process{
        
        write-verbose "Checking we dont already have a repository with name: $repositoryName"
        if(!(Get-PSResourceRepository -Name $repositoryName -erroraction Ignore))
        {
            write-verbose 'Repository not found.'

            write-verbose "Checking for drive location at:`n`t$($repositoryLocation)"
            if(!(test-path $repositoryLocation))
            {
                try{
                    New-Item -ItemType Directory -Path $repositoryLocation
                    write-verbose 'Directory Created'
                }Catch{
                    Throw 'Error creating directory'
                }
            }

            $registerSplat = @{
                Name = $repositoryName
                URI = $repositoryLocation
                Trusted = $true
            }
            write-verbose 'Registering resource repository'
            try{
                Register-PSResourceRepository @registerSplat
            }catch{
                throw 'Error creating temporary repository'
            }

            write-verbose 'Test Repository was created'
            if(!(Get-PSResourceRepository -Name $repositoryName -erroraction Ignore))
            {
                throw 'Something has gone wrong. Unable to find repository'
            }else{
                write-verbose 'Repository looks healthy'
            }


        }else{
            write-verbose "$repositoryName Found"
        }
    }
    
}
function remove-mfLocalPsResourceRepository
{

    <#
        .SYNOPSIS
            Remove the local test repository that was created with register-mfLocalPsResourceRepository
            
        .DESCRIPTION
             If a local test repository was created with the register-mfLocalPsResourceRepository, this command will remove it
             It will also remove the directory that hosted the local repository   

        .EXAMPLE
            remove-mfLocalPsResourceRepository
            
            
            
        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding()]
    PARAM(
        #Name of the repository
        [Parameter()]
        [string]$repositoryName = 'LocalTestRepository',
        #Root path of the module. Uses Temp Path by default
        [Parameter()]
        [string]$path = [System.IO.Path]::GetTempPath()

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $psResourceGet = @{
            name = 'Microsoft.PowerShell.PSResourceGet'
            version = [version]::new('1.0.4')
        }

        $psResourceGetRef = get-module $psResourceGet.name -ListAvailable|Sort-Object -Property Version -Descending|Select-Object -First 1

        
        if(!$psResourceGetRef -or $psResourceGetRef.Version -lt $psResourceGet.version)
        {
            throw "Module dependancy Name: $($psResourceGet.Name) minver:$($psResourceGet.version) Not found. Please install from the PSGallery"
        }

        $repositoryLocation = join-path $path -ChildPath $repositoryName

    }
    
    process{

        write-verbose 'Clean up the repository'
        
        write-verbose "Checking we dont already have a repository with name: $repositoryName"
        $repoRef = (Get-PSResourceRepository -Name $repositoryName -erroraction Ignore)
        if($repoRef)
        {
            write-verbose 'Repository reference found, try and remove'
            Try{
                unregister-PSResourceRepository -name $repositoryName -ErrorAction Stop
            }catch{
                throw 'Error unregistering the Resource Repository'
            }
        }

        if((test-path $repositoryLocation))
        {
            write-verbose "File folder found at: $repositoryLocation"
            try{
                remove-item $repositoryLocation -force -ErrorAction Stop -Recurse
                write-verbose 'Directory removed'
            }Catch{
                Throw 'Error Removing directory'
            }
        }
    }
    
}
function update-mfProject
{

    <#
        .SYNOPSIS
            Update the parameters of a moduleForge project
            
        .DESCRIPTION
            This command allows you to update any of the parameters that were saved with the new-mfProject function without
            having to recreate the whole project file from scratch.
            
        ------------
        .EXAMPLE
            update-mfProject -ModuleName "UpdatedModule" -description "An updated description for the module" -moduleAuthors "Jane Doe" -companyName "UpdatedCompany" -moduleTags "updated", "module" -projectUri "https://github.com/username/updated-repo" -iconUri "https://example.com/updated-icon.png" -licenseUri "https://example.com/updated-license" -RequiredModules @("UpdatedModule1", "UpdatedModule2") -ExternalModuleDependencies @("UpdatedDependency1", "UpdatedDependency2") -DefaultCommandPrefix "UpdMod" -PrivateData @{}

            #### DESCRIPTION
            This example demonstrates how to use the `update-mfProject` function to update multiple parameters of an existing module project. 
            It updates the module name, description, authors, company name, tags, project URI, icon URI, license URI, required modules, external module dependencies, default command prefix, and private data.

            #### OUTPUT
            The function will update the specified parameters in the module project configuration file.
            
        .EXAMPLE
            update-mfProject -ModuleName "UpdatedModule" -description "An updated description for the module"

            #### DESCRIPTION
            This example demonstrates how to use the `update-mfProject` function to update only the module name and description of an existing module project. 
            It leaves all other parameters unchanged.

            #### OUTPUT
            The function will update the module name and description in the module project configuration file.   
            
        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding()]
    PARAM(
        #The name of your module
        [Parameter()]
        [string]$ModuleName,
        #A description of your module. Is used as the descriptor in the module repository
        [Parameter()]
        [string]$description,
        #Minimum PowerShell version. Defaults to 7.2 as this is the current LTS version
        [Parameter()]
        [version]$minimumPsVersion,
        #Who are the primary module authors. Can expand later with add-mfmoduleAuthors command
        [Parameter()]
        [string[]]$moduleAuthors,
        #Company Name. If you are building this module for your organisation, this is where it goes
        [Parameter()]
        [string]$companyName,
        #Module Tags. Used to help discoverability and compatibility in package repositories
        [Parameter()]
        [String[]]$moduleTags,
        #Source Code Repository to use, i.e. your repositories github/azure devops uri
        [Parameter()]
        [string]$projectUri,
        # A URL to an icon representing this module.
        [Parameter()]
        [string]$iconUri,
        #URI to use for your projects license. Will try and use the license file if a projectUri is found
        [Parameter()]
        [string]$licenseUri,
        #Modules that must be imported into the global environment prior to importing this module
        [Parameter()]
        [Object[]]$RequiredModules,
        #Modules that must be imported into the global environment prior to importing this module
        [Parameter()]
        [String[]]$ExternalModuleDependencies,
        #If you are specifying a Default Command Prefix via your manifest, this will update that prefix
        [Parameter()]
        [String[]]$DefaultCommandPrefix,
        #If you have any additional Private Data you want to add to your module manifest, add it here
        [Parameter()]
        [object[]]$PrivateData,
        #Root path of the module. Uses the current working directory by default
        [Parameter()]
        [Alias('modulePath')]
        [string]$path = $(get-location).path,
        #Module Config File
        [Parameter(DontShow)]
        [string]$configFile = 'moduleForgeConfig.xml'

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        write-verbose 'Testing module path'
        $moduleTest = get-item $path
        if(!$moduleTest){
            throw "Unable to read from $path"
        }

        $path = $moduleTest.FullName
        write-verbose "update module config in: $path"

        #Read the config file
        write-verbose 'Importing config file'
        $configPath = join-path -path $path -ChildPath $configFile

        if(!(test-path $configPath))
        {
            throw "Unable to find config file at: $configPath"
        }

        $config = import-clixml $configPath -erroraction stop
        

    }
    
    process{

        if($ModuleName)
        {
            write-verbose "Updating Module name from: $($config.moduleName) -> $($moduleName)"
            $config.moduleName = $moduleName
        }

        if($description)
        {
            write-verbose "Updating Module description from: $($config.description) -> $($description)"
            $config.description = $description
        }

        if($minimumPsVersion)
        {
            write-verbose "Updating Module minimumPsVersion from: $($config.minimumPsVersion.tostring()) -> $($minimumPsVersion.tostring())"
            $config.minimumPsVersion = $minimumPsVersion
        }

        if($moduleAuthors)
        {
            write-verbose "Updating Module moduleAuthors from: $($config.moduleAuthors) -> $($moduleAuthors)"
            $config.moduleAuthors = $moduleAuthors
        }

        if($companyName)
        {
            write-verbose "Updating Module companyName from: $($config.companyName) -> $($companyName)"
            $config.companyName = $companyName
        }

        if($moduleTags)
        {
            write-verbose "Updating Module tags from: $($config.tags) -> $($tags)"
            $config.tags = $moduleTags
        }

        if($projectUri)
        {
            write-verbose "Updating Module projectUri from: $($config.projectUri) -> $($projectUri)"
            $config.projectUri = $projectUri
        }

        if($iconUri)
        {
            write-verbose "Updating Module iconUri from: $($config.iconUri) -> $($iconUri)"
            $config.iconUri = $iconUri
        }

        if($licenseUri)
        {
            write-verbose "Updating Module licenseUri from: $($config.licenseUri) -> $($licenseUri)"
            $config.licenseUri = $licenseUri
        }
        if($RequiredModules)
        {
            write-verbose "Updating Module RequiredModules from: $($config.RequiredModules|convertTo-json -depth 4)`n`n`t ->`n $($RequiredModules|convertTo-json -depth 4)"
            $config.RequiredModules = $RequiredModules
        }

        if($ExternalModuleDependencies)
        {
            write-verbose "Updating Module ExternalModuleDependencies from: $($config.ExternalModuleDependencies -join '; ') -> $($ExternalModuleDependencies -join '; ')"
            $config.ExternalModuleDependencies = $ExternalModuleDependencies
        }

        if($DefaultCommandPrefix)
        {
            write-verbose "Updating Module DefaultCommandPrefix from: $($config.DefaultCommandPrefix) -> $($DefaultCommandPrefix)"
            $config.DefaultCommandPrefix = $DefaultCommandPrefix
        }

        if($PrivateData)
        {
            write-verbose "Updating Module PrivateData from: $($config.PrivateData|convertTo-json -depth 4)`n`n`t ->`n $($PrivateData|convertTo-json -depth 4)"
            $config.PrivateData = $PrivateData
        }

        write-verbose "Exporting config to: $configPath"
        try{
            $config|export-clixml $configPath
        }catch{
            throw 'Error exporting config'
        }
    }
}
function write-mfModuleDocs
{

    <#
        .SYNOPSIS
            Generates and updates function documentation using PlatyPS, and creates an index for module functions.

        .DESCRIPTION
            This function automates documentation generation based on module functions, leveraging PlatyPS to create and update Markdown help files.
            It also builds an `index.md` file for organizing documentation, making it easier to integrate with GitHub Pages or other documentation platforms.
            Additionally, if specified, it includes a changelog based on Git commits.

        .EXAMPLE
            write-mfModuleDocs -ModuleName 'MyCustomModule' -includeChangeLog

            #### DESCRIPTION
            Builds documentation for `MyCustomModule` and includes a full Git-based changelog (`changeLog.md`) alongside function help files.

        .EXAMPLE
            write-mfModuleDocs -ModuleName 'MyCustomModule' -skipIndex

            #### DESCRIPTION
            Generates function documentation without updating `index.md`.

        .INPUTS
            [string] - Path is accepted as pipeline input or via direct assignment. It has a defaulf value and does not need to be set

        .NOTES
            Author: Adrian Andersson
            
    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseSingularNouns", "", Justification = "Plural 'Docs' reflects a short form of documentation")]
    PARAM(
        #The root path where documentation should be stored. Defaults to the current directory.
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [alias('modulePath')]
        [string]$Path = $(get-item .).fullname,
        #The name of the PowerShell module for which documentation should be generated.
        [Parameter(Mandatory)]
        [alias('module')]
        [ValidateScript({ Get-Module -Name $_ -ErrorAction SilentlyContinue })]
        [string]$ModuleName,
        #Specifies the subfolder within `docsFolder` where function-specific documentation should be stored. Defaults to `functions`.
        [Parameter()]
        [alias('docsPath')]
        [string]$docsFolder = 'docs',
        #Specifies the subfolder within `docsFolder` where function-specific documentation should be stored. Defaults to `functions`.
        [Parameter()]
        [alias('functionsPath')]
        [string]$functionsFolder = 'functions',
        #If specified, retrieves and includes a Markdown changelog based on Git commit history.
        [Parameter()]
        [switch]$includeChangeLog,
        #If specified, skips creating or updating the `index.md` file.
        [Parameter()]
        [switch]$skipIndex
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $platyPs = (get-module -Name PlatyPS -ListAvailable|Sort-Object -Property version -Descending|select-object -first 1)
        if($platyPs)
        {
            write-verbose "Build Function Documentation with PlatyPS Version $($platyPs.version)"
        }else{
            throw "This function relies on module PlatyPS. Please install it from the PSGallery"
        }

        $module = (get-module -Name $ModuleName|Sort-Object -Property version -Descending|select-object -first 1)
        if($module)
        {
            write-verbose "Build Function Documentation for Module $ModuleName - version: $($module.version)"
        }else{
            throw "Module is not pre-loaded. Please import the module first"
        }

        $customFolderSelect = @(
            'name'
            'basename'
            @{
                name = 'baseFolder'
                expression = {$($_.Directory.FullName.replace($DocsFullPath,''))}
            }
            @{
                name = 'leaf'
                expression = {$(split-path -path $_.Directory.FullName -leaf)}
            }
            @{
                name = 'relLink'
                expression = {("./$($($_.Directory.FullName.replace($DocsFullPath,'')).replace('\','/'))/$($_.name)").replace('//','/')}
            }
            @{
                name = 'subjectGroup'
                expression = {("$($($_.Directory.FullName.replace($DocsFullPath,'')).replace('\','/'))").replace('//','/').trimStart('/')}
            }
        )

        
    }
    
    process{
        #Checks and parses
        write-verbose "In path $path"
        $DocsFullPath = join-path -Path $Path -ChildPath $docsFolder
        if(!(test-path $DocsFullPath))
        {
            write-verbose 'Need to make docs folder as it does not exist'
            New-Item -ItemType Directory -Path $DocsFullPath
        }

        $functionsFullPath = join-path -Path $DocsFullPath -ChildPath $functionsFolder
        if(!(test-path $functionsFullPath))
        {
            write-verbose 'Need to make functions folder as it does not exist'
            New-Item -ItemType Directory -Path $functionsFullPath
        }else{
            write-verbose 'Recreating Functions Folder'
            try{
                remove-item $functionsFullPath -ErrorAction Stop -Force -Recurse
            }catch{
                throw 'Error cleaning up existing functions folder'
            }
            New-Item -ItemType Directory -Path $functionsFullPath
        }
        
        #Actual Process
        write-verbose 'Create markdown help from module help'
        New-MarkdownHelp -Module $module.Name -Force -OutputFolder $functionsFullPath

        if($includeChangeLog)
        {
            write-verbose 'Creating releaseNotes file'
            $changeLog = get-mfGitChangeLog -all
            write-verbose "ChangeLog: `n$($changeLog)"
            if($changeLog)
            {
                $changeLogPath = Join-Path $DocsFullPath -ChildPath 'changeLog.md'
                $changeLog | Out-File -FilePath $changeLogPath -Force 
            }else{
                write-warning 'changeLog notes were not captured as none existed, or something went wrong'
            }
        }

        if($skipIndex){
            Write-Verbose 'Skipping Index File'
        }else{
            $indexContent = [System.Collections.Generic.List[string]]::new()
            $indexContent.add("# Documentation Index`n")
            $folderContent = Get-ChildItem -Path  $DocsFullPath -Filter '*.md' -Recurse|Select-Object $customFolderSelect
            $folderGroup = $folderContent|Group-Object -Property 'subjectGroup'
            ($folderGroup.where{$_.'name' -eq ''}.group).foreach{
                if($_.'basename' -ne 'index')
                {
                    $indexContent.add("- [$($_.baseName)]($($_.relLink))")
                }
    
            }
            $folderGroup.where{$_.'name' -ne ''}.forEach{

                $indexContent.add("`n## $($_.'name')`n")
                $_.group.foreach{
                    $indexContent.add("- [$($_.baseName)]($($_.relLink))")
                }
            }
            write-verbose 'Create Index File'
            $indexPath = Join-Path $DocsFullPath -ChildPath 'index.md'
            $indexContent -join "`n"|out-file $indexPath -Force
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
            
    #>

    [CmdletBinding()]
    PARAM(
        #Root Path for module folder. Assume current working directory
        [Parameter(ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string]$moduleRoot = (Get-Item .).FullName #Use the fullname so that we don't have problems with PSDrive, symlinks, confusing bits etc
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $rootDirectories = @('source')
        $sourceDirectories = @('functions','enums','classes','filters','validationClasses','private','bin','resource')
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
                write-information "Directory: $fullpath not found. Will create" -tags 'FileCreation'
                try{
                    $result = new-item -itemtype directory -Path $fullPath -ErrorAction Stop
                }catch{
                    throw "Unable to make new directory: $result. Please check permissions and conflicts"
                }
            }

           

            if($_ -eq 'source')
            {
                write-verbose 'Source Folder: Checking for subdirectories and files in source folder'
                $sourceDirectories.foreach{
                    $subdirectoryFullPath = join-path -path $fullPath -childPath $_
                    
                    if(test-path $subdirectoryFullPath)
                    {
                        write-verbose "Directory: $subdirectoryFullPath is OK"
                    }else{
                        write-information "Directory: $subdirectoryFullPath not found. Will create" -tags 'FileCreation'
                        try{
                            $null = new-item -itemtype directory -Path $subdirectoryFullPath -ErrorAction Stop
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
                            write-information "File: $filePath not found. Will create" -tags 'FileCreation'
                            try{
                                $null = new-item -itemtype File -Path $filePath -ErrorAction Stop
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
#Support function for get-mfDependencyTree

function printTree {
    param(
        [string]$node,
        [int]$level = 0
    )

    $indent = '    ' * $level
    write-output "$indent >--DEPENDS-ON--> $node"
    if ($tree.ContainsKey($node)) {
        foreach ($child in $tree[$node]) {
            printTree -node $child -level ($level + 1)
        }
    }
}
