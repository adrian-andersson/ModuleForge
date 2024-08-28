BeforeAll{

    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    $dependencies = [ordered]@{
        functions = @('new-mfProject.ps1')
        private = @('add-mfFilesAndFolders.ps1')
    }

    $dependencies.GetEnumerator().ForEach{
        $DirectoryRef = join-path -path $sourcePath -childPath $_.Key
        $_.Value.ForEach{
            $ItemPath = join-path -path $DirectoryRef -childpath $_
            $ItemRef = get-item $ItemPath -ErrorAction SilentlyContinue
            if($ItemRef){
                write-verbose "Dependency identified at: $($ItemRef.fullname)"
                . $ItemRef.Fullname
            }else{
                write-warning "Dependency not found at: $ItemPath"
            }
        }
    }
    
    #Load This File
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
    
    #Create a temp folder so we don't clobber anything
    $testPath = join-path -path $currentPath -childPath 'moduleTest'

}

Describe 'update-mfProject' {
    BeforeAll{
        new-item -ItemType Directory -path $testPath
        Set-Location $testPath
    }
    It 'Should fail to update due to missing config file' {
        
        {$update = @{
                moduleName = 'UpdatedName'
            };
        update-mfProject $update} | Should -throw
    }


    AfterAll{
        Set-Location $currentPath
        Remove-Item $testPath -Force -Recurse
    }

}
Describe 'update-mfProject' {
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
        }
        update-mfProject @update
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
    }

    AfterAll{

        Set-Location $currentPath
        Remove-Item $testPath -Force -Recurse
        start-sleep -Seconds 2 #Give it 2 seconds to remove the folder
    }

}
