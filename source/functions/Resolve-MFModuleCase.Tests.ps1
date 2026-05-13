BeforeAll{
    #Load This File
     $fileName = $PSCommandPath.Replace('.Tests.ps1','.ps1')
     $functionName = 'Resolve-MFModuleCase'
    . $fileName


    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    #Create a temp folder so we don't clobber anything
    $testPath = join-path -path $currentPath -childPath 'moduletest'
    $testModuleName = 'moduleTest'
    $testPsm1Path = join-path $testPath -ChildPath "$testModuleName.psm1"
    $testPsd1Path = join-path $testPath -ChildPath "$testModuleName.psd1"
    
    
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

describe 'Make badCase Module' {
    beforeAll {
        write-verbose 'build test module files'
        $testPsm1 = @(
            'function get-text {'
            '    param ('
            '        [string]$returnString = "Hello"'
            '    )'
            '    process {'
            '        return $returnString'
            '    }'
            '}'
        )

        $testPsd1 = @(
            '@{'
            "'RootModule = '$testModuleName.psm1'"
            "GUID = 'f9d99e7b-8ffe-46d3-b990-80b21dc8c6c5'"
            "Author = 'Test.Module'"
            "Author = 'Test.Module'"
            "CompanyName = 'Adrian.Andersson'"
            "Copyright = '2025 Adrian.Andersson'"
            "Description = 'A test module'"
            "PowerShellVersion = '7.2'"
            "FunctionsToExport = 'get-text'"
            "CmdletsToExport = @()"
            "VariablesToExport = '*'"
            "AliasesToExport = '*'"
            "PrivateData = @{"
            "PSData = @{"
            "Tags = 'Test'"
            '}'
            '}'
            '}'
        )

        $testManifest

        write-verbose "Create module directory at: $testPath"
        new-item -itemType Directory -Path $testPath

        $testPsm1 -join "`n"|Out-File $testPsm1Path -force
        $testPsd1 -join "`n"|Out-File $testPsd1Path -force
    }

    It 'Should have created a psd1 file' {
        (get-childItem -path 'moduletest' -recurse -filter '*.psd1').count |Should -be 1
    }

    It 'Should have created a psm1 file' {
        (get-childItem -path 'moduletest' -recurse -filter '*.psm1').count |Should -be 1
    }
    
}

describe 'Resolve Module Case' {
    BeforeAll {
        $testModuleRoot = Split-Path $testPath -Parent
        # Store original path to restore later
        $originalPath = $env:PSModulePath
    }

    It 'Should resolve the module casing correctly' {
        # Temporarily point PSModulePath to our local test root
        $env:PSModulePath = "$testModuleRoot$([IO.Path]::PathSeparator)$originalPath"

        try {
            # Execute the function
            $result = Resolve-MFModuleCase -ModuleName $testModuleName
            
            # 1. Check the return object
            $result.Name | Should -Be $testModuleName

            # 2. Verify the physical folder rename
            # On Linux: This is the real test.
            # On Windows: This verifies the logic ran (if Windows didn't auto-resolve)
            $finalFolder = Get-Item $testPath
            if ($IsWindows) {
                # On Windows, we just care that the folder exists and is discoverable.
                # The OS won't let us prove the case change easily without a "middle-man" rename.
                $finalFolder.Name | Should -Be $testModuleName
            }
            else {
                # On Linux, the case must be EXACT or discovery breaks.
                $finalFolder.Name | Should -BeExact $testModuleName
            }
        }
        finally {
            $env:PSModulePath = $originalPath
        }
    }
}


AfterAll {
    if (Test-Path $testPath) {
        Remove-Item $testPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}