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
        [string]$configFile = 'moduleForgeConfig.xml'
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
        [array]$folders = @('enums','functions','filters','validationClasses','dscClasses','classes','private')


        $sourceFolder = join-path -path $modulePath -childPath 'source'


    }
    
    process{

        write-verbose "Attempt to build: $versionString"



        $moduleFile = join-path $moduleOutputFolder -ChildPath "$($config.moduleName).psm1"
        $manifestFile = join-path $moduleOutputFolder -ChildPath "$($config.moduleName).psd1"
        write-verbose "Will create module in: $moduleOutputFolder; Module Filename: $($config.moduleName).psm1; Manifest Filename:$($config.moduleName).psd1"

        write-verbose 'Adding Header'
        $moduleHeader|out-file $moduleFile -Force

        foreach($folder in $folders)
        {
            write-process "Processing folder: $folder"

            $fullFolderPath = join-path -path $sourceFolder -ChildPath $folder
            $folderItems = get-mfFolderItems -path $fullFolderPath -psScriptsOnly
            if($folderItems.count -gt 1) #Now we are on PS7 we don't need to worry about measure-object
            {
                write-verbose "$($folderItems.Count) Files found, getting content"

                switch ($folder) {
                    's'  {  }
                    Default {}
                }

            }



        }



        
    }
    
}