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