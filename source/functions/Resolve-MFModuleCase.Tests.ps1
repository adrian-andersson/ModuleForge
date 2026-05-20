BeforeAll{
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
        Rename-Item -Path $ModuleInstallLocation -NewName $TestModuleName.ToLower() 
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

AfterAll {
    #Remove our test module and start clean
    Uninstall-PSResource -Name $TestModuleName -ErrorAction Ignore -Scope CurrentUser
}