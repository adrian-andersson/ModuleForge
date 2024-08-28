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

                2024-08-28 - AA
                    - Need to fix the xml space, I put in type but it should be repository
                    
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