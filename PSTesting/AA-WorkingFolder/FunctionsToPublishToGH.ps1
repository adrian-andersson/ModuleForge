#This is an amazing amount of code required just to get a module published to GHRepositories



#OK whats needed
#Download the latest powershellget beta -- Done
#Add local repository -- Done
#Publish to local repository -- Done
#Update nuspec in local repository -- Done
#Repack local repository -- Done
#Publish to GH repository -- Done
#Fix all the function MetaData
#Test a deployment
#Create a function that runs all these together



function import-psGetBetaMOdule
{

    <#
        .SYNOPSIS
            Import, download the latest PSGet Beta
            
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
        #PowershellGet Beta Save location
        [Parameter()]
        [string]$powershellBetaPath = 'C:\powershellGetBeta',
        #Minimum PSGet Version
        [Parameter()]
        [version]$minVer = [version]::new('3.0.17')
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        $moduleName = 'PowerShellGet'
        $modulesPath = "$powershellBetaPath\$moduleName"

        function get-versionsAvailable {
            $versionSelect = @(
                'FullName',
                'CreationTime',
                'Name',
                @{
                    Name = 'Version'
                    Expression = {[version]::new($_.Name)}
                }
            )
            
            get-childItem $modulesPath |Select-Object $versionSelect|Sort-Object -Property 'version' -Descending
            
        }

        function start-powershellGetBetaDownload {


            if(!(test-path $powershellBetaPath -ErrorAction Ignore)){
                new-item -ItemType Directory -Force -Path $powershellBetaPath
            }
            write-warning 'Attempting Download'
            find-module -Repository psgallery -AllowPrerelease -Name powershellget|Save-Module $powershellBetaPath

        }

        if($PSVersionTable.PSVersion -lt 7.2 -or $PSVersionTable.platform -ne 'Win32NT')
        {
            throw 'Your on PowerShell less than 7.2, or your not using Windows. Try changing platforms and using latest version of PowerShell'
        }


        
        
    }
    
    process{

        $versionsAvailable = get-versionsAvailable

        #Check what versions we have imported currently
        $currentLoadedPSGet = get-module -Name powershellget|Sort-Object -Property version -Descending|Select-Object -first 1
        #Lets just hypothesis that at the moment we want, lets just go with 3.0.17 for now
        $minVer = [version]::new('3.0.17')
        if(!$currentLoadedPSGet)
        {
            write-warning 'No version loaded'
            if($versionsAvailable -and $versionsAvailable[0].Version -ge $minVer)
            {

                #throw "You have a version available to import.`nTry and import first with:`nimport-module '$($versionsAvailable[0].FullName)\$($moduleName).psd1'"
                import-module "$($versionsAvailable[0].FullName)\$($moduleName).psd1"
                write-warning 'Module Imported'
                
            }else{
                write-warning 'powershellget beta module not found on this PC'
                #throw "You need the PowershellGet 3 Beta Module`nTry downloading the latest PowershellGet BETA with:`nfind-module -Repository psgallery -AllowPrerelease -Name powershellget|save-module -path $powershellBetaPath`nThen import your new module from the save path"
                start-powershellGetBetaDownload
                $versionsAvailable = get-versionsAvailable
                import-module "$($versionsAvailable[0].FullName)\$($moduleName).psd1"
                write-warning 'Module should have downloaded and imported'
                
            }
        }elseIf($currentLoadedPSGet.version -lt $minVer -and $currentLoadedPSGet.Version.major -ge 3){
            write-warning "Youve imported PowershellGet 3, but the version your on is out-of-date. Need at least $($minver.tostring())"
            start-powershellGetBetaDownload
            $versionsAvailable = get-versionsAvailable
            import-module "$($versionsAvailable[0].FullName)\$($moduleName).psd1"
            write-warning 'Module should have updated and imported'
        }elseIf($currentLoadedPSGet.version -lt $minVer -and $currentLoadedPSGet.Version.major -lt 3){
            write-warning "Youve imported a PowerShellGet version less than 3. Need at least $($minver.tostring())."
            start-powershellGetBetaDownload
            $versionsAvailable = get-versionsAvailable
            import-module "$($versionsAvailable[0].FullName)\$($moduleName).psd1"
            write-warning 'Module should have downloaded and imported'
        }elseIf($currentLoadedPSGet.version -ge $minVer ){
            write-warning "Your running $($currentLoadedPSGet.Version.tostring()) - Minver - $($minver.tostring()). Should be good to go"
        }else{
            write-warning 'How did we end up in this block.... Are you a witch?'
        }
    }
    
}

function add-psGetLocalRepository
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
        #LocalRepository File Path
        [Parameter(DontShow)]
        [string]$localRepositoryFilePath = 'c:\nuget\publish',
        #LocalRepository File Path
        [Parameter(DontShow)]
        [string]$repoName = 'nuget-local'

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        
        
        if(!(test-path $localRepoPath))
        {
            New-Item -ItemType directory -Path $localRepoPath
        }

        import-psGetBeta
    }
    
    process{
        if(!(Get-PSResourceRepository $repoName -erroraction ignore))
        {
            Register-PSResourceRepository -Name $repoName -URI $localRepoPath
        }  
        
    }
    
}

function publish-psGetLocal
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
        #RepositoryPath
        [Parameter(Mandatory)]
        [string]$repositoryPath,
        #RepositoryPath
        [Parameter(DontShow)]
        [string]$repoName = 'nuget-local'
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        
    }
    
    process{
        Publish-PSResource -path $repositoryPath -Repository $repoName -confirm:$true
        
    }   
}

function update-psGetLocalNuspec
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
        #Module Name
        [Parameter(Mandatory)]
        [string]$moduleName,
        #$github Repository URI
        [Parameter()]
        [string]$repositoryUri = 'https://github.com/domain-platform-engineering/legacy-powershell-modules',
        #Module Version
        [Parameter()]
        [Version]$ModuleVersion,
        #LocalRepository File Path
        [Parameter(DontShow)]
        [string]$localRepositoryFilePath = 'c:\nuget\publish',
        #ExtractionPath
        [Parameter(DontShow)]
        [string]$extractPath = 'c:\nuget\extract'
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        

        function get-moduleVersions{
            $folderSelect = @(
                'fullname'
                'lastwritetime'
                'length'
                'name'
                @{
                    name = 'version'
                    expression = {[version]::new($_.name.split("$moduleName.")[1].split('.nupkg')[0])}
                }
            )

            get-childitem -path $localRepositoryFilePath -Filter "$moduleName.*"|Select-Object $folderSelect

        }
    }
    
    process{
        $moduleVersions = get-moduleVersions
        if(!$moduleVersions)
        {
            throw "Unable to find $moduleName in local repository file location"
        }

        if($moduleVersion)
        {
            $selectedModule = $moduleVersions.where{$_.version -eq $ModuleVersion}
        }else{
            write-verbose 'Version not specified. Processing newest'
            $selectedModule = $moduleVersions|Sort-object -Property version -Descending|Select-Object -First 1
        }

        if($selectedModule)
        {

            #Make sure we are always working clean
            if(! (test-path $ExtractPath))
            {
                New-Item -Path $ExtractPath -ItemType Directory |Out-Null
            }else{
                get-item -Path $ExtractPath |remove-item -recurse -force
                New-Item -Path $ExtractPath -ItemType Directory |Out-Null
            }


            expand-archive -Path $selectedModule.fullname -DestinationPath $ExtractPath
            #Find the Nuspec file 
            $nuSpec = get-childitem $ExtractPath -filter "*.nuspec"
            if($nuSpec -and $nuSpec.count -eq 1)
            {
                #$nuSpec
                $nuSpecName = $nuSpec.name
                $nuSpecPath = $nuSpec.fullname
                #Add nuget xml things
                $nuSpecXml = new-object -TypeName XML
                $nuSpecXml.Load($nuSpecPath)
                #Create new element, in same namespaceURI
                $newElement = $nuSpecXml.CreateElement("repository",$nuSpecXml.package.namespaceURI)
                $newElement.SetAttribute('url',$repositoryUri)
                $nuSpecXml.package.metadata.AppendChild($newElement)

                
                $nuSpecXml.Save($nuSpecPath)
                Remove-Variable nuSpecXml
                start-sleep -seconds 2
                #Now Zip it back up


                Compress-Archive -Path "$ExtractPath\*" -DestinationPath "$($selectedModule.fullname)" -force

            }else{
                throw 'no or multi nuspec'
            }

        }else{
            throw "Unable to process $moduleName in local repository file location. Version mismatch or sort error" 
        }
        

        


    }
    
}

function register-psGetGithubRepository
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
        #Repository Name
        [Parameter()]
        [string]$RepositoryName = 'DomainPlatformEngineering',
        #Repository URI
        [Parameter()]
        [string]$RepositoryURI = 'https://nuget.pkg.github.com/domain-platform-engineering/index.json',
        [Parameter()]
        [bool]$trusted = $true

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        
        import-psGetBetaMOdule
    }
    
    process{

        if(Get-PSResourceRepository $RepositoryName -erroraction ignore)
        {
            write-warning 'Repository already exists. No action required'
        }else{
            write-warning 'Need to register repository'
            $registerSplat = @{
                Name = $RepositoryName
                URI = $RepositoryURI
                Trusted = $trusted
            }
    
            Register-PSResourceRepository @registerSplat
        }

        
        
    }
    
}

function publish-psGetGithub
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
        #Github Credential. Should be username + Token
        [Parameter(Mandatory)]
        [pscredential]$credential,
        #Module Name
        [Parameter(Mandatory)]
        [string]$moduleName,
        [Parameter()]
        [string]$psResourceRepository = 'DomainPlatformEngineering',
        #Module Version
        [Parameter()]
        [Version]$ModuleVersion,
        #LocalRepository File Path
        [Parameter(DontShow)]
        [string]$localRepositoryFilePath = 'c:\nuget\publish'


    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        import-psGetBetaModule
        register-psGetGithubRepository


        $repoDetails = Get-PSResourceRepository $psResourceRepository
        

        function get-moduleVersions{
            $folderSelect = @(
                'fullname'
                'lastwritetime'
                'length'
                'name'
                @{
                    name = 'version'
                    expression = {[version]::new($_.name.split("$moduleName.")[1].split('.nupkg')[0])}
                }
            )

            get-childitem -path $localRepositoryFilePath -Filter "$moduleName.*"|Select-Object $folderSelect

        }

        
        try{
            write-verbose 'Testing for dotnet. Version will appear below if available'
            dotnet --version
        }catch{
            throw 'Dotnet SDK not installed or not path referenced. Please download and install Dotnet Core SDK'
        }
    }
    
    process{

        if(!$repoDetails)
        {
            throw 'Unable to config or find psResourceRepository'
        }

        write-warning 'We need to use dotnet sources for publishing ATM. Will try and register the source, but you can use `dotnet nuget source (list|add|remove)` and do this manually if you need'
        write-verbose 'Check for existing source'
        $dotnetsources =  dotnet nuget list source
        if($dotnetsources -like "*$($repoDetails.name)*")
        {
            write-verbose 'Dotnet source apparently already registered'
        }else{
            write-warning 'Attempt to add dotnet source'
            dotnet nuget add source $($repoDetails.Uri) --name $($repoDetails.name) --username $($credential.GetNetworkCredential().username) --password $($credential.GetNetworkCredential().Password)
        }






        $moduleVersions = get-moduleVersions
        if($moduleVersions)
        {

        }else{
            throw "Unable to find $moduleName in local repository file location"
        }

        
        if($moduleVersion)
        {
            $selectedModule = $moduleVersions.where{$_.version -eq $ModuleVersion}
        }else{
            write-verbose 'Version not specified. Processing newest'
            $selectedModule = $moduleVersions|Sort-object -Property version -Descending|Select-Object -First 1
        }

        if(!$selectedModule)
        {
            throw "Unable to process $moduleName in local repository file location. Version mismatch or sort error" 
        }

        
        
        write-verbose "Will try and publish with dotnet`ncommand:`ndotnet nuget push $($selectedModule.fullname) --api-key xxx-getyourowndamnedkey-xxx --source "

        dotnet nuget push $($selectedModule.fullname) --api-key $credential.GetNetworkCredential().Password --source $($repoDetails.name)

        
    }
    
}

