# ModuleForge

ModuleForge is a scaffolding and build tool for creating other PowerShell modules. With ModuleForge, you can easily generate the foundational structure and compile all your files into a working module.

## ModuleForge Dependencies

ModuleForge was built with Pester v5.6.1 and Microsoft.PowerShell.PSResourceGet v1.0.5

If you have any pester or powershellget problems, I Suggest you run the below code-snippet first, then restart your powershell terminal.

```PowerShell
install-module -name pester -repository psgallery -force

install-module -name Microsoft.PowerShell.PSResourceGet -force
```

Since the old PowerShellGet is deprecated, you should consider using the new PSResourceGet commands anyway (I.e. use install-psresource instead of install-module)

## Getting Started

Coming Soon

## Bartender Refactor and Compatibility

If you used my previous module for this: [bartender](https://github.com/DomainGroupOSS/bartender), then I tried to keep it backwards compatible. Some Notes on this

- The versioning should now be tracked by your build orchestration tool. PSake, Github Actions etc, not the module itself. 
  - I'm partial to github tags, but you could also retrieve the version from a PSRepository directly
  - I've included a function, `get-mfNextSemver` to help with figuring out what your next version could be
  - I've moved to SemVer v1.0 myself, this supports using github packages and psgallery. `get-mfNextSemver` uses that
  - Check [this](../documentation/SemVer_Interpretation.md) for how I'm using this
- ModuleForge is cross-platform compatible and works well with GitHub Actions Ubuntu Latest
- I've added a `add-mfRepositoryXmlData` function if you want to use Github Packages
- I've tried to remove anything that was orchestration specific, other than support for github packages
  - There is no more PlatyPS bits
  - There isn't postbuildscripts support

## ToDo

- [ ] better Documentation in this readme file
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
