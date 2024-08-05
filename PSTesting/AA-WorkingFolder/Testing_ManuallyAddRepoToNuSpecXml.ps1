$LocalRepoPath = 'C:\nuget\publish'
$nuSpecName = 'aa-powershell-test.nuspec'
$packageName = 'aa-powershell-test.1.0.0'

$nuPkg = "$localRepoPath\$packageName.nupkg"

$ExtractPath = 'C:\nuget\extract'



if(! (test-path $ExtractPath))
{
    New-Item -Path $ExtractPath -ItemType Directory
}else{
    get-item -Path $ExtractPath |remove-item -recurse -force
    New-Item -Path $ExtractPath -ItemType Directory
}

expand-archive -Path $nuPkg -DestinationPath $ExtractPath

$repositoryString = 'https://github.com/domain-platform-engineering/aa-powershell-test'
$nuSpecPath = "$ExtractPath\$nuSpecName"
$nuSpecXml = new-object -TypeName XML
$nuSpecXml.Load($nuSpecPath)


#$nuSpecXml.package.metadata.SetAttributeNode('repository','value')

#$nuSpecXml.package.metadata.SetAttribute('repository',$repositoryString)
#Create new element, in same namespaceURI
$newElement = $nuSpecXml.CreateElement("repository",$nuSpecXml.package.namespaceURI)
$newElement.SetAttribute('url',$repositoryString)
$nuSpecXml.package.metadata.AppendChild($newElement)


$nuSpecXml.Save($nuSpecPath)
Remove-Variable nuSpecXml
start-sleep -seconds 2
#Now Zip it back up

Compress-Archive -Path "$ExtractPath\*" -DestinationPath "$nuPkg" -force


<#Then I can succesfully push with
dotnet nuget push C:\nuget\publish\aa-powershell-test.1.0.0.nupkg --api-key xxx --source domPlatformEngineering

#>



