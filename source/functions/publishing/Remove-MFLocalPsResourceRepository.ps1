function Remove-MFLocalPsResourceRepository
{

    <#
        .SYNOPSIS
            Remove the local test repository that was created with register-mfLocalPsResourceRepository
            
        .DESCRIPTION
             If a local test repository was created with the register-mfLocalPsResourceRepository, this command will remove it
             It will also remove the directory that hosted the local repository   

        .EXAMPLE
            Remove-MFLocalPsResourceRepository

            #### DESCRIPTION
            Unregister the default 'LocalTestRepository' PSResource repository and delete its backing
            directory from the temp path. Uses the same default name and location as Register-MFLocalPsResourceRepository.

        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding(SupportsShouldProcess)]
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

        write-verbose 'Clean up the repository'
        
        write-verbose "Checking we dont already have a repository with name: $RepositoryName"
        $repoRef = (Get-PSResourceRepository -Name $RepositoryName -erroraction Ignore)
        if($repoRef)
        {
            write-verbose 'Repository reference found, try and remove'
            if($PSCmdlet.ShouldProcess($RepositoryName, 'Unregister PSResource repository'))
            {
                Try{
                    unregister-PSResourceRepository -name $RepositoryName -ErrorAction Stop
                }catch{
                    throw 'Error unregistering the Resource Repository'
                }
            }
        }

        if((test-path $repositoryLocation))
        {
            write-verbose "File folder found at: $repositoryLocation"
            if($PSCmdlet.ShouldProcess($repositoryLocation, 'Remove local repository directory'))
            {
                try{
                    remove-item $repositoryLocation -force -ErrorAction Stop -Recurse
                    write-verbose 'Directory removed'
                }Catch{
                    Throw 'Error Removing directory'
                }
            }
        }
    }
    
}