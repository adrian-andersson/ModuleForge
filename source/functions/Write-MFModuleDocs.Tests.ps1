[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath  = join-path -path $currentPath -childPath 'source'

    $dependencies = [ordered]@{
        functions = @('Get-MFGitChangeLog.ps1')
        private   = @(
            'ConvertTo-MFNavTitle.ps1'
            'Get-MFH1FromFile.ps1'
            'Test-MFHasJtdFrontMatter.ps1'
            'Add-MFJtdFrontMatter.ps1'
            'Get-MFChildLinkList.ps1'
            'Write-MFSectionIndex.ps1'
        )
    }

    $dependencies.GetEnumerator().ForEach{
        $DirectoryRef = join-path -path $sourcePath -childPath $_.Key
        $_.Value.ForEach{
            $ItemPath = join-path -path $DirectoryRef -childpath $_
            $ItemRef  = get-item $ItemPath -ErrorAction SilentlyContinue
            if($ItemRef){
                write-verbose "Dependency identified at: $($ItemRef.fullname)"
                . $ItemRef.Fullname
            }else{
                write-warning "Dependency not found at: $ItemPath"
            }
        }
    }

    #Create a temp folder so we don't clobber anything
    $testPath    = join-path -path $currentPath -childPath 'platyPsTestModule'
    $docsPath    = join-path -path $testPath    -childPath 'docs'
    $manifestPath = join-path $testPath -ChildPath 'platyPsTest.psd1'
    $moduleFile   = join-path $testPath -ChildPath 'platyPsTest.psm1'
    if(!(test-path $testPath)){ new-item -ItemType Directory -Path $testPath }
    if(!(test-path $docsPath)){ new-item -ItemType Directory -Path $docsPath }

    #Create a manifest file
@'
@{
    ModuleVersion     = '1.0.0'
    GUID              = '00000000-0000-0000-0000-000000000000'
    Author            = 'Example'
    Description       = 'A test module for PlatyPS doc generation.'
    PowerShellVersion = '5.1'
    FunctionsToExport = 'get-helloWorld'
    RootModule        = 'platyPsTest.psm1'
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
    $fileName     = $PSCommandPath.Replace('.Tests.ps1','.ps1')
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
                [Parameter(Position = 0)][Alias("p0")][string]$Param0,
                [Parameter(Position = 1)][Alias("p1")][string]$Param1,
                [Parameter(Position = 2)][Alias("p2")][string]$Param2,
                [Parameter(Position = 3)][Alias("p3")][string]$Param3,
                [Parameter(Position = 4)][Alias("p4")][string]$Param4,
                [Parameter(Position = 5)][Alias("p5")][string]$Param5,
                [Parameter(Position = 6)][Alias("p6")][string]$Param6
            )
            begin{
                $commandLine = "$Param0 $Param1 $Param2 $Param3 $Param4 $Param5 $Param6".trim()
                $tags = @('v1.0.1','v1.0.1-prev002','v1.0.1-prev001')
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
                    '--version'                                          { return 'git version 2.30.0.mock' }
                    'rev-parse --is-inside-work-tree'                    { return 'true' }
                    'tag --sort=-creatordate'                             { return $tags }
                    'log v1.0.1-prev002..v1.0.1 --pretty=format:%s'     { return $prettyLog1 }
                    'log v1.0.1-prev001..v1.0.1-prev002 --pretty=format:%s' { return $prettyLog2 }
                    'log v1.0.1-prev001 --pretty=format:%s'              { return $prettyLog3 }
                    default { throw "Unexpected git command: $commandLine" }
                }
            }
        }

        Set-Alias -name 'git' -Value invoke-GitCommand
        import-module $manifestPath
        import-module platyPS
        write-mfModuleDocs -modulename platyPsTest -path $docsPath -includeChangeLog
        $newDocsPath  = join-path $docsPath 'docs'
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

    # --- Changelog ---

    it 'Should have a changelog file in the docs'{
        (get-childitem -path $newDocsPath).name |Should -contain 'changeLog.md'
    }

    it 'Should have JTD front matter in the changelog' {
        $content = get-content (join-path $newDocsPath 'changeLog.md')
        $content |Should -contain 'layout: default'
        $content |Should -contain 'title: Change Log'
        $content |Should -contain 'nav_order: 2'
    }

    it 'Should have appropriate contents in the changelog'{
        $content = get-content (get-childitem -path (join-path $newDocsPath -ChildPath 'changeLog.md')).fullname
        $content |Should -contain '# Change Log'
        $content |Should -contain '## Version: v1.0.1'
        $content |Should -contain '- Added bandaid to small memory leak'
    }

    # --- Function doc file ---

    it 'Should have the function doc file in the functions folder'{
        (get-childitem -path $newFuncsPath).name |Should -contain 'get-helloWorld.md'
    }

    it 'Should have appropriate PlatyPS content in the function doc'{
        $content = get-content (get-childitem -path (join-path $newFuncsPath 'get-helloWorld.md')).fullname
        $content |Should -contain '## SYNOPSIS'
        $content |Should -contain '## SYNTAX'
        $content |Should -contain '### EXAMPLE 1'
        $content |Should -contain '## PARAMETERS'
    }

    it 'Should have JTD front matter in the function doc' {
        $content = get-content (join-path $newFuncsPath 'get-helloWorld.md')
        $content |Should -contain 'layout: default'
        $content |Should -contain 'parent: Functions'
    }

    it 'Should not include ProgressAction in the function doc' {
        $content = get-content (join-path $newFuncsPath 'get-helloWorld.md')
        $content |Should -Not -Contain '### -ProgressAction'
    }

    # --- Functions index page ---

    it 'Should have a functions index file' {
        Test-Path (join-path $newFuncsPath 'index.md') |Should -Be $true
    }

    it 'Should have correct front matter in the functions index' {
        $content = get-content (join-path $newFuncsPath 'index.md')
        $content |Should -contain 'layout: default'
        $content |Should -contain 'title: Functions'
        $content |Should -contain 'has_children: true'
    }

    it 'Should link to the function page from the functions index' {
        $content = get-content (join-path $newFuncsPath 'index.md')
        ($content |Where-Object {$_ -match 'get-helloWorld\.md'}) |Should -Not -BeNullOrEmpty
    }

    # --- Homepage index ---

    it 'Should have an index file in the docs'{
        (get-childitem -path $newDocsPath).name |Should -contain 'index.md'
    }

    it 'Should have JTD front matter in the homepage index' {
        $content = get-content (join-path $newDocsPath 'index.md')
        $content |Should -contain 'layout: default'
        $content |Should -contain 'title: Home'
        $content |Should -contain 'nav_order: 1'
    }

    it 'Should use the module name as the H1 in the homepage index' {
        $content = get-content (join-path $newDocsPath 'index.md')
        $content |Should -contain '# platyPsTest'
    }

    it 'Should stamp the module version in the homepage index' {
        $content = get-content (join-path $newDocsPath 'index.md')
        $content |Should -contain '> Module version: 1.0.0'
    }

    it 'Should include the module description in the homepage index' {
        $content = get-content (join-path $newDocsPath 'index.md')
        ($content |Where-Object {$_ -match 'A test module for PlatyPS'}) |Should -Not -BeNullOrEmpty
    }

    it 'Should link to the changelog from the homepage index' {
        $content = get-content (join-path $newDocsPath 'index.md')
        ($content |Where-Object {$_ -match 'changeLog\.md'}) |Should -Not -BeNullOrEmpty
    }

    it 'Should list the functions section in the homepage sections table' {
        $content = get-content (join-path $newDocsPath 'index.md')
        ($content |Where-Object {$_ -match '\[Functions\]'}) |Should -Not -BeNullOrEmpty
    }

    # --- SkipIndex ---

    Describe 'write-mfModuleDocs with SkipIndex' {
        BeforeAll {
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

    # --- StampAllDocs ---

    Describe 'write-mfModuleDocs with StampAllDocs' {
        BeforeAll {
            # Create a misc section with a plain page and a pre-stamped page
            $miscPath = join-path $newDocsPath 'misc'
            New-Item -ItemType Directory -Path $miscPath -Force | Out-Null
            "# About This Thing`n`nSome content here." | Out-File (join-path $miscPath 'About.md') -Force

            # Pre-existing page with JTD front matter — must not be touched
            @"
---
layout: default
title: Custom Title
parent: Misc
---
# Custom Title
Custom content.
"@ | Out-File (join-path $miscPath 'CustomPage.md') -Force

            # Create a tutorials section with a github sub-section and an img folder (no .md files)
            $tutorialsPath = join-path $newDocsPath 'tutorials'
            $githubPath    = join-path $tutorialsPath 'github'
            $imgPath       = join-path $tutorialsPath 'img'
            New-Item -ItemType Directory -Path $githubPath -Force | Out-Null
            New-Item -ItemType Directory -Path $imgPath    -Force | Out-Null
            "# Getting Started`n`nTutorial content." | Out-File (join-path $githubPath 'Tutorial01.md') -Force
            # img folder intentionally has no .md files

            write-mfModuleDocs -modulename platyPsTest -path $docsPath -StampAllDocs
        }

        It 'Should stamp a plain page with JTD front matter' {
            $content = get-content (join-path $miscPath 'About.md')
            $content |Should -contain 'layout: default'
            $content |Should -contain 'parent: Misc'
        }

        It 'Should use the H1 heading as the title in stamped pages' {
            $content = get-content (join-path $miscPath 'About.md')
            $content |Should -contain 'title: About This Thing'
        }

        It 'Should not modify pages that already have JTD front matter' {
            $content = get-content (join-path $miscPath 'CustomPage.md')
            $content |Should -contain 'title: Custom Title'
            ($content |Where-Object {$_ -eq 'title: Misc'}) |Should -BeNullOrEmpty
        }

        It 'Should create a parent index.md for the misc section' {
            Test-Path (join-path $miscPath 'index.md') |Should -Be $true
            $content = get-content (join-path $miscPath 'index.md')
            $content |Should -contain 'has_children: true'
            $content |Should -contain 'title: Misc'
        }

        It 'Should include child links in the misc index' {
            $content = get-content (join-path $miscPath 'index.md')
            ($content |Where-Object {$_ -match 'About This Thing'}) |Should -Not -BeNullOrEmpty
        }

        It 'Should create a parent index.md for the tutorials section' {
            Test-Path (join-path $tutorialsPath 'index.md') |Should -Be $true
            $content = get-content (join-path $tutorialsPath 'index.md')
            $content |Should -contain 'has_children: true'
            $content |Should -contain 'title: Tutorials'
        }

        It 'Should create a sub-section index.md for tutorials/github' {
            Test-Path (join-path $githubPath 'index.md') |Should -Be $true
            $content = get-content (join-path $githubPath 'index.md')
            $content |Should -contain 'has_children: true'
            $content |Should -contain 'parent: Tutorials'
        }

        It 'Should stamp the grandchild page with parent and grand_parent' {
            $content = get-content (join-path $githubPath 'Tutorial01.md')
            $content |Should -contain 'parent: Github'
            $content |Should -contain 'grand_parent: Tutorials'
        }

        It 'Should skip the img folder because it contains no markdown files' {
            Test-Path (join-path $imgPath 'index.md') |Should -Be $false
        }

        It 'Should list stamped sections in the homepage sections table' {
            $content = get-content (join-path $newDocsPath 'index.md')
            ($content |Where-Object {$_ -match '\[Misc\]'})      |Should -Not -BeNullOrEmpty
            ($content |Where-Object {$_ -match '\[Tutorials\]'}) |Should -Not -BeNullOrEmpty
        }
    }

    AfterAll{
        remove-alias git
        remove-module platyPsTest,platyPs -ErrorAction Ignore
        remove-item -Path $testPath -Force -recurse
    }
}
