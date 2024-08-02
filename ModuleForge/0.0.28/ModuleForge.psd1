
@{
  PrivateData = @{
    moduleRevision = '0.0.27.1'
    PSData = @{
      LicenseUri = 'https://github.com/adrian-andersson/ModuleForge/blob/main/LICENSE'
      ProjectUri = 'https://github.com/adrian-andersson/ModuleForge'
    }
    bartenderVersion = '6.2.0'
    moduleCompiledBy = 'Bartender | A Framework for making PowerShell Modules'
    builtOn = '2024-07-30T20:56:02'
    builtBy = 'AdrianAndersson'
    bartenderCopyright = '2020 Domain Group'
  }
  ScriptsToProcess = @()
  CmdletsToExport = @()
  AliasesToExport = @()
  Author = 'Adrian Andersson'
  Description = 'ModuleForge is a PowerShell scaffolding and build tool for creating other PowerShell modules. With ModuleForge, you can easily generate the foundational structure, boilerplate code, and github actions build techniques'
  GUID = 'c3746b45-1434-492b-b81b-1793dbc1973a'
  CompanyName = ' '
  Copyright = '2024  '
  FunctionsToExport = @('build-mfProject','get-mfDependencyTree','get-mfFolderItems','Get-ScriptDependencies','Get-mfScriptDetails','get-mfScriptText','new-mfProject','register-mfLocalPsResourceRepository','Remove-mfLocalPsResourceRepository')
  PowerShellVersion = '7.2.0'
  ModuleVersion = '0.0.28'
  RootModule = 'ModuleForge.psm1'
}
