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