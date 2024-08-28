BeforeAll{

    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    $dependencies = [ordered]@{
        functions = @('get-mfFolderItems.ps1','get-mfDependencyTree.ps1','get-mfFolderItemDetails.ps1','new-mfProject.ps1','register-mfLocalPsResourceRepository.ps1','remove-mfLocalPsResourceRepository.ps1','add-mfRepositoryXmlData.ps1')
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
    $testPath = join-path -path $currentPath -childPath 'buildTest'
    $sourcePath = join-path $testPath -ChildPath 'Source'
    $functionsPath = join-path $sourcePath -ChildPath functions
    $privatePath = join-path $sourcePath -ChildPath private
    $classPath = join-path $sourcePath -ChildPath classes
    $enumPath = join-path $sourcePath -ChildPath enums
    $classPath = join-path $sourcePath -ChildPath classes
    $resourcePath = join-path $sourcePath -ChildPath resource
    $validatorPath = join-path $sourcePath -childPath validationClasses
    $testFunctionPath = join-path $privatePath -ChildPath 'test.ps1'
    $privateFunctionPath = join-path $functionsPath -ChildPath 'private.ps1'
    $classDefinitionPath = join-path $classPath -ChildPath 'class.ps1'
    $enumDefinitionPath = join-path $enumPath -ChildPath 'enum.ps1'
    $resourceFilePath = join-path $resourcePath -ChildPath 'example.txt'
    $validatorFilePath = join-path $validatorPath -ChildPath 'validator.ps1'


    #Create a temp folder for the repo
    $repoTestPath = join-path -path $testPath -childPath 'repoTest'
    $repoName = 'PesterTesting'


}


Describe 'build-mfProject' {
    It 'should throw an error if module path does not exist' {
        $params = @{
            version = [semver]::new('1.0.0')
            modulePath = 'NonExistentPath'
        }
        { build-mfProject @params } | Should -Throw "Unable to read from NonExistentPath"
    }
}


describe 'build-mfProject' {
    beforeAll {
        $testFunction = @(
            'function get-text {'
            '    param ('
            '        [string]$returnString = "Hello"'
            '    )'
            '    process {'
            '        return $returnString'
            '    }'
            '}'
        )

        $privateFunction = @(
            'function get-textPrivate {'
            '    param ('
            '        [string]$returnString = "Hello"'
            '    )'
            '    process {'
            '        return $returnString'
            '    }'
            '}'
        )

        $classDefinition = @(
            'class MyClass {'
            '    [string]$Property = "Value"'
            '    MyClass() {}'
            '    [string] GetProperty() {'
            '        return $this.Property'
            '    }'
            '}'
        )

        $enumDefinition = @(
            'enum MyEnum {'
            '    Value1'
            '    Value2'
            '}'
        )

        $textFile = @(
            'Some Text'
            'In a file'
        )

        $validatorFile = @(
            'class CustomValidator : System.Management.Automation.ValidateArgumentsAttribute {'
            '    [void] Validate([object]$arguments,[System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {'
            '        $input = $arguments -as [string]'
            '        if ($input -notin @("my","list")) {'
            '            throw [System.Management.Automation.ValidationMetadataException] "Invalid input"'
            '        }'
            '    }'
            '}'
        )



        new-item -itemType Directory -Path $testPath
        Set-Location $testPath

        $mfProjSplat = @{
            ModuleName = 'TestModule'
            description = 'Test description'
            moduleAuthors = @('Author1', 'Author2')
            companyName = 'TestCompany'
            minimumPsVersion = '7.4'
            projectUri = 'https://example.com'
            iconUri = 'https://example.com/logo.png'
            licenseUri = 'https://example.com/license.md'
            DefaultCommandPrefix = 'te'
            #RequiredModules = @('Pester')
            ExternalModuleDependencies = @('Microsoft.PowerShell.PSResourceGet')
        }

        new-mfProject @mfProjSplat
        start-sleep -seconds 3
        $testFunction -join "`n"|Out-File $testFunctionPath -force
        $privateFunction -join "`n"|Out-file $privateFunctionPath -Force
        $classDefinition -join "`n" | Out-File $classDefinitionPath -Force
        $enumDefinition -join "`n" | out-file $enumDefinitionPath -Force
        $textFile -join "`n" | out-file $resourceFilePath -Force
        $validatorFile -join "`n" | out-file $validatorFilePath -Force

        build-mfProject -version '1.0.0-PREv001'
    }

    It 'Should have created a build folder' {
        (test-path 'build') |Should -be $true
    }

    It 'Should have created a psd1 file' {
        (get-childItem -path 'build' -recurse -filter '*.psd1').count |Should -be 1
    }

    It 'Should have created a psm1 file' {
        (get-childItem -path 'build' -recurse -filter '*.psm1').count |Should -be 1
    }

    It 'Should have created a txt file' {
        (get-childItem -path 'build' -recurse -filter '*.txt').count |Should -be 1
    }

    It 'Should have created a validators file' {
        (get-childItem -path 'build' -recurse -filter '*.Validators.ps1').count |Should -be 1
    }

    
    
}


describe 'register-psRepository'{
    BeforeAll {
        Set-Location $testPath
        new-item -ItemType Directory -Path $repoTestPath -Force
        register-mfLocalPsResourceRepository -repositoryName $repoName -path $repoTestPath
    }

    it 'Should have registered a local repository' {
        (get-psResourceRepository).Name |Should -Contain $repoName
    }
}


describe 'publish-psResource'{
    BeforeAll {
        Set-Location $testPath
        $psdReference = $(get-childItem -path 'build' -recurse -filter '*.psd1').fullname
        
    }

    it 'Should have a PSD1 reference' {
        $psdReference| Should -beLike '*TestModule.psd1'
    }

    it 'Should publish to the local repository' {
        publish-psResource -repository $repoName -Path $psdReference
        (get-childItem -path $repoTestPath -recurse -filter '*.nupkg').count |Should -be 1
    }
}



describe 'add-mfRepositoryXmlData'{
    BeforeAll {
        Set-Location $testPath
        $nuPkgRef = $(get-childItem -path $repoTestPath -recurse -filter '*.nupkg').fullname
    }

    it 'Should have a nuPkg reference' {
        $nuPkgRef | Should -not -BeNullOrEmpty
    }

    it 'Should update the XML' {
        {add-mfRepositoryXmlData -repositoryUri 'https://example.com' -branch 'main' -commit 'a1b2c3d' -NugetPackagePath $nuPkgRef -force} | Should -Not -Throw
    }
}

describe 'remove-mfLocalPsResourceRepository'  {

    it 'Should unregister the repository Correctly' {
        remove-mfLocalPsResourceRepository -repositoryName $repoName -path $repoTestPath
        (get-psResourceRepository).Name |Should -Not -Contain $repoName
    }

}


describe 'build-mfProject' {
    beforeAll {
        Set-Location $testPath
        build-mfProject -version '1.0.0-PREv002' -noExternalFiles
    }
    it 'Should rebuild the project as a single file ' {
        (get-childItem -path 'build' -recurse -filter '*.Validators.ps1').count |Should -Be 0
    }
}



afterAll {

    Set-Location $currentPath
    Remove-Item $testPath -Force -Recurse -ErrorAction Ignore
    #Remove-Item $repoTestPath -Recurse -Force -ErrorAction Ignore
    start-sleep -Seconds 2 #Give it 2 seconds to remove the folder
}