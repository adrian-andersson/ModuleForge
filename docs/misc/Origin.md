---
layout: default
title: From Bartender to ModuleForge
parent: Concepts
nav_order: 7
---

# From Bartender to ModuleForge

ModuleForge did not start as a new idea. It started as the second attempt at solving a problem I had alreadysolved once before, but needed resolving as PowerShell switched to Pwsh, Nuget evolved, and Github got into the Package Repository game.

This page exists if anyone is interested in the origin story of ModuleForge and the technical challenges getting it operational.

---

## Bartender

Before ModuleForge there was **Bartender** -> a module build tool I wrote to package and publish Windows PowerShell modules to an internal Artifactory feed. The folder structure it used was the same one ModuleForge uses today. Backwards compatibility with Bartender's output was a deliberate design constraint when I started ModuleForge, because some of what Bartender built still exists, and I wanted to support easy transitioning.

The interesting work in Bartender's era was not the build tooling itself, it was what I was using it to build. DSC resources and a Domain-Specific Language model for configuration management. That is where I worked out how to handle classes, enums, custom validation attributes, and DSC resources in a way that was repeatable and consistent across a team. Most of those design patterns carried directly into ModuleForge. So did the lessons learnt:

- **DSC Resources cannot rely on `ScriptsToProcess`.** If you put class definitions in `ScriptsToProcess`, they load in a different scope than the module and DSC cannot find them. I learnt alot about AWS EC2 Instance Start-Up process as a result of all the testing.
- **Classes outside of DSC are genuinely useful, but PowerShell's implementation has real gaps.** Inheritance works, and it is worth using. But the scoping rules are surprising, the error messages are unhelpful, and anything that touches classes needs to be loaded in exactly the right order.
- **Enums are fantastic until you try to use them across module boundaries.** They simplify validation and self-document intent, but the same loading-order scoping issues that affect classes apply here. Once you know the rules they are manageable, but the rules are not obvious.
- **Not having automated prerelease builds is a real constraint.** Bartender had no prerelease versioning pipeline. The result was that "works in dev" and "works in prod" were the same claim, with no clean way to validate changes before they hit users.

Then Pester 4 became Pester 5, and Bartender's testing approach broke. It was the beginning of the end -> technical debt had been accumulating and this was the push that made it too expensive to catch up.

Shortly after, the company switched from Artifactory to GitHub Packages. Bartender's entire reason for existing was publishing to Artifactory. With that gone, and the debt too high to rewrite, Bartender was far less useful. It was constrained with the old DotNet versioning, it didn't work cross-platform, the testing didn't work as intended. It was the right tool for the time, it was no longer that time.

---

## The Gap

ModuleForge was not an immediate response to Bartender's legacy. PowerShell 7 _almost_ there, but not quite. PSResourceGet was still early. Rewriting everything on tooling that was itself still unstable would have produced problems. Work was started but never finished.

---

## Starting Again

In late 2023, I made a more concerted effort to get ModuleForge working. I had a clear set of goals shaped entirely by what Bartender had failed to do:

- **NuGet v3 compliant** -> Bartender produced packages that worked with Artifactory's NuGet v2 feed. It worked with PSGallery. GitHub Packages is NuGet v3. Getting the repository URI into the `.nupkg` metadata correctly is not obvious and is not handled by default PowerShell tooling.
- **GitHub Packages first-class** -> the whole point. It had to work, not approximately work.
- **Self-building** -> ModuleForge should use ModuleForge to build itself.
- **SemVer and prereleases, done properly** -> the thing Bartender never had. Build a prerelease and Semver support, install it from the feed, test it, promote it to stable. This decouples development from release in a way that matters.
- **Everything modern** -> PSResourceGet, Pester 5, PowerShell 7. No backwards compatibility with Windows PowerShell 5.1.
- **Cross-Platform compatibility** -> PowerShell was cross-platform, my tooling was going to be cross-platform as well!
- **Self-Versioning** -> It needed totrack and apply versions automatically, without a whole PR Cycle, outside of the source-code

The first version of ModuleForge changed how I wrote PowerShell. Targeting cross-platform from the start, even for code I knew would only run on Windows, produces cleaner code. You catch implicit Windows dependencies early. You stop using `$env:USERPROFILE` when `$HOME` works everywhere. You stop assuming backslash path separators. The discipline carries even when the final target is Windows-only.

---

## The Snowball

Around the same time I was building v1, I was working on CI/CD pipelines for other projects; A clean TerraForm pipline, React applications on GitHub. Good pipelines. The kind where a PR tells you, in the PR itself, exactly what broke and why, before anyone reviews it. Where commits are structured because the pipeline uses that structure to generate release notes. Where the changelog writes itself.

I wanted that for PowerShell, for ModuleForge. The whole DevOps CI/CD goal.

So ModuleForge grew: PR templates that surface the change type and release intent. Commit prefixes that feed directly into `Get-MFGitChangeLog`. Automated Pester results posted as PR comments. PSScriptAnalyzer lint reports in the same place. None of these were in the original plan, they accumulated because once you see what a well-instrumented pipeline looks like, it is hard to go back.

Documentation was always the gap I wanted to close properly. Bartender had experimented with PlatyPS, generating reference docs from comment-based help. The output was functional but disconnected from anything a reader would actually navigate. I wanted documentation that was generated from the module but lived alongside handwritten guides in a coherent site. `Write-MFModuleDocs` is that attempt. Github Docs makes it work

---

## Azure DevOps

Not long after ModuleForge was in a usable state, I moved to a role where GitHub was not available. So I ported the workflows from Github to Azure DevOps pipelines. They are very similar, but the underlying infrastructure is just different enough. The GitHub Actions workflows became Azure DevOps pipeline YAML. Feature parity was the goal -> same Pester gate, same PSScriptAnalyzer report, same Build and Release inputs. It mostly worked. In Azure DevOps there is a little bit more manual work to do to get Pipeline's to work, but it's a few minutes and a once-per-repository ordeal.

That porting process is also where I found the lowercase prerelease bug. PSResourceGet on Azure DevOps Artifacts behaves incorrectly when prerelease labels contain uppercase characters, the version resolves wrong, installs fail silently, or the wrong version gets installed. The default label in `Get-MFNextSemver` is `pre` (lowercase) specifically because of this. I originally wanted and had `PRE` so it looked cleaner next to the prerelease number. A bug that only surfaces in a specific feed implementation, with a fix that looks arbitrary unless you know why it is there.

## Things Nobody Warned Me About

A partial list of problems that were not in any documentation, tutorial, or website answer I could find at the time, and what eventually solved them.

### Getting the source repository URI into the `.nupkg`

PowerShell's publishing toolchain does not support embedding a repository URI in package metadata natively. This matters because NuGet v3 feeds use it for source linking and feed validation. The solution is unglamorous: publish to a local file-based PSResource repository first, locate the resulting `.nupkg`, rename it to `.zip`, extract it, find the `.nuspec` XML inside, manually inject the `<repository>` element with the correct URI, re-pack the archive, rename it back to `.nupkg`, and then push *that* to the real upstream feed using the NuGet CLI. `Add-MFRepositoryXmlData` and `Register-MFLocalPsResourceRepository` exist entirely because of this.

Hopefully one day this will be solved natively

### Load order for classes, enums, and validation attributes

PowerShell compiles special types at parse time rather than at runtime, which means the order source files are dot-sourced in matters in ways that function files do not. Enums that classes reference must already exist when the class is parsed. Validation attributes that parameters reference must exist when the function is defined. Getting this wrong produces errors that look nothing like a load-order problem, they look like type-not-found errors or missing-method exceptions deep in a call stack. The solution is a strict explicit order: enums first, then classes, then validation classes, then functions. ModuleForge enforces this in the build step so the developer never has to think about it.

There is also the problem with PowerShell not having a way to export these types to the Module scope, so you either need to manually export them (using dot-sourcing, or scripts-to-process in the manifest) to the Global scope (Persisting after the module is removed), or write wrapper functions to access them. I'm hoping in some distant future the Manifest and Module loading get an update to expose these things for approprate scope export.

### Getting validation classes to work in a module at all

Custom validation attributes (`[ValidateScript]` subclasses) have a particular scoping problem: they are resolved at parameter binding time, which happens in the caller's scope, not the module's scope. If the validation class is defined inside the module but not visible in the calling scope, either via `ScriptsToProcess` or by being compiled into the `.psm1` before any function that uses it, the binder cannot find it and the error message gives no indication why. This took some experimenting to figure out.

It's a little disappoiting that this is the result, because it is hard to recommend validation classes at all. But they are genuinely useful. For example, you could create a custom validator that took a password as imput, or alternatively a string, and if the input was a string, automatically connect to secrets-management and pull out the matching secret name. Things like that would have amazing value and utility

### The uppercase prerelease label bug ([PSResourceGet #1787](https://github.com/PowerShell/PSResourceGet/issues/1787))

Discussed already, prerelease labels containing uppercase characters cause PSResourceGet to behave incorrectly on Azure DevOps Artifacts, versions resolve wrong, installs quietly pull the wrong build, or the operation fails in a way that looks entirely unrelated to label casing. Mentioned earlier in this page, included here for completeness. The default `prev` label is lowercase for this reason alone.

### PSResourceGet requiring the module folder to match the module name exactly ([PSResourceGet #305](https://github.com/PowerShell/PSResourceGet/issues/305))

When PSResourceGet installs a module, the folder name on disk must match the module name in the manifest exactly, including case. NuGet is lower-case by convention, so a module named `MyModule` might be installed into a folder called `mymodule` on Linux, which PSResourceGet then cannot find with `Get-Module -ListAvailable`. `Resolve-MFModuleCase` exists to detect and correct this mismatch after install. It is called explicitly in the PSGallery release workflow for exactly this reason. This might be useful

### How DSC resources actually load, and why `ScriptsToProcess` breaks them

DSC resolves resource types in a separate runspace from the configuration. Anything in `ScriptsToProcess` loads in the module's runspace but is not visible to the DSC engine's runspace when it tries to instantiate the resource. The result is a resource that loads cleanly, passes all module validation, and then fails at configuration compile time with an error that says nothing useful about runspaces. The fix is to never rely on `ScriptsToProcess` for anything a DSC resource needs, classes and types must be compiled into the `.psm1` directly. Which means no fancy validators

Generally, it seems far easier to split DSC resource code into DSC specific modules, and not add any additional funcions to the module.

### Mocking the Git CLI in Pester

`git` is an external executable, not a PowerShell function, so `Mock` cannot intercept it directly. The approach that works is wrapping every `git` call in a thin internal helper function, aliased to `git`, then having the function return real git output based on the input variables.

### Building a dependency tree across functions and classes

`Get-MFDependencyTree` works by parsing the AST of each source file and extracting names of functions and types that are referenced but not defined locally. The tricky part is that PowerShell's AST does not give you a clean "this file calls these functions" list, you walk the tree, identify command expressions and type references, filter out built-ins and the file's own definitions, and cross-reference against the rest of the source folder. Getting this right for all the combinations of how classes, enums, and private functions can reference each other was significantly more involved than anticipated

### Building ModuleForge from an older version of itself

The bootstrapping problem. The CI pipeline uses ModuleForge to build ModuleForge. To do that it installs ModuleForge from PSGallery (or GitHub Packages) and uses that version to compile the current source. This means the version doing the building is always *behind* the source being built, which is fine for stable releases, but during active development on the build functions themselves, you are testing new behaviour with old code. The mental overhead of keeping track of which version is building what, and whether a failure is a bug in the *source* or a limitation of the *builder*, is a fun cognitive load exercise.

The Github workflows for ModuleForge have some slight variations to ensure consistent results, since the ModuleForge module itself cannot be depended on (Self-referencing issues) like in an external module.
