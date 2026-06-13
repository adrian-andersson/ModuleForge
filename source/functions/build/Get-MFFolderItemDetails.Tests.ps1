[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    $mockPsScriptRoot = $sourcePath

    # Resolve dependencies by filename anywhere under source/, so tests stay independent of the folder layout. List order is load order.
    $sourceMap = @{}
    Get-ChildItem -Path $sourcePath -Recurse -Filter '*.ps1' -File | ForEach-Object { if(-not $sourceMap.ContainsKey($_.Name)){ $sourceMap[$_.Name] = $_.FullName } }
    $dependencies = @(
        'Get-MFFolderItems.ps1'
    )
    $dependencies.ForEach{
        if($sourceMap.ContainsKey($_)){
            write-verbose "Dependency identified at: $($sourceMap[$_])"
            . $sourceMap[$_]
        }else{
            write-warning "Dependency not found under source: $_"
        }
    }

    #Load This File
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')

}

Describe 'Get-MFFolderItemDetails' {

    BeforeAll {
        $folderItemDetails = Get-MFFolderItemDetails -path $sourcePath
    }

    It 'Should have returned more than 10 of items' {
        $folderItemDetails.Count | Should -BeGreaterThan 10
    }
    It 'Should have function and private groups' {
        $folderItemDetails.group | Should -Contain 'functions'
        $folderItemDetails.group | Should -Contain 'private'
    }
    It 'Should have the correct function names' {
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Add-MFRepositoryXmlData'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Build-MFProject'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Get-MFDependencyTree'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Get-MFFolderItemDetails'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Get-MFFolderItems'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Get-MFNextSemver'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'New-MFProject'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Register-MFLocalPsResourceRepository'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Remove-MFLocalPsResourceRepository'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Update-MFProject'
        $folderItemDetails.FunctionDetails.functionName | Should -contain 'Add-MFFilesAndFolders'
    }
    It 'Should return appropriate dependencies' {
        $folderItemDetails.where{$_.name -eq 'Get-MFFolderItemDetails.ps1'}.Dependencies.Reference | Should -be 'Get-MFFolderItems'
    }

}

Describe 'Get-MFFolderItemDetails scriptblock - function analysis' {
    BeforeAll {
        $sbPath = Join-Path $sourcePath 'resource' 'scriptBlocks' 'Get-MFFolderItemDetails.scriptblock.ps1'
        [scriptblock]$sb = [scriptblock]::Create((Get-Content $sbPath -Raw))

        $testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "MFSbTest_$([System.IO.Path]::GetRandomFileName())"
        $testFunctionsDir = Join-Path $testRoot 'source' 'functions'
        New-Item -ItemType Directory -Path $testFunctionsDir -Force | Out-Null

        @'
function Do-Something {
    param([string]$InputValue)
    process { return $InputValue }
}
'@ | Set-Content (Join-Path $testFunctionsDir 'Do-Something.ps1')

        @'
function Do-Other {
    param([string]$InputValue)
    process { return Do-Something $InputValue }
}
'@ | Set-Content (Join-Path $testFunctionsDir 'Do-Other.ps1')

        $testFolderItems = Get-MFFolderItems -Path $testFunctionsDir -PSScriptsOnly
        $sbResult = & $sb $testFunctionsDir $testFolderItems
    }

    AfterAll {
        Remove-Item $testRoot -Recurse -Force -ErrorAction SilentlyContinue -ProgressAction SilentlyContinue
    }

    It 'Should return one result per file' {
        $sbResult.Count | Should -Be 2
    }
    It 'Should identify function names correctly' {
        $sbResult.FunctionDetails.functionName | Should -Contain 'Do-Something'
        $sbResult.FunctionDetails.functionName | Should -Contain 'Do-Other'
    }
    It 'Should detect the cross-file dependency' {
        $sbResult.Where{$_.Name -eq 'Do-Other.ps1'}.Dependencies.Reference | Should -Contain 'Do-Something'
    }
    It 'Should populate relativePath on each item' {
        $sbResult | ForEach-Object { $_.relativePath | Should -Not -BeNullOrEmpty }
    }
}

Describe 'Get-MFFolderItemDetails scriptblock - class analysis' {
    BeforeAll {
        $sbPath = Join-Path $sourcePath 'resource' 'scriptBlocks' 'Get-MFFolderItemDetails.scriptblock.ps1'
        [scriptblock]$sb = [scriptblock]::Create((Get-Content $sbPath -Raw))

        $testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "MFSbClassTest_$([System.IO.Path]::GetRandomFileName())"
        $testClassDir = Join-Path $testRoot 'source' 'classes'
        New-Item -ItemType Directory -Path $testClassDir -Force | Out-Null

        @'
class MyTestClass {
    [string]$Name
    [int]$Count
    MyTestClass([string]$n) { $this.Name = $n }
    [string] GetName() { return $this.Name }
}
'@ | Set-Content (Join-Path $testClassDir 'MyTestClass.ps1')

        $testFolderItems = Get-MFFolderItems -Path $testClassDir -PSScriptsOnly
        $sbResult = & $sb $testClassDir $testFolderItems
    }

    AfterAll {
        Remove-Item $testRoot -Recurse -Force -ErrorAction SilentlyContinue -ProgressAction SilentlyContinue
    }

    It 'Should return a result for the class file' {
        $sbResult | Should -Not -BeNullOrEmpty
    }
    It 'Should identify the class name' {
        $sbResult.ClassDetails.className | Should -Contain 'MyTestClass'
    }
    It 'Should identify class methods' {
        $sbResult.ClassDetails.Where{$_.className -eq 'MyTestClass'}.methods.Name | Should -Contain 'GetName'
    }
    It 'Should identify class properties' {
        $sbResult.ClassDetails.Where{$_.className -eq 'MyTestClass'}.properties.Name | Should -Contain 'Name'
        $sbResult.ClassDetails.Where{$_.className -eq 'MyTestClass'}.properties.Name | Should -Contain 'Count'
    }
}
