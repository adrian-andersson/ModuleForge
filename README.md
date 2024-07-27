# ModuleForge
ModuleForge is a powerful scaffolding and build tool for creating other PowerShell modules. With ModuleForge, you can easily generate the foundational structure, boilerplate code, and github actions build techniques


## ToDo

- [ ]Add a way to build a file dependency tree. Should help with building pester dependencies and maybe we can make a mermaid chart out of it for documentation purposes
- [ ] Add a function to publish to packages. At least add the repository to the nuspec
- [ ] Add support back in for Icons
- [ ] Add support and commentary in for module DefaultCommandPrefix 
- [ ] Add support for RequiredModules
- [ ] Add support for ExternalModuleDependencies.
- [ ] Add more details into PrivateData
- [ ] Consider the implications of not building until AFTER pester
- [ ] Save to config more pester option:
    - including a bool for codecoverage
    - Include INTS, 1 each for prerelease and non-prerelease modules.
        - (PreRelease could be much lower, like 30 percent for prerelease and 60 percent for non as an example)
 - [ ] Add a way to include own private data
 - [ ] Consider adding back PlatyPS for help documentation and changelogs stuff. It worked pretty well in Bartender


 ## RequiredModules and ExternalModule ExternalModuleDependencies

 As disussed [here on reddit](https://www.reddit.com/r/PowerShell/comments/7lt6mz/module_manifests_requiredmodules_vs/) and [in this linked github issue](https://github.com/OneGet/oneget/issues/164)


 > So a brief bit of googling turned this up. It seems that, on some level, RequiredModules should be used for all internal and external modules that your module depends on. ExternalModuleDepencies apparently identifies which modules you're not including in the package itself and must also be obtained somehow/somewhere. So you'd list internal dependencies once in RequiredModules and external dependencies twice (once with name and version in RequiredModules and once by name only in ExternalModuleDependencies).


 ## Reminder on Dependencies

 The ModuleForge.Test + ModuleForge worked with Pester v5.6.1 and Microsoft.PowerShell.PSResourceGet v1.0.5

 Suggest you run the below code-snippet first, then restart your powershell terminal.

 After that you should stop using the old powershell get command (I.e. use install-psresource instead of install-module)

```PowerShell
install-module -name pester -repository psgallery -force

install-module -name Microsoft.PowerShell.PSResourceGet -force
```


 ## Hints on Cross-Platform Compatibility with this module

  - Use `join-path` aggresively
  - Case-Sensitivity is important. If you are referencing files and paths on anything but windows, the case matters.
   - FileList in module-manifest doesnt work very well if you keep things in subfolders
   - DSC is kinda broken right now

## About Pester

 - Scoping anything that isn't an exposed function is a little painful. You can use inModuleScope but that breaks the code coverage. You can use using and mocking but thats a lot of work and also mucks up your code coverage. The best way I found of dealing with this is to just dot-source all the dependent files for your function. This works well on Pester 5+ since they use jobs/containers now