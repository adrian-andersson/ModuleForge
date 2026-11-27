[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{

    $WarningPreference = 'SilentlyContinue'

    #Load This File (the function lives alongside this test in source/private)
    $fileName = ($PSCommandPath -replace '\.tests\.ps1$','.ps1')
    $functionName = 'Format-MFManifestBlock'
    . $fileName

    #Write a block into a minimal manifest, the way Build-MFProject does, and read it back
    $readBlock = {
        param([string]$Block)
        $path = Join-Path $TestDrive "$(New-Guid).psd1"
        "@{`n    PrivateData = @{`n$Block`n    }`n}" | Set-Content -Path $path -Encoding utf8
        (Import-PowerShellDataFile -Path $path).PrivateData
    }
}

Describe 'Check Clean Environment' {
    It 'Should have loaded the function directly, not from an imported module' {
        (get-command $functionName).source | should -BeNullOrEmpty
    }
}

Describe 'Format-MFManifestBlock' {
    It 'Should write a block that reads back as the same values' {
        $block = Format-MFManifestBlock -Name 'ModuleForge' -Data ([ordered]@{ Version = '1.5.0-prev001'; BuildDate = '2026-11-27T11:56:21' }) -Indent '        '
        $data = & $readBlock $block
        $data.ModuleForge.Version | Should -Be '1.5.0-prev001'
        $data.ModuleForge.BuildDate | Should -Be '2026-11-27T11:56:21'
    }

    It 'Should write nested dictionaries as nested blocks' {
        $block = Format-MFManifestBlock -Name 'ModuleForge' -Data ([ordered]@{ Version = '1.0.0'; Source = [ordered]@{ Commit = 'abc123'; RunId = '42' } })
        $data = & $readBlock $block
        $data.ModuleForge.Source.Commit | Should -Be 'abc123'
        $data.ModuleForge.Source.RunId | Should -Be '42'
    }

    It 'Should keep the order it was given' {
        $block = Format-MFManifestBlock -Name 'Block' -Data ([ordered]@{ Zulu = '1'; Alpha = '2'; Mike = '3' })
        $keys = ($block -split "`n" | Where-Object { $_ -match '^\s+(\w+) = ' } | ForEach-Object { $Matches[1] })
        $keys | Should -Be @('Zulu','Alpha','Mike')
    }

    It 'Should indent each level from the indent given' {
        $lines = (Format-MFManifestBlock -Name 'Block' -Data ([ordered]@{ Key = 'value'; Group = [ordered]@{ Inner = 'x' } }) -Indent '    ') -split "`n"
        $lines[0] | Should -Be '    Block = @{'
        $lines[1] | Should -Be "        Key = 'value'"
        $lines[2] | Should -Be '        Group = @{'
        $lines[3] | Should -Be "            Inner = 'x'"
        $lines[-1] | Should -Be '    }'
    }

    It 'Should escape single quotes, so a value cannot break out of its string' {
        $value = "it's'; Remove-Item C:\ -Recurse; '"
        $data = & $readBlock (Format-MFManifestBlock -Name 'Block' -Data ([ordered]@{ Key = $value }))
        $data.Block.Key | Should -Be $value
    }

    It 'Should leave out empty values and empty groups' {
        $block = Format-MFManifestBlock -Name 'Block' -Data ([ordered]@{ Kept = 'yes'; Empty = ''; Missing = $null; Group = [ordered]@{} })
        $block | Should -Not -Match 'Empty|Missing|Group'
        (& $readBlock $block).Block.Kept | Should -Be 'yes'
    }

    It 'Should refuse a key that is not letters and numbers' {
        { Format-MFManifestBlock -Name 'Block' -Data ([ordered]@{ 'Bad Key' = 'x' }) } | Should -Throw '*letters and numbers*'
        { Format-MFManifestBlock -Name 'Bad-Name' -Data ([ordered]@{ Key = 'x' }) } | Should -Throw
    }
}
