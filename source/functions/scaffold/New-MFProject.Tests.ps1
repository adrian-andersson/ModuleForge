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
        'Update-MFProject.ps1'
        'Add-MFProjectScripts.ps1'
        'Add-MFFilesAndFolders.ps1'
    )
    $dependencies.ForEach{ . $_ }
    
    #Load This File
    . ($PSCommandPath -replace '\.tests\.ps1$','.ps1')
    
    #Create a temp folder so we don't clobber anything
    $testPath = join-path -path $TestDrive -childPath 'moduleTest'

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

Describe 'New-MFProject trims a trailing path separator' {
    BeforeAll{
        new-item -ItemType Directory -path $testPath -force
        #Run from elsewhere and pass an explicit ModulePath so we exercise the trailing-separator trim branch
        Set-Location $currentPath
    }
    It 'Should handle a ModulePath that ends with a separator' {
        $trailingPath = "$testPath$([IO.Path]::DirectorySeparatorChar)"
        New-MFProject -ModuleName 'TrailingModule' -description 'Trailing separator test' -ModulePath $trailingPath
        #Config should land at the trimmed path, not a double-separator path
        Test-Path -Path (join-path $testPath -ChildPath 'moduleForgeConfig.xml') | Should -Be $true
    }
    It 'Should strip credentials from the project URI' {
        $tokenPath = join-path $testPath -ChildPath 'tokenProject'
        $null = new-item -ItemType Directory -Path $tokenPath -Force
        New-MFProject -ModuleName 'TokenModule' -description 'Token test' -ModulePath $tokenPath -ProjectUri 'https://org:pat123@dev.azure.com/org/project/_git/repo'
        (Import-Clixml -Path (join-path $tokenPath -ChildPath 'moduleForgeConfig.xml')).projectUri | Should -Be 'https://dev.azure.com/org/project/_git/repo'
    }
    It 'Should default testDependencies to Pester and PSScriptAnalyzer' {
        (Import-Clixml -Path (join-path $testPath -ChildPath 'moduleForgeConfig.xml')).testDependencies | Should -Be 'PesterAndScriptAnalyzer'
    }
    It 'Should default the minimum PowerShell version to the current LTS' {
        (Import-Clixml -Path (join-path $testPath -ChildPath 'moduleForgeConfig.xml')).minimumPsVersion | Should -Be ([version]'7.6.0')
    }
    AfterAll{
        Set-Location $currentPath
        Remove-Item $testPath -Force -Recurse -ProgressAction SilentlyContinue
        start-sleep -Seconds 2
    }
}
