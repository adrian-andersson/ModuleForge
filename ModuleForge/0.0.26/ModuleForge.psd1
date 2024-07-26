
@{
  Copyright = '2024  '
  CmdletsToExport = @()
  Description = 'ModuleForge is a PowerShell scaffolding and build tool for creating other PowerShell modules. With ModuleForge, you can easily generate the foundational structure, boilerplate code, and github actions build techniques'
  FunctionsToExport = @('build-mfProject','get-mfFolderItems','get-mfScriptText','new-mfProject','register-mfLocalPsResourceRepository','Remove-mfLocalPsResourceRepository')
  PrivateData = @{
    moduleRevision = '0.0.25.2'
    PSData = @{
      ProjectUri = 'https://github.com/adrian-andersson/ModuleForge'
      LicenseUri = 'https://github.com/adrian-andersson/ModuleForge/blob/main/LICENSE'
      ReleaseNotes = 'First build'
    }
    moduleCompiledBy = 'Bartender | A Framework for making PowerShell Modules'
    builtBy = 'AdrianAndersson'
    builtOn = '2024-07-26T13:40:58'
    bartenderCopyright = '2020 Domain Group'
    bartenderVersion = '6.2.0'
  }
  GUID = 'c3746b45-1434-492b-b81b-1793dbc1973a'
  AliasesToExport = @()
  ScriptsToProcess = @()
  CompanyName = ' '
  RootModule = 'ModuleForge.psm1'
  PowerShellVersion = '7.2.0'
  ModuleVersion = '0.0.26'
  Author = 'Adrian Andersson'
}
