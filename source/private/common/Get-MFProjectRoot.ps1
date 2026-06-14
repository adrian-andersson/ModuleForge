function Get-MFProjectRoot
{

    <#
        .SYNOPSIS
            Locate the root directory of a ModuleForge project.

        .DESCRIPTION
            Searches the supplied path and each parent directory in turn for a moduleForgeConfig.xml file.
            Returns the full path to the directory containing the config file.
            Throws if no config file is found before reaching the filesystem root.

        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding()]
    [OutputType([string])]
    PARAM(
        #Starting path for the upward search. Defaults to the current working directory
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [alias('Path')]
        [string]$ModulePath = $(get-location).path,
        #Name of the ModuleForge config file
        [Parameter(DontShow)]
        [string]$ConfigFile = 'moduleForgeConfig.xml'
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }
    process{
        try{
            $searchPath = (get-item $ModulePath -ErrorAction Stop).FullName
            $searchPath = (Resolve-Path $searchPath).ProviderPath
        }catch{
            throw "Path not accessible: $ModulePath"
        }

        while($searchPath){
            $match = Get-ChildItem -LiteralPath $searchPath -File | Where-Object { $_.Name -ieq $ConfigFile }
            if ($match) {
                Write-Verbose "Found project root at: $searchPath"
                return $searchPath
            }
            $parent = split-path $searchPath -Parent
            if($parent -eq $searchPath){
                break
            }
            $searchPath = $parent
        }

        throw "Unable to locate '$ConfigFile' in '$ModulePath' or any parent directory. Is this a ModuleForge project?"
    }
}