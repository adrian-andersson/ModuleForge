[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    # Resolve dependencies by filename anywhere under source/, so tests stay independent of the folder layout. List order is load order.
    $sourceMap = @{}
    Get-ChildItem -Path $sourcePath -Recurse -Filter '*.ps1' -File | ForEach-Object { if(-not $sourceMap.ContainsKey($_.Name)){ $sourceMap[$_.Name] = $_.FullName } }
    $dependencies = @(
        'Update-MFProject.ps1'
        'Add-MFProjectScripts.ps1'
        'Add-MFFilesAndFolders.ps1'
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
    
    #Create a temp folder so we don't clobber anything
    $testPath = join-path -path $currentPath -childPath 'moduleTest'

}

Describe 'New-MFProject' {
    BeforeAll{
        new-item -ItemType Directory -path $testPath -force
        set-location $testPath
    }
    It 'should create scaffold with mandatory parameters' {
        $params = @{
            ModuleName = 'TestModule'
            description = 'Test description'
        }
        New-MFProject @params
        $moduleConfig = join-path $testPath -ChildPath moduleForgeConfig.xml
        Test-Path -Path $moduleConfig | Should -Be $true
        $sourceFolder = join-path $testPath -ChildPath 'source'
        Test-Path -Path $sourceFolder | Should -Be $true
    }


    AfterAll{

        Set-Location $currentPath
        Remove-Item $testPath -Force -Recurse -ProgressAction SilentlyContinue
        start-sleep -Seconds 2 #Give it 2 seconds to remove the folder
    }

}

Describe 'New-MFProject should throw if config already exists' {
    BeforeAll{
        new-item -ItemType Directory -path $testPath -force
        set-location $testPath
        New-MFProject -ModuleName 'TestModule' -description 'Test description'
    }
    It 'Should throw when a config file already exists in the target path' {
        { New-MFProject -ModuleName 'TestModule' -description 'Test description' } | Should -Throw
    }
    AfterAll{
        Set-Location $currentPath
        Remove-Item $testPath -Force -Recurse -ProgressAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
}

Describe 'New-MFProject' {
    BeforeAll{
        new-item -ItemType Directory -path $testPath
        set-location $testPath
        $moduleConfig = join-path $testPath -ChildPath moduleForgeConfig.xml

    }
    It 'should create a config file with correct parameters' {
        $params = @{
            ModuleName = 'TestModule'
            description = 'Test description'
            moduleAuthors = @('Author1', 'Author2')
            companyName = 'TestCompany'
            moduleTags = @('tag1', 'tag2')
            minimumPsVersion = '7.4'
            projectUri = 'https://example.com'
            iconUri = 'https://example.com/logo.png'
            licenseUri = 'https://example.com/license.md'
            DefaultCommandPrefix = 'tst'

        }
        New-MFProject @params
        $config = Import-Clixml -Path $moduleConfig
        $config.moduleName | Should -Be $params.ModuleName
        $config.description | Should -Be $params.description
        $config.moduleAuthors | Should -Be $params.moduleAuthors
        $config.companyName | Should -Be $params.companyName
        $config.tags | Should -Be $params.moduleTags
        $config.minimumPsVersion |should -be $params.minimumPsVersion
        $config.projectUri |should -be $params.projectUri
        $config.iconUri | should -be $params.iconUri
        $config.licenseUri | should -be $params.licenseUri
        $config.DefaultCommandPrefix |should -be $params.DefaultCommandPrefix
    }

    AfterAll{

        Set-Location $currentPath
        Remove-Item $testPath -Force -Recurse -ProgressAction SilentlyContinue
        start-sleep -Seconds 2 #Give it 2 seconds to remove the folder
    }

}
