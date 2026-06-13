[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'

    #Load This File (the function lives alongside this test in source/private)
    $fileName = $PSCommandPath.Replace('.Tests.ps1','.ps1')
    $functionName = 'printTree'
    . $fileName

}

Describe 'Check Clean Environment' {
    It 'Should have loaded the function directly, not from an imported module' {
        (get-command $functionName).source | should -BeNullOrEmpty
    }
}

Describe 'printTree' {
    #printTree reads a $tree hashtable from its caller's scope (it is a nested helper of Get-MFDependencyTree).
    #We define $tree in the It scope so the scope chain resolves it.

    It 'Emits a DEPENDS-ON line for the requested node' {
        $tree = @{}
        $out = printTree -node 'Solo' -level 0
        #A single node produces a single string (scalar), so assert on $out directly
        $out | Should -HaveCount 1
        $out | Should -Match '>--DEPENDS-ON--> Solo'
    }

    It 'Recurses into child nodes found in the tree' {
        $tree = @{ 'A' = @('B','C'); 'B' = @('D') }
        $out = printTree -node 'A' -level 0
        ($out -join "`n") | Should -Match '>--DEPENDS-ON--> A'
        ($out -join "`n") | Should -Match '>--DEPENDS-ON--> B'
        ($out -join "`n") | Should -Match '>--DEPENDS-ON--> C'
        ($out -join "`n") | Should -Match '>--DEPENDS-ON--> D'
    }

    It 'Indents child nodes deeper than their parent' {
        $tree = @{ 'A' = @('B') }
        $out = printTree -node 'A' -level 0
        $parentLine = $out | Where-Object { $_ -match '>--DEPENDS-ON--> A' }
        $childLine  = $out | Where-Object { $_ -match '>--DEPENDS-ON--> B' }
        ($childLine.Length - $childLine.TrimStart().Length) | Should -BeGreaterThan ($parentLine.Length - $parentLine.TrimStart().Length)
    }
}
