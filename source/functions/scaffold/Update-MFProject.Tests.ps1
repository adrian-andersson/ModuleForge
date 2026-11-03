[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Reference Current Path
    $currentPath = $(get-location).path
    #Walk up from this test to the project root, so it runs the same from any working directory
    $projectRoot = $PSScriptRoot
    while(!(test-path (join-path -path $projectRoot -childPath 'moduleForgeConfig.xml'))){ $projectRoot = split-path -path $projectRoot -parent; if(!$projectRoot){ throw 'Unable to find moduleForgeConfig.xml above this test' } }
    $sourcePath = join-path -path $projectRoot -childPath 'source'

    #Dependencies by filename anywhere under source/, loaded in this order. Throws if a name is missing or found more than once
    $dependencies = & (join-path -path $sourcePath -childPath 'resource' -AdditionalChildPath 'scripts','Get-MFTestDependency.ps1') -SourcePath $sourcePath -Name @(
        'ConvertTo-MFSafeUri.ps1'
        'New-MFProject.ps1'
        'Add-MFProjectScripts.ps1'
        'Add-MFFilesAndFolders.ps1'
    )
    $dependencies.ForEach{ . $_ }
    
    #Load This File
    . ($PSCommandPath -replace '\.tests\.ps1$','.ps1')
    
    #Create a temp folder so we don't clobber anything
    $testPath = join-path -path $TestDrive -childPath 'moduleTest'

}

Describe 'Update-MFProject' {
    BeforeAll{
        new-item -ItemType Directory -path $testPath
        Set-Location $testPath
    }
    It 'Should fail to update due to missing config file' {
        
        {$update = @{
                moduleName = 'UpdatedName'
            };
        Update-MFProject $update} | Should -throw
    }


    AfterAll{
        Set-Location $currentPath
        Remove-Item $testPath -Force -Recurse -ProgressAction SilentlyContinue
    }

}
Describe 'Update-MFProject' {
    BeforeAll{
        new-item -ItemType Directory -path $testPath
        set-location $testPath
        $moduleConfig = join-path $testPath -ChildPath moduleForgeConfig.xml
        $sourceFolder = join-path $testPath -ChildPath 'source'

    }
    It 'should create scaffold with mandatory parameters' {
        $params = @{
            ModuleName = 'TestModule'
            description = 'Test description'
        }
        new-mfProject @params
        Test-Path -Path $moduleConfig | Should -Be $true
        Test-Path -Path $sourceFolder | Should -Be $true
    }


    It 'Should update the config file' {
        $update = @{
            moduleName = 'UpdatedName'
            description = 'Test Description 2'
            companyName = 'TestCompany2'
            minimumPsVersion = '7.4'
            moduleAuthors = @('brian.may','jeremy.clarkson','richard.hammond')
            moduleTags = @('one','two')
            projectUri = 'https://example.com'
            iconUri = 'https://example.com/logo.png'
            licenseUri = 'https://example.com/license.md'
            DefaultCommandPrefix = 'tst'
            RequiredModules = @('Microsoft.PowerShell.PSResourceGet','Pester')
            ExternalModuleDependencies = 'PSReadLine'
            PrivateData = @{ TestKey = 'TestValue' }
        }
        Update-MFProject @update
        $config = Import-Clixml -Path $moduleConfig
        $config.moduleName | Should -Be $update.moduleName
        $config.description | Should -Be $update.description
        $config.companyName | Should -Be $update.companyName
        $config.minimumPsVersion | Should -Be $update.minimumPsVersion
        $config.moduleAuthors | Should -Be $update.moduleAuthors
        $config.tags | should -be $update.moduleTags
        $config.projectUri | Should -Be $update.projectUri
        $config.iconUri | Should -Be $update.iconUri
        $config.licenseUri | Should -Be $update.licenseUri
        $config.DefaultCommandPrefix | Should -Be $update.DefaultCommandPrefix
        $config.RequiredModules | Should -Contain 'Pester'
        $config.ExternalModuleDependencies | Should -Contain 'PSReadLine'
        $config.PrivateData.TestKey | Should -Be 'TestValue'
    }

    AfterAll{

        Set-Location $currentPath
        Remove-Item $testPath -Force -Recurse -ProgressAction SilentlyContinue
        start-sleep -Seconds 2 #Give it 2 seconds to remove the folder
    }

}
