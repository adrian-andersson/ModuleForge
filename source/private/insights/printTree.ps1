#Support function for get-mfDependencyTree

function printTree {
    param(
        [string]$node,
        [int]$level = 0
    )

    $indent = '    ' * $level
    write-output "$indent >--DEPENDS-ON--> $node"
    if ($tree.ContainsKey($node)) {
        foreach ($child in $tree[$node]) {
            printTree -node $child -level ($level + 1)
        }
    }
}