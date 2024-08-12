
@{
  FunctionsToExport = @('add-mfRepositoryXmlData','build-mfProject','get-mfDependencyTree','get-mfDependencyTreeAsJob','get-mfFolderItems','get-mfNextSemver','Get-mfScriptDetails','get-mfScriptText','new-mfProject','publish-mfGithubPackage','register-mfLocalPsResourceRepository','Remove-mfLocalPsResourceRepository','update-mfProject')
  Description = 'ModuleForge is a PowerShell scaffolding and build tool for creating other PowerShell modules. With ModuleForge, you can easily generate the foundational structure, boilerplate code, and github actions build techniques'
  PrivateData = @{
    moduleCompiledBy = 'Bartender | A Framework for making PowerShell Modules'
    bartenderVersion = '6.2.0'
    PSData = @{
      LicenseUri = 'https://github.com/adrian-andersson/ModuleForge/blob/main/LICENSE'
      ProjectUri = 'https://github.com/adrian-andersson/ModuleForge'
    }
    builtBy = 'AdrianAndersson'
    bartenderCopyright = '2020 Domain Group'
    moduleRevision = '0.0.29.1'
    builtOn = '2024-08-10T19:53:46'
  }
  NestedModules = @('validators.ps1')
  CmdletsToExport = @()
  ModuleVersion = '0.0.30'
  PowerShellVersion = '7.2.0'
  GUID = 'c3746b45-1434-492b-b81b-1793dbc1973a'
  AliasesToExport = @()
  ScriptsToProcess = 'validators.ps1'
  RootModule = 'ModuleForge.psm1'
  Author = 'Adrian Andersson'
  Copyright = '2024  '
  CompanyName = ' '
}
