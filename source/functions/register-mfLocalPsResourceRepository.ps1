function register-mfLocalPsResourceRepository
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
        #Name of the repository
        [Parameter()]
        [string]$repositoryName = 'LocalTestRepository',
        #Root path of the module. Uses Temp Path by default
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