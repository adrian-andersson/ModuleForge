[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{
    $WarningPreference = 'SilentlyContinue'
    #Reference Current Path
    $currentPath = $(get-location).path


    #Create a temp folder so we don't clobber anything
    $testPath = join-path -path $currentPath -childPath 'ManifestTest'
    
    

    if(!(test-path $testPath)){
        new-item -ItemType Directory -Path $testPath
    }

    $configFile = join-path $testPath 'moduleForgeConfig.xml'
    $buildFolder = join-path $testPath 'build'
    if(!(test-path $buildFolder)){
        new-item -ItemType Directory -Path $buildFolder
    }

    $moduleFolder = join-path $buildFolder 'manifestTest'
    if(!(test-path $moduleFolder)){
        new-item -ItemType Directory -Path $moduleFolder
    }
    $manifestFile = join-path $moduleFolder 'manifestTest.psd1'
    #Create a configFile and Manifest so we can actually test the function with expected results
    @{
        moduleName = 'manifestTest'
    }|export-clixml $configFile

    $manifestSplat = @{
        Description = 'Test manifest'
        Path = $manifestFile
        Prerelease = 'prev005'
        ModuleVersion = '1.2.3'
    }
    New-ModuleManifest @manifestSplat

    set-location $testPath



    #Load This File
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
}

describe 'Get-MFLatestSemverFromBuildManifest with prerelease' {
    BeforeAll{
        $latestVer = Get-MFLatestSemverFromBuildManifest
    }

    It 'should have a semver object' {
        $latestVer.GetType().name |should -be 'SemanticVersion'
    }

    It 'Should have returned the correct version' {
        $latestVer.ToString() |should -be '1.2.3-prev005'
        $latestVer.prereleaselabel |should -be 'prev005'
    }
}

describe 'Get-MFLatestSemverFromBuildManifest without prerelease' {
    BeforeAll{
        $manifestSplat = @{
            Description = 'Test manifest'
            Path = $manifestFile
            ModuleVersion = '2.3.4'
        }
        New-ModuleManifest @manifestSplat 
        $latestVer = Get-MFLatestSemverFromBuildManifest
        

    }

    It 'should have a semver object' {
        $latestVer.GetType().name |should -be 'SemanticVersion'
    }

    It 'Should have returned the correct version' {
        $latestVer.ToString() |should -be '2.3.4'
        $latestVer.prereleaselabel |should -BeNullOrEmpty
    }
}

AfterAll{
    set-location $currentPath
    remove-item -Path $testPath -Force -recurse -ProgressAction SilentlyContinue
}