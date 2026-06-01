[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{
    $functionsDir = Split-Path $PSCommandPath -Parent
    $sourceDir    = Split-Path $functionsDir -Parent

    $dependencies = [ordered]@{
        private = @('Get-MFProjectRoot.ps1')
    }
    $dependencies.GetEnumerator().ForEach{
        $dirRef = join-path $sourceDir $_.Key
        $_.Value.ForEach{
            $itemPath = join-path $dirRef $_
            $item = get-item $itemPath -ErrorAction SilentlyContinue
            if($item){. $item.FullName}else{write-warning "Dependency not found: $itemPath"}
        }
    }

    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
}

Describe 'Invoke-MFPester' {
    BeforeAll{
        $testRoot = join-path ([System.IO.Path]::GetTempPath())"MFTest_$([System.IO.Path]::GetRandomFileName())"
        $testFunctionsDir = join-path $testRoot 'source' 'functions'
        New-Item -ItemType Directory -Path $testFunctionsDir -Force | Out-Null
        @{moduleName = 'TestModule'} | Export-Clixml (join-path $testRoot 'moduleForgeConfig.xml')

        'function Do-Thing {}' | Set-Content (join-path $testFunctionsDir 'Do-Thing.ps1')
        'function Do-Other {}' | Set-Content (join-path $testFunctionsDir 'Do-Other.ps1')
        ''                    | Set-Content (join-path $testFunctionsDir 'Do-Thing.Tests.ps1')
        ''                    | Set-Content (join-path $testFunctionsDir 'Do-Skip.Skip.ps1')

        $script:capturedConfig = $null
        Mock Invoke-Pester {$script:capturedConfig = $Configuration}
    }

    AfterAll{
        Remove-Item $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'should call Invoke-Pester once' {
        Invoke-MFPester -ModulePath $testRoot
        Should -Invoke Invoke-Pester -Times 1
    }

    It 'should not include .Tests.ps1 files in coverage paths' {
        Invoke-MFPester -ModulePath $testRoot
        ($script:capturedConfig.CodeCoverage.Path.Value | Where-Object {$_ -match '\.Tests\.ps1$'}) | Should -BeNullOrEmpty
    }

    It 'should not include .Skip.ps1 files in coverage paths' {
        Invoke-MFPester -ModulePath $testRoot
        ($script:capturedConfig.CodeCoverage.Path.Value | Where-Object {$_ -match '\.Skip\.ps1$'}) | Should -BeNullOrEmpty
    }

    It 'should include function files in coverage paths' {
        Invoke-MFPester -ModulePath $testRoot
        ($script:capturedConfig.CodeCoverage.Path.Value | Where-Object {$_ -match 'Do-Thing\.ps1$'}) | Should -Not -BeNullOrEmpty
    }
}

Describe 'Invoke-MFPester ExcludeFromCoverage' {
    BeforeAll{
        $testRoot = join-path ([System.IO.Path]::GetTempPath())"MFTest_$([System.IO.Path]::GetRandomFileName())"
        $testFunctionsDir = join-path $testRoot 'source' 'functions'
        New-Item -ItemType Directory -Path $testFunctionsDir -Force | Out-Null
        @{moduleName = 'TestModule'} | Export-Clixml (join-path $testRoot 'moduleForgeConfig.xml')

        'function Do-Thing {}' | Set-Content (join-path $testFunctionsDir 'Do-Thing.ps1')
        'function Do-Complex {}' | Set-Content (join-path $testFunctionsDir 'Do-Complex.ps1')

        $script:capturedConfig = $null
        Mock Invoke-Pester {$script:capturedConfig = $Configuration}
    }

    AfterAll{
        Remove-Item $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'should exclude the specified file from coverage paths' {
        Invoke-MFPester -ModulePath $testRoot -ExcludeFromCoverage 'Do-Complex.ps1'
        ($script:capturedConfig.CodeCoverage.Path.Value | Where-Object {$_ -match 'Do-Complex\.ps1$'}) | Should -BeNullOrEmpty
    }

    It 'should still include non-excluded files in coverage paths' {
        Invoke-MFPester -ModulePath $testRoot -ExcludeFromCoverage 'Do-Complex.ps1'
        ($script:capturedConfig.CodeCoverage.Path.Value | Where-Object {$_ -match 'Do-Thing\.ps1$'}) | Should -Not -BeNullOrEmpty
    }
}

Describe 'Invoke-MFPester Error Handling' {
    It 'should throw when no moduleForgeConfig.xml is found' {
        $emptyDir = join-path ([System.IO.Path]::GetTempPath())"MFEmpty_$([System.IO.Path]::GetRandomFileName())"
        New-Item -ItemType Directory -Path $emptyDir | Out-Null
        try{
            {Invoke-MFPester -ModulePath $emptyDir} | Should -Throw
        }finally{
            Remove-Item $emptyDir -Force -Recurse -ErrorAction SilentlyContinue
        }
    }

    It 'should throw when source\functions folder does not exist' {
        $noFunctionsDir = join-path ([System.IO.Path]::GetTempPath())"MFNoFns_$([System.IO.Path]::GetRandomFileName())"
        New-Item -ItemType Directory -Path $noFunctionsDir | Out-Null
        @{moduleName = 'TestModule'} | Export-Clixml (join-path $noFunctionsDir 'moduleForgeConfig.xml')
        try{
            {Invoke-MFPester -ModulePath $noFunctionsDir} | Should -Throw
        }finally{
            Remove-Item $noFunctionsDir -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
}