# Testing how we get validators, enums and Classes to work Consistently

## Notes on Scope

When you want to use Classes, Enums and custom Validator extensions in your PowerShell module, you need to be aware of the scoping concerns and problems that such objects bring. Essentially

- Classes with Inheritence need to be loaded in the right order, a child class won't compile if it is loaded before it's parent
- Enums should just about in every scenario load first
- All things need to be loaded and compiled correctly before your functions are parsed
- Things that are not explicitely exported in the module manifest aren't going to be scoped to the terminal/session, and instead will only be scoped to the module
- There is no way to export anything other than functions and aliases, which means that effectively all your classes, enums, validators etc are forever going to be Module Scoped, unless you figure out a way to _break them out_, and there is no clean way to do so with a high level of confidence
- Classes and Enums _probably should_ be scoped to the module anyway
  - Unless your doing a Domain-Specific Language module, in which case it might make sense

To stop too much repeating, we will just refer to all classes, enums and validators as _special snowflakes_

### Notes on Nested Modules

Nested Modules refers to when you make a new module manifest, you can provide an array of PS1/PSM1 files that live in the same folder as the Manifest (PSD1) and Root Module (PSM1) file, and when importing the module, these get run first. It looks like this `New-ModuleManifest -NestedModules @('script1','script2')`

This could be used, in theory, to make sure our _special snowflakes_ load in the right order. Here's my notes on testing this out

- Nested Module behaviour is inconsistent and breaks scope, they wont be available to the module
- A module will _NOT_ import correctly _if_ the ENUMS are loaded in a nested module, I think it breaks scope.
  - Enums should go to the top of the root module as a result
- Classes will also _NOT_ import correctly _IF_ they are loaded in a nested module, which also implicates scope as the problem
- _Validators_ are different in that the reverse is true. If you put them at the top of your root module, the functions cannot see them (because they haven't compiled yet?), so they _ONLY_ work as nested modules

### Notes on ScriptsToProcess

Similar to Nested Modules, you can supply `New-ModuleManifest -ScriptsToProcess @('script1','script2')`, and PowerShell will effectively dot-source all of these just prior to importing the module. This has advantages over nestedModules because all the scripts get processed on the session scope, making them inherently available in the module scope, but its not clean either:

- Scripts to Process also breaks scope, but the other way, they will be too available
- You can add everything via ScriptsToProcess, but once you import your module, all the _special snowflakes_ will be available in your session, forever, until you close it. It may cause problems with re-loading modules
- This is actually the best way to handle Domain-Specific languages though, like if you _want_ to use a special custom class with a custom hashtable constructor, this works really well.


### A note on DSC Resources

Just some special notes on previous testing (Circa 2018) external files with DSC Resource modules. DSC modules seem to change just about everything above

- If DSC Resources are involved, scripts to process and Nested Modules don't load in time (Maybe at all, its hard to know)
- This means:
  - Since we know from testing that nested modules don't load correctly for DSC, everything needs to be loaded together in the root module file
  - You need to ensure you get everything in the root module in the right order, I suggest ENUMS, CLASSES first then the rest
  - This suggests that custom validator classes and DSC resources should not exist in the same module

### So whats the best approach? Testing notes

- Keep your DSC resources in separate modules
- Validators always get imported as nested modules
- Put enums and classes at the top of the PSM1 root module
- If you _really really_ want to make them available outside the module, load them in _scriptstoprocess_ instead
- Probably avoid custom validators if your also exporting _scriptstoprocess_. I don't know how that would go
