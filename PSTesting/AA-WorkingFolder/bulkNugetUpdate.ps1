#How this works
#Have a local file-based repository full of nugets to upload
$localRepoPath = 'C:\tempRepository'
#Have a github repository ready to go
$githubRepository = 'https://github.com/domain-platform-engineering/legacy-powershell-modules'

#Get all the nuspecks

$nupkgs = get-childitem $localRepoPath -filter *.nupkg

#ExtractionPath
$ExtractPath = 'C:\nuget\extract'


foreach($nuPkg in $nupkgs[1..$($nuPkgs.count)])
{
        
    #Scrub our temp directory
    if(! (test-path $ExtractPath))
    {
        New-Item -Path $ExtractPath -ItemType Directory
    }else{
        get-item -Path $ExtractPath |remove-item -recurse -force
        New-Item -Path $ExtractPath -ItemType Directory
    }



    #Expand the archive
    expand-archive -Path $nuPkg -DestinationPath $ExtractPath

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
        $newElement.SetAttribute('url',$githubRepository)
        $nuSpecXml.package.metadata.AppendChild($newElement)

        
        $nuSpecXml.Save($nuSpecPath)
        Remove-Variable nuSpecXml
        start-sleep -seconds 2
        #Now Zip it back up


        Compress-Archive -Path "$ExtractPath\*" -DestinationPath "$($nuPkg.fullname)" -force

    }else{
        throw 'no or multi nuspec'
    }

    <#
    #Add nuget xml things
    $nuSpecPath = "$ExtractPath\$nuSpecName"
    $nuSpecXml = new-object -TypeName XML
    $nuSpecXml.Load($nuSpecPath)
    #>



}

<#
Upload the bulk
$apiKey = 'xxx-getyourowndamnedkey-xxx'
$NuPkgs = get-childitem -Filter *.nupkg
$nuPkgs.foreach{
    dotnet nuget push $_.fullname --api-key $apiKey --source domPlatformEngineering
}

#>