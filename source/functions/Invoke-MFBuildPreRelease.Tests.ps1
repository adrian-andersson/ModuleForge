[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{
    $WarningPreference = 'SilentlyContinue'
    $functionsDir = Split-Path $PSCommandPath -Parent
    $sourceDir    = Split-Path $functionsDir -Parent

    $dependencies = [ordered]@{
        functions = @('Get-MFLatestSemverFromBuildManifest.ps1','Get-MFNextSemver.ps1')
        private   = @('Get-MFProjectRoot.ps1')
    }
    $dependencies.GetEnumerator().ForEach{
        $dirRef = join-path $sourceDir $_.Key
        $_.Value.ForEach{
            $itemPath = join-path $dirRef $_
            $item = get-item $itemPath -ErrorAction SilentlyContinue -ProgressAction SilentlyContinue
            if($item){. $item.FullName}else{write-warning "Dependency not found: $itemPath"}
        }
    }
    #Stub BuildMFProject so we can check the parameters sent to it without actually running a build
    function Build-MFProject {
        param(
            [Parameter()]$Version,
            [Parameter()]$ModulePath,
            [Parameter()]$ConfigFile
        )
        throw "Stub should be mocked"
    }

    $global:__BuildMFProjectCalls = @()

    #Load This File
     $fileName = $PSCommandPath.Replace('.Tests.ps1','.ps1')
     $functionName = 'Invoke-MFBuildPreRelease'
    . $fileName
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

Describe 'Invoke-MFBuildPreRelease' {
    BeforeAll{
        $testRoot = join-path ([System.IO.Path]::GetTempPath())"MFTest_$([System.IO.Path]::GetRandomFileName())"
        New-Item -ItemType Directory -Path $testRoot | Out-Null

        @{moduleName = 'TestModule'} | Export-Clixml (join-path $testRoot 'moduleForgeConfig.xml')

        $moduleFolder = join-path $testRoot 'build' 'TestModule'
        New-Item -ItemType Directory -Path $moduleFolder -Force | Out-Null
        New-ModuleManifest -Path (join-path $moduleFolder 'TestModule.psd1') `
            -ModuleVersion '1.0.0' `
            -Description 'Test manifest' `
            -Prerelease 'prev001'

        Mock Build-MFProject {}
    }

    AfterAll{
        Remove-Item $testRoot -Recurse -Force -ErrorAction SilentlyContinue -ProgressAction SilentlyContinue
    }

    It 'should call Build-MFProject once' {
        Invoke-MFBuildPreRelease -ModulePath $testRoot
        Should -Invoke Build-MFProject -Times 1
    }

    It 'should pass the incremented pre-release version to Build-MFProject' {
        Invoke-MFBuildPreRelease -ModulePath $testRoot
        Should -Invoke Build-MFProject -ParameterFilter {$Version.ToString() -eq '1.0.0-prev002'}
    }

    It 'should pass the resolved project root path to Build-MFProject' {
        Invoke-MFBuildPreRelease -ModulePath $testRoot
        Should -Invoke Build-MFProject -ParameterFilter {$ModulePath -eq $testRoot}
    }

    It 'should find the project root when called from a subdirectory' {
        $subDir = join-path $testRoot 'source' 'functions'
        New-Item -ItemType Directory -Path $subDir -Force | Out-Null
        Invoke-MFBuildPreRelease -ModulePath $subDir
        Should -Invoke Build-MFProject -Times 1
    }
}

Describe 'Invoke-MFBuildPreRelease Error Handling' {
    BeforeAll{
        Mock Build-MFProject {}
    }
    It 'should throw when no moduleForgeConfig.xml is found' {
        $emptyDir = join-path ([System.IO.Path]::GetTempPath())"MFEmpty_$([System.IO.Path]::GetRandomFileName())"
        New-Item -ItemType Directory -Path $emptyDir | Out-Null
        try{
            {Invoke-MFBuildPreRelease -ModulePath $emptyDir} | Should -Throw
        }finally{
            Remove-Item $emptyDir -Force -Recurse -ErrorAction SilentlyContinue -ProgressAction SilentlyContinue
        }
    }
}

Describe 'Check we still have a Clean Environment' {
    BeforeAll {
        write-warning "PSCommandPath: $psCommandPath; scriptToLoad: $($PSCommandPath.Replace('.Tests.ps1','.ps1'))"
    }
    It 'Should have loaded the script directly, not from the module' {
        $PSCommandPath.Replace('.Tests.ps1','.ps1')|should -be $fileName
        (get-command $functionName).source |should -BeNullOrEmpty
    }
}