[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'
    #Reference Current Path
    $currentPath = $(get-location).path

    # Add-MFRepositoryXmlData depends only on built-in cmdlets (Expand-Archive, XML, Compress-Archive),
    # so there are no source-function dependencies to dot-source.

    #Load This File
    $fileName = $PSCommandPath.Replace('.Tests.ps1','.ps1')
    $functionName = 'Add-MFRepositoryXmlData'
    . $fileName

    #Create a working folder under the project root (consistent with the other tests). Keeping all file IO
    #inside the repo workspace is also safer on locked-down CI runners than reaching into the system temp path.
    $repoXmlTestPath = join-path -path $currentPath -childPath 'repoXmlTest'
    if(test-path $repoXmlTestPath){ remove-item $repoXmlTestPath -Recurse -Force -ErrorAction Ignore }
    $null = new-item -ItemType Directory -Path $repoXmlTestPath

    #The nuspec namespace the function reads via $nuSpecXml.package.namespaceURI
    $nuspecNamespace = 'http://schemas.microsoft.com/packaging/2013/05/nuspec.xsd'

    #Build a minimal but valid .nupkg - a zip holding a .nuspec plus a dummy payload file.
    #A .nupkg is just a zip, so we can synthesise one without NuGet present.
    $packSource = join-path $repoXmlTestPath 'packSource'
    $null = new-item -ItemType Directory -Path $packSource

    $nuspecXmlText = @"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="$nuspecNamespace">
  <metadata>
    <id>TestModule</id>
    <version>1.0.0</version>
    <authors>Pester</authors>
    <description>Synthetic package for testing Add-MFRepositoryXmlData</description>
  </metadata>
</package>
"@
    $nuspecXmlText | Out-File -FilePath (join-path $packSource 'TestModule.nuspec') -Encoding utf8
    'dummy payload content' | Out-File -FilePath (join-path $packSource 'TestModule.psm1') -Encoding utf8

    $nupkgPath = join-path $repoXmlTestPath 'TestModule.1.0.0.nupkg'
    Compress-Archive -Path (join-path $packSource '*') -DestinationPath $nupkgPath -Force

    #Act - inject the repository data. -Force avoids the interactive Read-Host on the extraction folder.
    #An explicit -ExtractionPath inside the sandbox keeps the function from touching the system temp path.
    $extractionPath = join-path $repoXmlTestPath 'extract'
    Add-MFRepositoryXmlData -RepositoryUri 'https://github.com/test/repo' -NugetPackagePath $nupkgPath -Branch 'main' -Commit 'abc123' -ExtractionPath $extractionPath -Force

    #Read the repacked nupkg back to verify the injection survived the unpack -> edit -> repack round-trip
    $verifyPath = join-path $repoXmlTestPath 'verify'
    Expand-Archive -Path $nupkgPath -DestinationPath $verifyPath -Force
    $repackedNuspecFile = Get-ChildItem $verifyPath -Filter '*.nuspec' -Recurse | Select-Object -First 1
    [xml]$repackedNuspec = Get-Content $repackedNuspecFile.FullName -Raw
    $repackedFileNames = (Get-ChildItem $verifyPath -Recurse -File).Name
}

Describe 'Check Clean Environment' {
    It 'Should have loaded the script directly, not from the module' {
        $PSCommandPath.Replace('.Tests.ps1','.ps1') | should -be $fileName
        (get-command $functionName).source | should -BeNullOrEmpty
    }
}

Describe 'Add-MFRepositoryXmlData' {

    It 'Should inject a repository element into the nuspec metadata' {
        $repackedNuspec.package.metadata.repository | Should -Not -BeNullOrEmpty
    }

    It 'Should set the repository type to git' {
        $repackedNuspec.package.metadata.repository.type | Should -Be 'git'
    }

    It 'Should set the repository url' {
        $repackedNuspec.package.metadata.repository.url | Should -Be 'https://github.com/test/repo'
    }

    It 'Should set the branch attribute when supplied' {
        $repackedNuspec.package.metadata.repository.branch | Should -Be 'main'
    }

    It 'Should set the commit attribute when supplied' {
        $repackedNuspec.package.metadata.repository.commit | Should -Be 'abc123'
    }

    It 'Should preserve the original package payload through the repack' {
        $repackedFileNames | Should -Contain 'TestModule.psm1'
    }

    It 'Should throw when the supplied file is not a .nupkg' {
        $notNupkg = join-path $repoXmlTestPath 'notapackage.txt'
        'not a package' | Out-File -FilePath $notNupkg
        { Add-MFRepositoryXmlData -RepositoryUri 'https://github.com/test/repo' -NugetPackagePath $notNupkg -Force } | Should -Throw '*not a .nupkg file*'
    }
}

AfterAll{
    remove-item $repoXmlTestPath -Recurse -Force -ErrorAction Ignore -ProgressAction SilentlyContinue
}
