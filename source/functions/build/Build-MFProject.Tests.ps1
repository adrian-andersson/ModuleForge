[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'
    # Captured before $sourcePath is reassigned to the temp build folder below
    $mockPsScriptRoot = $sourcePath

    # Resolve dependencies by filename anywhere under source/, so tests stay independent of the folder layout. List order is load order.
    $sourceMap = @{}
    Get-ChildItem -Path $sourcePath -Recurse -Filter '*.ps1' -File | ForEach-Object { if(-not $sourceMap.ContainsKey($_.Name)){ $sourceMap[$_.Name] = $_.FullName } }
    $dependencies = @(
        'Get-MFFolderItems.ps1'
        'Get-MFDependencyTree.ps1'
        'Get-MFFolderItemDetails.ps1'
        'New-MFProject.ps1'
        'Register-MFLocalPsResourceRepository.ps1'
        'Remove-MFLocalPsResourceRepository.ps1'
        'Add-MFRepositoryXmlData.ps1'
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
    $fileName = $PSCommandPath.Replace('.Tests.ps1','.ps1')
    $functionName = 'Build-MFProject'
    . $fileName
    
    #Create a temp folder so we don't clobber anything
    $testPath = join-path -path $currentPath -childPath 'buildTest'
    $sourcePath = join-path $testPath -ChildPath 'source'
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

Describe 'Check Clean Environment' {
    BeforeAll {
        write-warning "PSCommandPath: $psCommandPath; scriptToLoad: $($PSCommandPath.Replace('.Tests.ps1','.ps1'))"
    }
    It 'Should have loaded the script directly, not from the module' {
        $PSCommandPath.Replace('.Tests.ps1','.ps1')|should -be $fileName
        (get-command $functionName).source |should -BeNullOrEmpty
    }
}

Describe 'Build-MFProject' {
    It 'should throw an error if module path does not exist' {
        $params = @{
            version = [semver]::new('1.0.0')
            ModulePath = 'NonExistentPath'
        }
        { Build-MFProject @params } | Should -Throw "Unable to read from NonExistentPath"
    }
}


describe 'Build-MFProject' {
    beforeAll {
        write-verbose 'build test module files'
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


        write-verbose "Create module directory at: $testPath"
        new-item -itemType Directory -Path $testPath
        write-verbose "Set location to: $testPath"
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
        write-verbose 'Creating ModuleForge Test Project'
        new-mfProject @mfProjSplat
        start-sleep -seconds 3
        write-verbose "Outputting Test files. Example: $testFunctionPat"
        $testFunction -join "`n"|Out-File $testFunctionPath -force
        $privateFunction -join "`n"|Out-file $privateFunctionPath -Force
        $classDefinition -join "`n" | Out-File $classDefinitionPath -Force
        $enumDefinition -join "`n" | out-file $enumDefinitionPath -Force
        $textFile -join "`n" | out-file $resourceFilePath -Force
        $validatorFile -join "`n" | out-file $validatorFilePath -Force
        write-verbose 'Building project'
        Build-MFProject -version '1.0.0-PREv001'
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


describe 'Register-PSRepository'{
    BeforeAll {
        Set-Location $testPath
        new-item -ItemType Directory -Path $repoTestPath -Force
        register-mfLocalPsResourceRepository -repositoryName $repoName -path $repoTestPath
    }

    it 'Should have registered a local repository' {
        (get-psResourceRepository).Name |Should -Contain $repoName
    }
}


describe 'Publish-PSResource'{
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



describe 'Add-MFRepositoryXmlData'{
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

describe 'Remove-MFLocalPsResourceRepository'  {

    it 'Should unregister the repository Correctly' {
        remove-mfLocalPsResourceRepository -repositoryName $repoName -path $repoTestPath
        (get-psResourceRepository).Name |Should -Not -Contain $repoName
    }

}


describe 'Build-MFProject' {
    beforeAll {
        Set-Location $testPath
        Build-MFProject -version '1.0.0-PREv002' -noExternalFiles
    }
    it 'Should rebuild the project as a single file ' {
        (get-childItem -path 'build' -recurse -filter '*.Validators.ps1').count |Should -Be 0
    }
}

describe 'Build-MFProject with ExportClasses and ExportEnums' {
    beforeAll {
        Set-Location $testPath
        Build-MFProject -version '1.0.0-PREv003' -ExportClasses -ExportEnums
    }
    it 'Should have created an external Classes file' {
        (get-childItem -path 'build' -recurse -filter '*.Classes.ps1').count | Should -Be 1
    }
    it 'Should have created an external Enums file' {
        (get-childItem -path 'build' -recurse -filter '*.Enums.ps1').count | Should -Be 1
    }
}

describe 'Build-MFProject with ReleaseNotes' {
    beforeAll {
        Set-Location $testPath
        Build-MFProject -version '1.0.0-PREv004' -ReleaseNotes 'Test release notes' -IncludeReleaseNotesInDescription
    }
    it 'Should have release notes in the manifest' {
        $manifest = Import-PowerShellDataFile (get-childItem -path 'build' -recurse -filter '*.psd1').fullname
        $manifest.PrivateData.PSData.ReleaseNotes | Should -Be 'Test release notes'
    }
    it 'Should have release notes appended to the description' {
        $manifest = Import-PowerShellDataFile (get-childItem -path 'build' -recurse -filter '*.psd1').fullname
        $manifest.Description | Should -BeLike '*Test release notes*'
    }
}

afterAll {

    Set-Location $currentPath
    Remove-Item $testPath -Force -Recurse -ErrorAction Ignore -ProgressAction SilentlyContinue
    #Remove-Item $repoTestPath -Recurse -Force -ErrorAction Ignore
    start-sleep -Seconds 2 #Give it 2 seconds to remove the folder
}