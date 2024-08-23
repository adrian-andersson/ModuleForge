<#
Module Mixed by BarTender
	A Framework for making PowerShell Modules
	Version: 6.2.0
	Author: Adrian.Andersson
	Copyright: 2020 Domain Group

Module Details:
	Module: ModuleForge
	Description: ModuleForge is a PowerShell scaffolding and build tool for creating other PowerShell modules. With ModuleForge, you can easily generate the foundational structure, boilerplate code, and github actions build techniques
	Revision: 0.0.46.1
	Author: Adrian Andersson
	Company:  

Check Manifest for more details
#>

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
            
            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                2024-08-08 - AA
                    - Initial Attempt
                    
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
            $newElement = $nuSpecXml.CreateElement("type",$nuSpecXml.package.namespaceURI)
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

                2024-08-23 - AA
                    - Change the build to use the folderItemDetails, should lead to a faster pass
                    - Added informational output stream to the build, should make for nice Orchestration stream
                    
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
       
        #Better Order
        [array]$folders = @('enums','validationClasses','classes','dscClasses','functions','private','filters')


        $sourceFolder = join-path -path $modulePath -childPath 'source'

        #What folders do we need to copy the files directly in
        [array]$copyFolders = @('resource','bin')

        $scriptsToProcess = New-Object System.Collections.Generic.List[string]
        $functionsToExport = New-Object System.Collections.Generic.List[string]
        $nestedModules = New-Object System.Collections.Generic.List[string]

        $DscResourcesToExport = New-Object System.Collections.Generic.List[string]

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
        <#
        if($fileList.count -ge 1)
        {
            write-verbose "Included in fileList: $($fileList.ToArray() -join ',')"
            [array]$splatManifest.fileList = [array]$fileList.ToArray()
        }
        #>

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
            
            
            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
            2024-08-11 - AA
                - Initial script
                - Bit of an experimental function this one
                    
    #>

    [CmdletBinding()]
    PARAM(
        #What Reference Data are we looking at. See function example for how to retrieve
        [Parameter(Mandatory)]
        [object[]]$referenceData,
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
            including: The content of PS1 files, the names of any functions, any dependencies

            This function uses a job to import all the ps1 items so that all types can be reflected correctly without having to load the module
            
        ------------
        .EXAMPLE
            get-mfFolderItemDetails .\source
            
            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                2024-07-27 AA
                    - First Refactor
                2024-08-12 AA
                    - Improve the relativePath code
                    - Add a folderGroup passthrough
                    - Need to figure out a better way for importing the module
                    
    #>

    [CmdletBinding()]
    PARAM(
        #Path to source folder.
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string]$path
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
                #Clumsy way of doing this list, could just do array with +
                #Feel like this is slightly neater and easier to turn bits off or expand
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
        $global:dbgScriptBlock = $sblock

        write-verbose 'Getting Folder Items'

        [array]$folders = @('enums','validationClasses','classes','dscClasses','functions','private','filters')
        $folderItems = $folders.ForEach{
            $folderPath = Join-Path $path -ChildPath $_
            get-mfFolderItems -path $folderPath -psScriptsOnly
        }

        write-verbose 'Starting Job'
        $job = Start-Job -ScriptBlock $sblock -ArgumentList @($path, $folderItems)
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
            Get a list of files from a folder - whilst processing the .mfignore and .mforder files
            
        .DESCRIPTION
             Get the files out of a folder. Adds a bit of smarts to it such as:
             - Ignore anything in the .mfignore file
             - Filter out anything that isn't a PS1 file if, with a switch
             - Ignore files with .test.ps1 - These are assumed to be pester files
             - Ignore files with .tests.ps1 - These are assumed to be pester files
             - Ignore files with .skip.ps1 - These are assumed to be skippable

            
           

              Will always return a full path name
            
        ------------
        .EXAMPLE
            get-mfFolderItems '.\source\functions\example.ps1'
            
            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                2024-07-22 - AA
                    - Refactored from Bartender
                    - Made much faster and more modern

                2024-08-23 - AA
                    - Added the .bt files as exclusions to help with Bartender backwards compatibility
                    
    #>

    [CmdletBinding(DefaultParameterSetName='Default')]
    PARAM(
        #Path to start in
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

function get-mfNextSemver
{

    <#
    .SYNOPSIS
        Increments the version of a Semantic Version (SemVer) object.

    .DESCRIPTION
        The `get-mfNextSemver` function takes a Semantic Version (SemVer) object as input and increments the version based on the 'increment' parameter. It can handle major, minor, and patch increments. The function also handles pre-release versions and allows the user to optionally override the pre-release label.

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

    .NOTES
        Author: Adrian Andersson

        Changelog:

            2024-08-10 - AA
                - First attempt at incrementing the Semver
                   
    #>

    [CmdletBinding()]
    PARAM(
        #Semver Version
        [Parameter(Mandatory)]
        [SemVer]$version,

        #What are we incrementing
        [Parameter()]
        [ValidateSet('Major','Minor','Patch')]
        [string]$increment,

        #Is this a prerelease
        [Parameter()]
        [switch]$prerelease,

        #Optional override the prerelease label. If not supplied will use 'prerelease'
        [Parameter()]
        [string]$preReleaseLabel
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $defaultPrereleaseLabel = 'prerelease'

        if (-not $increment -and -not $prerelease) {
            throw 'At least one of "increment" parameter or "prerelease" switch should be supplied.'
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
            $currentPreReleaseSplit = $version.PreReleaseLabel.Split('.')
            $currentpreReleaseLabel = $currentPreReleaseSplit[0]
            if(!$preReleaseLabel -or ($currentpreReleaseLabel -eq $preReleaseLabel)){
                write-verbose 'No change to prerelease label'
                $nextPreReleaseLabel = $currentpreReleaseLabel
                $currentPreReleaseInt = [int]$currentPreReleaseSplit[1]
                $nextPrerelease = $currentPreReleaseInt+1
                

            }else{
                write-verbose 'Prerelease label changed. Resetting prerelease version to 1'
                $nextPreReleaseLabel = $preReleaseLabel
                $nextPreRelease = 1
            }
            
            $nextVersionString = "$($version.major).$($version.minor).$($version.patch)-$($nextPreReleaseLabel).$($nextPrerelease)"
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

            $nextVersionString = "$($nextVersion.major).$($nextVersion.minor).$($nextVersion.patch)-$($nextPreReleaseLabel).1"
            $nextVersion = [semver]::New($nextVersionString)
            write-verbose "Next Prerelease will be: $($nextVersion.ToString())"
        }

        return $nextVersion


    }
    
}

function Get-mfScriptFunctionDetails
{

    <#
        .SYNOPSIS
            Identify functions and classes in a PS1 file, return the name of the function along with the actual content of the file.
            
        .DESCRIPTION
            Used to pull the names of functions and classes from a PS1 file, and return them in an object along with the content itself.
            This will provide a way to get the names of functions and resources as well as copying the content cleanly into a module file.
            It works best when you keep to single types (Classes or Functions) in a file.
            By returning the function and dscResource names, we can also compile what we need to export in a module manifest

            
            
        ------------
        .EXAMPLE
            get-mfScriptText c:\myFile.ps1 -scriptType function
            
            
            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                2024-07-28 - AA
                    - Refactored from Bartender

                2024-08-02
                    - Suspect this is superceded with the moduleDependency stuff

                2024-08-12
                    - Add a passthrough param for folderGroup
                    
    #>

    param(
        [Parameter(Mandatory)]
        [string]$Path,
        #Passthrough Relative Path from get-mfFolderItems
        [Parameter()]
        [string]$RelativePath,
        #What type of file are we looking at, is it expected we will have Classes, Functions or a mix of everything
        [ValidateSet('Class','Function','All')]
        [Parameter()]
        [string]$type = 'All',
        #Passthrough param for FolderGroup
        [Parameter()]
        [string]$folderGroup
    )

    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"


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
        
        
        write-verbose 'Using PowerShell Parser on file'
        $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
        write-verbose 'Extracting Functions and Classes'
        $Functions = $AST.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        $Classes = $AST.FindAll({ $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] }, $true)

        #$functionDetails = New-Object System.Collections.Generic.List[string]
    
        
    
        if($type -eq 'All' -or $type -eq 'Function')
        {
            $functionDetails = foreach ($Function in $Functions) {


                $cmdletDependenciesList = New-Object System.Collections.Generic.List[string]
                $typeDependenciesList = New-Object System.Collections.Generic.List[string]
                $paramTypeDependenciesList = New-Object System.Collections.Generic.List[string]
                $validatorTypeDependenciesList = New-Object System.Collections.Generic.List[string]
                #$validatorTypeDependenciesList2 = New-Object System.Collections.Generic.List[string]
        
                write-verbose "Checking Function: $functionName"
                $FunctionName = $Function.Name
        
        
                write-verbose 'Finding Function Dependencies'
                $Cmdlets = $Function.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)
        
                
                foreach($c in $Cmdlets)
                {
                    $cmdletDependenciesList.add($c.GetCommandName())
                }
        
                write-verbose 'Finding Type and Class Dependencies'
                $TypeExpressions = $Function.FindAll({ $args[0] -is [System.Management.Automation.Language.TypeExpressionAst] }, $true)
                $TypeExpressions.TypeName.FullName.foreach{
                    write-verbose "Need to clean up: $($_)"
                    $tname = $_
                    [string]$tnameReplace = $($tname.Replace('[','')).replace(']','')
                    $typeDependenciesList.add($tnameReplace)
                }


                write-verbose 'Finding Function Parameter Types'
                $Parameters = $Function.Body.ParamBlock.Parameters
                $Parameters.StaticType.Name.foreach{$paramTypeDependenciesList.add($_)}
                #$Parameters.Attributes.Typename.Fullname.where{$_ -notin $paramTypeDependenciesList}.foreach{$validatorTypeDependenciesList.Add($_)}



                write-verbose 'Finding Validators'
                $attributes = $Parameters.Attributes
                foreach($att in $attributes)
                {
                    $refType = $att.TypeName.GetReflectionType()

                    write-verbose "refType for $($att.TypeName.FullName): $refType"

        
                    if($refType -and ($refType.IsSubclassOf([System.Management.Automation.ValidateArgumentsAttribute]) -or [System.Management.Automation.ValidateArgumentsAttribute].IsAssignableFrom($refType))) {
                        [string]$tname = $Att.TypeName.FullName
                        [string]$tname = $($tname.Replace('[','')).replace(']','')
                        $validatorTypeDependenciesList.Add($tname)
                    }
                }
        
                [psCustomObject]@{
                    functionName = $FunctionName
                    cmdLets = $cmdletDependenciesList|group-object|Select-Object Name,Count
                    #types = $TypeExpressions|group-object|Select-Object Name,Count
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
            new-mfProject -ModuleName "MyModule" -description "A module for automating tasks" -moduleAuthors "John Doe" -companyName "MyCompany" -moduleTags "automation", "tasks" -projectUri "https://github.com/username/repo" -iconUri "https://example.com/icon.png" -licenseUri "https://example.com/license" -RequiredModules @("Module1", "Module2") -ExternalModuleDependencies @("Dependency1", "Dependency2") -DefaultCommandPrefix "MyMod" -PrivateData @{}

            #### DESCRIPTION
            This example demonstrates how to use the `new-mfProject` function to create a scaffold for a new PowerShell module named "MyModule". 
            It includes a description, authors, company name, tags, project URI, icon URI, license URI, required modules, external module dependencies, default command prefix, and private data.

            #### OUTPUT
            The function will create the directory structure and essential files for the new module "MyModule" in the current working directory. 
            It will also set up the specified metadata and dependencies.
            
            
            
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
        [String[]]$DefaultCommandPrefix,
        [Parameter()]
        [object[]]$PrivateData

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
        add-mfFilesAndFolders -moduleRoot $modulePath

       

        if($projectUri -and !$licenseUri)
        {
            if(test-path $(join-path -path $modulePath -childPath 'LICENSE'))
            {
                $licenseUri = "$projectUri\LICENSE"
            }
        }

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
            moduleforgeVersion = $moduleForgeReference.Version.ToString()
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

function publish-mfGithubPackage
{

    <#
        .SYNOPSIS
            Push an updated PowerShell NUPKG to github packages
            
        .DESCRIPTION
            This function uploads a specified PowerShell NUPKG file to a GitHub repository. 
            It should be executed after updating the NUSPEC XML file to ensure the package metadata is current.
            
        .EXAMPLE
            publish-mfGithubPackage -repositoryUri "https://api.github.com/repos/username/repo" -NugetPackagePath "C:\path\to\package.nupkg" -githubToken (Get-Credential)
            
            #### DESCRIPTION
            This example demonstrates how to use the `publish-mfGithubPackage` function to upload a NUPKG file to a GitHub repository. 
            The `repositoryUri` parameter specifies the GitHub repository URI, `NugetPackagePath` is the path to the NUPKG file, 
            and `githubToken` is the PSCredential object containing the GitHub token.
            
            #### OUTPUT
            The function will output verbose messages indicating the progress of the upload process. 
            If successful, the NUPKG file will be uploaded to the specified GitHub repository.
            
            
            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                2024-08-09 - AA
                    - Initial script
                    
    #>

    [CmdletBinding()]
    PARAM(
         #RepositoryUri
         [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
         [string]$repositoryUri,
         #Path to the actual file in the repository, should be something like C:\Users\{UserName}\AppData\Local\Temp\LocalTestRepository\{ModuleName}.{ModuleVersion}.nupkg
         [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
         [string]$NugetPackagePath,
         #github token to use to publish. Uses a PSCredential Object, but username is not used
         [Parameter(Mandatory)]
         [pscredential]$githubToken
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        
    }
    
    process{

        write-verbose 'Checking nupkg is valid'
        $nuPackage = get-item $NugetPackagePath
        if(!$nuPackage)
        {
            throw "Unable to find: $NugetPackagePath"
        }

        if($nuPackage.Extension -ne '.nupkg')
        {
            throw "$NugetPackagePath not a .nupkg file"
        }

        if($repositoryUri[-1] -eq '/')
        {
            write-verbose 'Fixing URI'
            $repositoryUri = $repositoryUri.Substring(0,($repositoryUri.Length-1))
        }

        # Read the file content
        $fileContent = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($nuPackage.FullName))

        # Create the JSON body
        $jsonBody = @{
            "message" = "Upload .nupkg file"
            "content" = $fileContent
        } | ConvertTo-Json

        $uploadUri = "$($repositoryUri)/contents/$($nupackage.name)"
        write-verbose "Upload URI is: $uploadUri"

        $headers = @{
            Authorization = "token $($githubToken.GetNetworkCredential().Password)"
            Accept = 'application/vnd.github.v3+json'
        }

        $restSplat = @{
            URI = $uploadUri
            Headers = $headers
            Method = 'Put'
            Body = $jsonBody
        }

        Invoke-RestMethod @restSplat
        
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
            
            
            Changelog:
            
                2024-07-26 - AA
                    - Created function to register repository
                    
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
            
            
            Changelog:
            
                2024-07-26 - AA
                    - Created function to clean-up repository
                    
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
            
            
            Changelog:
            
                2024-07-22 - AA
                    - Refactored from Bartender
                    
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
        #Root path of the module. Uses the current working directory by default
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
        [Parameter()]
        [String[]]$DefaultCommandPrefix,
        [Parameter()]
        [object[]]$PrivateData,
         #Root path of the module. Uses the current working directory by default
        [string]$modulePath = $(get-location).path,
        [Parameter(DontShow)]
        [string]$configFile = 'moduleForgeConfig.xml'

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
            write-verbose "Updating Module tags from: $($config.moduleTags) -> $($moduleTags)"
            $config.moduleTags = $moduleTags
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
        [Parameter(ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string]$moduleRoot = (Get-Item .).FullName #Use the fullname so that we don't have problems with PSDrive, symlinks, confusing bits etc
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $rootDirectories = @('documentation','source')
        $sourceDirectories = @('functions','enums','classes','filters','dscClasses','validationClasses','private','bin','resource')
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
                write-verbose 'Source Folder: Checking for subdirectories and files in source folder'
                $sourceDirectories.foreach{
                    $subdirectoryFullPath = join-path -path $fullPath -childPath $_
                    
                    if(test-path $subdirectoryFullPath)
                    {
                        write-verbose "Directory: $subdirectoryFullPath is OK"
                    }else{
                        write-warning "Directory: $subdirectoryFullPath not found. Will create"
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
                            write-warning "File: $filePath not found. Will create"
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
                2024-08-12
                    - Suspect deprecated, leave for compatibility or revisit
                    
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

