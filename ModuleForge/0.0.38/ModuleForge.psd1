
@{
  CompanyName = ' '
  PrivateData = @{
    moduleCompiledBy = 'Bartender | A Framework for making PowerShell Modules'
    builtBy = 'AdrianAndersson'
    bartenderVersion = '6.2.0'
    bartenderCopyright = '2020 Domain Group'
    builtOn = '2024-08-12T16:50:15'
    PSData = @{
      LicenseUri = 'https://github.com/adrian-andersson/ModuleForge/blob/main/LICENSE'
      ProjectUri = 'https://github.com/adrian-andersson/ModuleForge'
    }
    moduleRevision = '0.0.37.1'
  }
  Description = 'ModuleForge is a PowerShell scaffolding and build tool for creating other PowerShell modules. With ModuleForge, you can easily generate the foundational structure, boilerplate code, and github actions build techniques'
  GUID = 'c3746b45-1434-492b-b81b-1793dbc1973a'
  FunctionsToExport = @('add-mfRepositoryXmlData','build-mfProject','get-mfDependencyTree','get-mfFolderItemDetails','get-mfFolderItems','get-mfNextSemver','Get-mfScriptFunctionDetails','new-mfProject','publish-mfGithubPackage','register-mfLocalPsResourceRepository','remove-mfLocalPsResourceRepository','update-mfProject')
  PowerShellVersion = '7.2.0'
  CmdletsToExport = @()
  RootModule = 'ModuleForge.psm1'
  ScriptsToProcess = @()
  AliasesToExport = @()
  ModuleVersion = '0.0.38'
  Copyright = '2024  '
  Author = 'Adrian Andersson'
}
