
@{
  NestedModules = @('validators.ps1')
  ModuleVersion = '0.0.29'
  Author = 'Adrian Andersson'
  PrivateData = @{
    moduleRevision = '0.0.28.1'
    moduleCompiledBy = 'Bartender | A Framework for making PowerShell Modules'
    builtOn = '2024-08-10T19:33:46'
    bartenderVersion = '6.2.0'
    PSData = @{
      LicenseUri = 'https://github.com/adrian-andersson/ModuleForge/blob/main/LICENSE'
      ProjectUri = 'https://github.com/adrian-andersson/ModuleForge'
      ReleaseNotes = 'v 29'
    }
    bartenderCopyright = '2020 Domain Group'
    builtBy = 'AdrianAndersson'
  }
  ScriptsToProcess = 'validators.ps1'
  AliasesToExport = @()
  FunctionsToExport = @('add-mfRepositoryXmlData','build-mfProject','get-mfDependencyTree','get-mfDependencyTreeAsJob','get-mfFolderItems','get-mfNextSemver','get-mfScriptText','new-mfProject','publish-mfGithubPackage','register-mfLocalPsResourceRepository','Remove-mfLocalPsResourceRepository','update-mfProject')
  CompanyName = ' '
  RootModule = 'ModuleForge.psm1'
  GUID = 'c3746b45-1434-492b-b81b-1793dbc1973a'
  CmdletsToExport = @()
  Copyright = '2024  '
  Description = 'ModuleForge is a PowerShell scaffolding and build tool for creating other PowerShell modules. With ModuleForge, you can easily generate the foundational structure, boilerplate code, and github actions build techniques'
  PowerShellVersion = '7.2.0'
}
