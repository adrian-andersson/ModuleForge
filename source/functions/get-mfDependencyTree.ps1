function get-mfDependencyTree
{

    <#
        .SYNOPSIS
            Generate a dependency tree of ModuleForge PowerShell scripts, either in terminal or a mermaid flowchart
            
        .DESCRIPTION
            The `get-mfDependencyTree` function processes an array of objects representing PowerShell scripts and their dependencies.
            It generates a visual representation of the dependency tree, either as a text-based tree in the terminal or as a Mermaid diagram.
            This function helps in understanding the relationships and dependencies between different scripts and modules in a project.
            
        ------------
        .EXAMPLE
            $folderItemDetails = get-mfFolderItemDetails -path (get-item .\source).fullname
            get-mfDependencyTree ($folderItemDetails|Select-Object relativePath,dependencies)
            
            #### DESCRIPTION
            Show files and any dependencies

        .INPUTS
            [OBJECT[]] - ReferenceData Object Array (Resulting from get-mfFolderItemDetails) accepted as pipeline input

        .OUTPUTS
            [STRING] - Returns a formatted string representing the dependency tree, Output format can be:
                        - Multi-line string expected to print to terminal (Default Behaviour)
                        - A mermaid chart (If specified with Output Type 'Mermaid') 
                        - A mermaid chart encapsulated in a markdown code block ('MermaidMarkdown')
            
        .NOTES
            Author: Adrian Andersson
                        
    #>

    [CmdletBinding()]
    PARAM(
        #What Reference Data are we looking at. See function example for how to retrieve
        [Parameter(ValueFromPipeline)]
        [object[]]$referenceData = (get-mfFolderItemDetails -path (get-item source).fullname),
        [Parameter()]
        [ValidateSet('Mermaid','MermaidMarkdown','Terminal')]
        [string]$outputType = 'Terminal'
    )
    begin {
        # Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        # Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        
        $dependencies = New-Object System.Collections.Generic.List[object]
    }
    
    process {
        foreach ($ref in $referenceData) {
            $relativePath = $ref.relativePath
            foreach ($dep in $ref.dependencies) {
                $dependencies.add(
                    [PSCustomObject]@{
                        Parent = $relativePath
                        Child  = $dep.ReferenceFile
                    }
                )
            }
        }

        $output = New-Object System.Collections.Generic.List[string]
        if ($outputType -eq 'Mermaid' -or $outputType -eq 'MermaidMarkdown') {
            if ($outputType -eq 'MermaidMarkdown') {
                $output.add('```mermaid')
            }
            $output.add('flowchart TD')
            foreach ($dep in $dependencies) {
                $output.add("'$($dep.Parent)' --> '$($dep.Child)'")
            }
            if ($outputType -eq 'MermaidMarkdown') {
                $output.add('```')
            }
            
            $output -join "`n"
        } else {
            $tree = @{}
            foreach ($dep in $dependencies) {
                write-verbose "In: $dep dependencyCheck"
                if (-not $tree.ContainsKey($dep.Parent)) {
                    write-verbose "Need to add: $($dep.Parent) As ParentRef"
                    $tree[$dep.Parent] = New-Object System.Collections.Generic.List[string]
                }

                write-verbose "Need to add $($dep.Child) as child of $($dep.Parent)"
                $tree[$dep.Parent].add($dep.Child)
            }

            $rootNodes = $referenceData.where{$_.Dependencies.Count -gt 0}.relativePath
            $rootNodes.foreach{
                write-output $_
                if ($tree.ContainsKey($_)) {
                    foreach ($child in $tree[$_]) {
                        printTree -node $child -level 1
                    }
                }
            }
        }
    }
}