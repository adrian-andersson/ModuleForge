#Support function for get-mfDependencyTree

function printTree {
    param(
        [string]$node,
        [int]$level = 0,
        #Files whose dependencies have already been printed. Shared across the whole tree so each file is expanded only once
        [System.Collections.Generic.HashSet[string]]$Visited = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase),
        #Files on the current branch, from the root down to this node. A child already in here is a circular reference
        [System.Collections.Generic.HashSet[string]]$Ancestors = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    )

    $indent = '    ' * $level
    $hasChildren = $tree.ContainsKey($node)

    if ($hasChildren -and $Ancestors.Contains($node)) {
        write-output "$indent >--DEPENDS-ON--> $node (circular reference)"
        return
    }

    if ($hasChildren -and $Visited.Contains($node)) {
        write-output "$indent >--DEPENDS-ON--> $node (dependencies shown above)"
        return
    }

    write-output "$indent >--DEPENDS-ON--> $node"
    if ($hasChildren) {
        $null = $Visited.Add($node)
        $null = $Ancestors.Add($node)
        foreach ($child in $tree[$node]) {
            printTree -node $child -level ($level + 1) -Visited $Visited -Ancestors $Ancestors
        }
        $null = $Ancestors.Remove($node)
    }
}
