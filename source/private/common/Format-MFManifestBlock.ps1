function Format-MFManifestBlock
{

    <#
        .SYNOPSIS
            Write a nested, ordered hashtable as text for a module manifest.

        .DESCRIPTION
            New-ModuleManifest writes a nested hashtable in custom PrivateData as the text 'System.Collections.Hashtable',
            losing its values, and writes the keys of a hashtable in no particular order. Build-MFProject uses this to
            write its build provenance as a readable section instead: a manifest key holding a hashtable, with nested
            hashtables for groups, in the order given.

            Values are written as single-quoted strings, with any single quotes doubled, so the manifest stays data.
            Empty values are left out.

        .OUTPUTS
            [string] - The manifest text, one line per entry, indented by -Indent

        .NOTES
            Author: Adrian Andersson
    #>

    [CmdletBinding()]
    [OutputType([string])]
    PARAM(
        #The manifest key the block is written under
        [Parameter(Mandatory)]
        [ValidatePattern('^[A-Za-z][A-Za-z0-9]*$')]
        [string]$Name,
        #The values to write, in order. A value that is itself a dictionary becomes a nested block
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Data,
        #The indent of the key, to match the lines around it
        [Parameter()]
        [string]$Indent = ''
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }
    process{
        $inner = "$Indent    "
        $lines = [System.Collections.Generic.List[string]]::new()
        $lines.Add("$Indent$Name = @{")
        foreach($key in $Data.Keys)
        {
            if($key -notmatch '^[A-Za-z][A-Za-z0-9]*$')
            {
                throw "Manifest keys must be letters and numbers, starting with a letter: '$key'"
            }
            $value = $Data[$key]
            if($value -is [System.Collections.IDictionary])
            {
                if($value.Count -ge 1)
                {
                    (Format-MFManifestBlock -Name $key -Data $value -Indent $inner) -split "`n" | ForEach-Object { $lines.Add($_) }
                }
            }elseif(![string]::IsNullOrEmpty("$value")){
                $lines.Add("$inner$key = '$("$value".Replace("'","''"))'")
            }
        }
        $lines.Add("$Indent}")
        $lines -join "`n"
    }
}
