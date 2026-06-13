[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'

    #Load This File (the function lives alongside this test in source/private)
    $fileName = $PSCommandPath.Replace('.Tests.ps1','.ps1')
    $functionName = 'Get-MFProjectRoot'
    . $fileName

    #Temp working folder. Use GetTempPath for cross-platform safety (env:TEMP is null on Linux CI)
    $testRoot = join-path -path ([System.IO.Path]::GetTempPath()) -childPath "mfTest_ProjectRoot_$(New-Guid)"
    new-item -ItemType Directory -Path $testRoot | out-null

    #A project root holds a moduleForgeConfig.xml; a nested child does not
    new-item -ItemType File -Path (join-path -path $testRoot -childPath 'moduleForgeConfig.xml') | out-null
    $nestedChild = join-path -path $testRoot -childPath 'source' -AdditionalChildPath 'functions'
    new-item -ItemType Directory -Path $nestedChild | out-null

    #A separate folder with no config anywhere above it
    $orphan = join-path -path ([System.IO.Path]::GetTempPath()) -childPath "mfTest_Orphan_$(New-Guid)"
    new-item -ItemType Directory -Path $orphan | out-null

}

AfterAll{
    Remove-Item $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $orphan -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Check Clean Environment' {
    It 'Should have loaded the function directly, not from an imported module' {
        (get-command $functionName).source | should -BeNullOrEmpty
    }
}

Describe 'Get-MFProjectRoot' {
    It 'Returns the directory containing moduleForgeConfig.xml when given that directory' {
        Get-MFProjectRoot -ModulePath $testRoot | Should -Be ((Get-Item $testRoot).FullName)
    }

    It 'Walks up from a nested child directory to find the project root' {
        Get-MFProjectRoot -ModulePath $nestedChild | Should -Be ((Get-Item $testRoot).FullName)
    }

    It 'Throws when no config file exists in the path or any parent' {
        { Get-MFProjectRoot -ModulePath $orphan } | Should -Throw
    }

    It 'Throws when the supplied path does not exist' {
        { Get-MFProjectRoot -ModulePath (join-path $testRoot 'doesNotExist') } | Should -Throw
    }

    It 'Accepts pipeline input' {
        $nestedChild | Get-MFProjectRoot | Should -Be ((Get-Item $testRoot).FullName)
    }
}
