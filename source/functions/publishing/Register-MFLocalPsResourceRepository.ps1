function Register-MFLocalPsResourceRepository
{

    <#
        .SYNOPSIS
            Add a local file-based PowerShell repository into the systems temp location
            
        .DESCRIPTION
            Allows you to test psresourceGet, as well as directly manipulate the nuget package,
            for example, to add git data to the nuspec

        .EXAMPLE
            Register-MFLocalPsResourceRepository      
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
        [string]$RepositoryName = 'LocalTestRepository',
        #Root path of the module. Uses Temp Path by default
        [Parameter()]
        [string]$Path = [System.IO.Path]::GetTempPath()

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

        $repositoryLocation = join-path $Path -ChildPath $RepositoryName

    }
    
    process{
        
        write-verbose "Checking we dont already have a repository with name: $RepositoryName"
        if(!(Get-PSResourceRepository -Name $RepositoryName -erroraction Ignore))
        {
            write-verbose 'Repository not found.'

            write-verbose "Checking for drive location at:`n`t$($repositoryLocation)"
            if(!(test-path $repositoryLocation))
            {
                try{
                    $null = New-Item -ItemType Directory -Path $repositoryLocation
                    write-verbose 'Directory Created'
                }Catch{
                    Throw 'Error creating directory'
                }
            }

            $registerSplat = @{
                Name = $RepositoryName
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
            if(!(Get-PSResourceRepository -Name $RepositoryName -erroraction Ignore))
            {
                throw 'Something has gone wrong. Unable to find repository'
            }else{
                write-verbose 'Repository looks healthy'
            }


        }else{
            write-verbose "$RepositoryName Found"
        }
    }
    
}