[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{
    $WarningPreference = 'SilentlyContinue'
    #Load This File
    $fileName = $PSCommandPath.Replace('.Tests.ps1','.ps1')
    $functionName = 'Resolve-MFModuleCase'
    . $fileName
    
    $TestModuleName = 'ModuleForgeCaseTest'

    #Remove our test module and start clean
    Uninstall-PSResource -Name $TestModuleName -ErrorAction Ignore -Scope CurrentUser

    #Fresh Install our test module
    Install-PSResource $TestModuleName -Repository PSGallery -TrustRepository -Scope CurrentUser

    #Now we need to figure out how to do a rename of our module
    #I suspect things from the PSGallery are discoverable with Get-Module, because they won't have this problem
    $ModuleBase = (Get-Module $TestModuleName -ListAvailable | Select-Object -First 1).ModuleBase
    $ModuleFolder = Split-Path $ModuleBase -Parent
    If($ModuleFolder)
    {
        Rename-Item -Path $ModuleFolder -NewName $TestModuleName.ToLower() 
        Start-Sleep -Seconds 4
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

Describe 'Check Resolve-MFModuleCase with bad case folder' {
    BeforeAll {
        $Result = resolve-MFModuleCase -ModuleName $TestModuleName
    }

    It 'Should have Attempted a rename' {
        $Result.RenameAttempt | Should -Be $true
    }
    It 'Should have case matching Manifest and FolderBase names' {
        $Result.ManifestAndFolderMatch |  Should -Be $true
    }
}

Describe 'Check Resolve-MFModuleCase with good case folder' {
    BeforeAll {
        $Result2 = resolve-MFModuleCase -ModuleName $TestModuleName
    }

    It 'Should not have Attempted a rename' {
        $Result2.RenameAttempt | Should -Be $false
    }
    It 'Should still have case matching Manifest and FolderBase names' {
        $Result2.ManifestAndFolderMatch |  Should -Be $true
    }
}

Describe 'Resolve-MFModuleCase with an explicit ModuleFolder' {
    BeforeAll {
        # By this point the earlier describes have corrected the folder casing, so -Filter matches
        # the now-PascalCase folder on both case-sensitive and case-insensitive filesystems.
        $ModulesRoot = Split-Path (Split-Path (Get-Module $TestModuleName -ListAvailable | Select-Object -First 1).ModuleBase -Parent) -Parent
        $Result3 = Resolve-MFModuleCase -ModuleName $TestModuleName -ModuleFolder $ModulesRoot
    }

    It 'Should resolve the module using the supplied ModuleFolder path' {
        $Result3 | Should -Not -BeNullOrEmpty
    }
    It 'Should report case matching Manifest and FolderBase names' {
        $Result3.ManifestAndFolderMatch | Should -Be $true
    }
}

Describe 'Resolve-MFModuleCase with a module that does not exist' {
    It 'Should warn and return nothing when the module is not installed' {
        $result = Resolve-MFModuleCase -ModuleName 'ThisModuleDefinitelyDoesNotExist99999'
        $result | Should -BeNullOrEmpty
    }
}

AfterAll {
    #Remove our test module and start clean
    Uninstall-PSResource -Name $TestModuleName -ErrorAction Ignore -Scope CurrentUser
}