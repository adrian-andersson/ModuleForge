[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    $dependencies = [ordered]@{
        functions = @('Get-MFGitChangeLog.ps1')
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
    

    #Create a temp folder so we don't clobber anything
    $testPath = join-path -path $currentPath -childPath 'platyPsTestModule'
    $docsPath = join-path -path $testPath -childPath 'docs'
    $manifestPath = join-path $testPath -ChildPath 'platyPsTest.psd1'
    $moduleFile = join-path $testPath -ChildPath 'platyPsTest.psm1'
    if(!(test-path $testPath)){
        new-item -ItemType Directory -Path $testPath
    }
    if(!(test-path $docsPath)){
        new-item -ItemType Directory -Path $docsPath
    }
    
    #Create a manifest file
@'
@{
    ModuleVersion     = '1.0.0'
    GUID              = '00000000-0000-0000-0000-000000000000'
    Author           = 'Example'
    PowerShellVersion = '5.1'
    FunctionsToExport = 'get-helloWorld'
    RootModule = 'platyPsTest.psm1'
}
'@|out-file $manifestPath
    #Create a module file
    
@'
function get-helloWorld
{
<#
        .SYNOPSIS
            Returns a greeting message with the provided name.

        .DESCRIPTION
            This function takes a name as an input parameter and returns a "Hello" greeting message.
            It supports pipeline input and debugging messages for better tracking.

        .EXAMPLE
            Get-HelloWorld

            #### DESCRIPTION
            Executes the function to return a greeting.

            #### OUTPUT
            Hello world!

        .EXAMPLE
            Get-HelloWorld -Name "TestUser"

            #### DESCRIPTION
            Executes the function to return a greeting for "TestUser".

            #### OUTPUT
            Hello TestUser!

    #>
    [CmdletBinding()]
    PARAM(
        # Specifies the name to greet.
        [Parameter(ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string]$Name = 'World'
    )
    process{
        "Hello $name!"
    }
}
'@|Out-File $moduleFile

    #Load This File
    $fileName = $PSCommandPath.Replace('.Tests.ps1','.ps1')
    $functionName = 'Write-MFModuleDocs'
    . $fileName
    
    #Need to ensure PlatyPS is available 
    if(! (get-module 'platyPs' -ListAvailable))
    { 
        install-module -Repository 'PSGallery' -Name platyPS -Force -SkipPublisherCheck
    }

    

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


Describe 'write-mfModuleDocs' {
    BeforeAll {
        # Mock the git version command
        function invoke-GitCommand{
            [CmdletBinding()]
            PARAM(
                [Parameter(Position = 0)]
                [Alias("p0")]
                [string]$Param0,
                [Parameter(Position = 1)]
                [Alias("p1")]
                [string]$Param1,
                [Parameter(Position = 2)]
                [Alias("p2")]
                [string]$Param2,
                [Parameter(Position = 3)]
                [Alias("p3")]
                [string]$Param3,
                [Parameter(Position = 4)]
                [Alias("p4")]
                [string]$Param4,
                [Parameter(Position = 5)]
                [Alias("p5")]
                [string]$Param5,
                [Parameter(Position = 6)]
                [Alias("p6")]
                [string]$Param6
            )

            begin{
                $commandLine = "$Param0 $Param1 $Param2 $Param3 $Param4 $Param5 $Param6"
                $commandLine = $commandLine.trim()


                $tags = @(
                    'v1.0.1',
                    'v1.0.1-prev002',
                    'v1.0.1-prev001'
                )

                $prettyLog1 = @(
                    'feat: errors are now a feature'
                    'test: threw spaget at wall to see what stuck'
                    'fix: Added bandaid to small memory leak'
                    'fix: Fixed bug that was stuck on fly paper by removing fly paper'
                )
                $prettyLog2 = @(
                    'test: Added true test of patience'
                    'feat: Added another hello world example'
                    'feat: Added new feature'
                )
                $prettyLog3 = @(
                    'chore: mopped the floor'
                    'chore: washed the dishes'
                    'fix: Removed the throw command and changed to Write-verbose so error is now a feature'
                    'perf: Removed artificial sleep timer to drastically improve performance'
                    'perf: increased caffiene dossage by ordering strong flatwhite instead of regular flatwhite'
                    'docs: Updated documentation by switching from single spacing to 1.5 spacing and changing font to comic-sans'
                    'refactor: changed ritual sacrifice from jane to jenny '
                )
            }
            
            process{
                Write-Verbose "Command provided: $commandLine"
                switch -Wildcard ($commandLine) {
                    '--version' { return 'git version 2.30.0.mock' }
                    'rev-parse --is-inside-work-tree' { return 'true' }
                    'tag --sort=-creatordate' { return $tags }
                    'log v1.0.1-prev002..v1.0.1 --pretty=format:%s' { return $prettyLog1 }
                    'log v1.0.1-prev001..v1.0.1-prev002 --pretty=format:%s' { return $prettyLog2 }
                    'log v1.0.1-prev001 --pretty=format:%s' { return $prettyLog3 }
                    default { throw "Unexpected git command: $commandLine" }
                }
            }
        }

        Set-Alias -name 'git' -Value invoke-GitCommand
        import-module $manifestPath
        import-module platyPS
        write-mfModuleDocs -modulename platyPsTest -path $docsPath -includeChangeLog
        $newDocsPath = join-path $docsPath 'docs'
        $newFuncsPath = join-path $newDocsPath 'functions'

    }

    it 'Should have imported platyPsTestModule' {
        (get-module platyPsTest).Name |Should -Not -BeNullOrEmpty
    }

    it 'Should have the get-helloworld function' {
        (get-command -name get-helloworld -Module platyPsTest).Name |Should -Not -BeNullOrEmpty
    }

    it 'Should have the platyPs module available'{
        (get-module platyPs).Name |Should -Not -BeNullOrEmpty
    }

    it 'Should have a changelog file in the docs'{
        (get-childitem -path $newDocsPath).name |Should -contain 'changeLog.md'
    }

    it 'Should have appropriate contents in the changelog'{
        $content = get-content (get-childitem -path (join-path $newDocsPath -ChildPath 'changeLog.md')).fullname
        $content |Should -contain '# Change Log'
        $content |Should -contain '## Version: v1.0.1'
        $content |Should -contain '- Added bandaid to small memory leak'
    }

    it 'Should have a changelog file in the docs'{
        (get-childitem -path $newFuncsPath).name |Should -contain 'get-helloWorld.md'
    }

    
    it 'Should have appropriate contents in the changelog'{
        $content = get-content (get-childitem -path (join-path $newFuncsPath "get-helloWorld.md")).fullname
        $content |Should -contain '## SYNOPSIS'
        $content |Should -contain '## SYNTAX'
        $content |Should -contain '### EXAMPLE 1'
        $content |Should -contain '### EXAMPLE 1'
        $content |Should -contain '### EXAMPLE 1'
        $content |Should -contain '## PARAMETERS'
    }

    it 'Should have an index file in the docs'{
        (get-childitem -path $newDocsPath).name |Should -contain 'index.md'
    }

    
    it 'Should have appropriate contents in the index file'{
        $content = get-content (get-childitem -path (join-path $newDocsPath 'index.md')).fullname
        $content |Should -contain '# Documentation Index'
        $content |Should -contain '- [changeLog](./changeLog.md)'
        $content |Should -contain '## functions'
        $content |Should -contain '- [get-helloWorld](./functions/get-helloWorld.md)'
    }

    Describe 'write-mfModuleDocs with SkipIndex' {
        BeforeAll {
            # Remove index.md so we can verify -SkipIndex does not recreate it
            # Running again also exercises the functions folder recreation path
            Remove-Item (join-path $newDocsPath 'index.md') -ErrorAction Ignore
            write-mfModuleDocs -modulename platyPsTest -path $docsPath -SkipIndex
        }
        It 'Should not create index.md when SkipIndex is set' {
            Test-Path (join-path $newDocsPath 'index.md') | Should -Be $false
        }
        It 'Should still regenerate function documentation' {
            (Get-ChildItem -Path $newFuncsPath -Filter '*.md').Count | Should -BeGreaterThan 0
        }
    }

    AfterAll{
        remove-alias git
        remove-module platyPsTest,platyPs -ErrorAction Ignore
        remove-item -Path $testPath -Force -recurse
    }
}

