BeforeAll{

    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    $dependencies = [ordered]@{
        functions = @('update-mfProject.ps1')
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

Describe 'new-mfProject' {
    BeforeAll{
        new-item -ItemType Directory -path $testPath -force
        set-location $testPath
    }
    It 'should create scaffold with mandatory parameters' {
        $params = @{
            ModuleName = 'TestModule'
            description = 'Test description'
        }
        new-mfProject @params
        $moduleConfig = join-path $testPath -ChildPath moduleForgeConfig.xml
        Test-Path -Path $moduleConfig | Should -Be $true
        $sourceFolder = join-path $testPath -ChildPath 'source'
        Test-Path -Path $sourceFolder | Should -Be $true
    }


    AfterAll{

        Set-Location $currentPath
        Remove-Item $testPath -Force -Recurse
        start-sleep -Seconds 2 #Give it 2 seconds to remove the folder
    }

}

Describe 'new-mfProject' {
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
        new-mfProject @params
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
        Remove-Item $testPath -Force -Recurse
        start-sleep -Seconds 2 #Give it 2 seconds to remove the folder
    }

}
