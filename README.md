# ModuleForge

ModuleForge is a scaffolding and build tool for creating other PowerShell modules. With ModuleForge, you can easily generate the foundational structure and compile all your files into a working module.

## Objectives of this module

What I wanted to achieve with this tool was the following:

- Have a fast way to create modules to a standardised source structure, and supporting modern PowerShell best-practices
- Support and use the latest versions of PowerShell (7+), pester, and Nuget for your packaging
- Use PSResourceGet for module management instead of the now legacy PowerShell Get
- Support Module PreRelease tags and assist with versioning
- Support Semantic Versioning
- Support simple and complex PowerShell modules alike, with Cross-Platform Compatibility and Pester Testing at the forefront
- Provide direction on getting the most out of Pester for Module Development
- Easily identify function and file dependencies in your code
- Provide workarounds and _bootstraps_ for using this module with modern orchestration tools, including GitHub Actions + GitHub Packages, AzureDevops Pipelines + Packages
- Maintain backwards compatibility with my old ~2017 BarTender scaffolding tool

## Why do we need another Scaffolding tool?

Good question, I had some pretty clear objectives and goals for this module (see above). If you already have a good pipeline that works for you and your module needs, please keep using it. This scaffolding module is built for what works for me. That said, I built ModuleForge to be compatible with a wide range of other supporting modules and tools. For example, it will work fine if you're using PSake or PSBuild. It will help you with module versioning, with whatever private repository you want to use, and a variety of other things.

## Tested Compatibility

- GitHub
  - Works with GitHub Actions, including the _ubuntu latest_ runner.
  - Supports releases and Packages in GitHub as well
- Azure DevOps
  - Works on Azure DevOps pipelines
  - Works for Azure DevOps Packages
- Bitbucket
  - Tested Bitbucket Pipelines
- PSGallery
  - Tested module compatibility with PSGallery

## ModuleForge Dependencies

ModuleForge was built with Pester v5.6.1 and Microsoft.PowerShell.PSResourceGet v1.0.5

If you encounter any issues with Pester or PowerShellGet, run the following code snippet and then restart your PowerShell terminal.

```PowerShell
install-module -name pester -repository psgallery -force

install-module -name Microsoft.PowerShell.PSResourceGet -force
```

Since the old PowerShellGet is deprecated, you should consider using the new PSResourceGet commands anyway (I.e. use install-psresource instead of install-module)

## Getting Started

Tutorial Coming Soon

## Bartender Refactor and Compatibility

If you used my previous module for this: [bartender](https://github.com/DomainGroupOSS/bartender), then I tried to keep it backwards compatible. Some Notes on this

- The versioning should now be tracked by your build orchestration tool. PSake, GitHub Actions etc, not the module itself. 
  - I'm partial to GitHub tags, but you could also retrieve the version from a PSRepository directly
  - I've included a function, `get-mfNextSemver` to help with figuring out what your next version could be
  - I've moved to SemVer v1.0 myself, this supports using GitHub packages and psgallery. `get-mfNextSemver` uses that
  - Check [this](../documentation/SemVer_Interpretation.md) for how I'm using this
- ModuleForge is cross-platform compatible and works well with GitHub Actions Ubuntu Latest
- I've added a `add-mfRepositoryXmlData` function if you want to use GitHub Packages
- I've tried to remove anything that was orchestration specific, other than support for GitHub packages
  - There is no more PlatyPS bits
  - There isn't postbuildscripts support

## ToDo

- [ ] better documentation in this readme file
- [X] Add a way to build a file dependency tree.
- [X] Add support back in for Icons
- [X] Add support and commentary in for module DefaultCommandPrefix
- [x] Add support for RequiredModules
- [x] Add support for ExternalModuleDependencies.
- [X] Add more details into PrivateData
  - Partial implementation.
  - Right now, pass through to manifest splat
- [ ] Fix DSC modules
  - Have attempted a first pass at DSC, but there are currently problems and I don't have a good test scenario. 
  - Will revisit at a later time. Do people still make DSC modules?
- [ ] Add some Bootstrap code to get GitHub Actions code and template created
- [ ] Add some Bootstrap code to get Azure DevOps code and template created
- [ ] Automatically add the Commit Messages to the Release Notes.
