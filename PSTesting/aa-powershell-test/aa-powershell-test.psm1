function get-testHelloWorld
{

    <#
        .SYNOPSIS
            Just Say Hello World
            
        .DESCRIPTION
            Just Say Hello World

            
        .NOTES
            Author: Adrian Andersson
            
            
            Changelog:
            
                2022-01-10 - AA
                    - Test function
                    
    #>

    [CmdletBinding()]
    PARAM(
        #PARAM DESCRIPTION

    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        
    }
    
    process{
        Write-Output "Hello World!!!"
        
    }
    
}