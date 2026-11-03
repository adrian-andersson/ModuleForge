[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Reference paths for loading the dependency function
    $currentPath = $(get-location).path
    #Walk up from this test to the project root, so it runs the same from any working directory
    $projectRoot = $PSScriptRoot
    while(!(test-path (join-path -path $projectRoot -childPath 'moduleForgeConfig.xml'))){ $projectRoot = split-path -path $projectRoot -parent; if(!$projectRoot){ throw 'Unable to find moduleForgeConfig.xml above this test' } }
    $sourcePath = join-path -path $projectRoot -childPath 'source'

    #Dependencies by filename anywhere under source/, loaded in this order. Throws if a name is missing or found more than once
    $dependencies = & (join-path -path $sourcePath -childPath 'resource' -AdditionalChildPath 'scripts','Get-MFTestDependency.ps1') -SourcePath $sourcePath -Name @(
        'Add-MFProjectScripts.ps1'
    )
    $dependencies.ForEach{ . $_ }

    #Load This File (the function lives alongside this test in source/private)
    $fileName = ($PSCommandPath -replace '\.tests\.ps1$','.ps1')
    $functionName = 'Add-MFFilesAndFolders'
    . $fileName

    #Temp working folder. Use GetTempPath for cross-platform safety (env:TEMP is null on Linux CI)
    $testRoot = join-path -path ([System.IO.Path]::GetTempPath()) -childPath "mfTest_FilesAndFolders_$(New-Guid)"
    new-item -ItemType Directory -Path $testRoot | out-null

    $expectedSubDirs = @('functions','enums','classes','validationClasses','private','bin','resource')
    $expectedFiles = @('.gitignore','.mfignore')

}

AfterAll{
    Remove-Item $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Check Clean Environment' {
    It 'Should have loaded the function directly, not from an imported module' {
        (get-command $functionName).source | should -BeNullOrEmpty
    }
}

Describe 'Add-MFFilesAndFolders' {
    BeforeAll{
        Add-MFFilesAndFolders -moduleRoot $testRoot
        $sourceFolder = join-path -path $testRoot -childPath 'source'
    }

    It 'Creates the source folder' {
        Test-Path $sourceFolder | Should -BeTrue
    }

    It 'Creates every expected source subfolder' {
        foreach($dir in $expectedSubDirs){
            Test-Path (join-path -path $sourceFolder -childPath $dir) | Should -BeTrue
        }
    }

    It 'Creates the empty ignore files in each subfolder' {
        foreach($dir in $expectedSubDirs){
            foreach($file in $expectedFiles){
                Test-Path (join-path -path $sourceFolder -childPath $dir -AdditionalChildPath $file) | Should -BeTrue
            }
        }
    }

    It 'Does not create a filters subfolder (removed in v1.3.0)' {
        Test-Path (join-path -path $sourceFolder -childPath 'filters') | Should -BeFalse
    }
}

Describe 'Add-MFFilesAndFolders is idempotent' {
    It 'Does not throw when run again against an existing structure' {
        #Exercises the "directory is OK" / "file is OK" branches where everything already exists
        { Add-MFFilesAndFolders -moduleRoot $testRoot } | Should -Not -Throw
    }
}

Describe 'Add-MFFilesAndFolders accepts pipeline input' {
    It 'Creates the structure from a piped path' {
        $pipeRoot = join-path -path ([System.IO.Path]::GetTempPath()) -childPath "mfTest_FilesAndFoldersPipe_$(New-Guid)"
        new-item -ItemType Directory -Path $pipeRoot | out-null
        try{
            $pipeRoot | Add-MFFilesAndFolders
            Test-Path (join-path -path $pipeRoot -childPath 'source' -AdditionalChildPath 'functions') | Should -BeTrue
        }finally{
            Remove-Item $pipeRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
