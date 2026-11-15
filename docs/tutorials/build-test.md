---
layout: default
title: Testing the Published Module
parent: Tutorials
nav_order: 5
---
# Testing the Published Module (Build Test)

Your Pester tests load your functions straight from `source/`. That is the right way to unit test, but it can't see what the build changes: the manifest's export lists, the compiled `.psm1`, and how the package installs. A function can pass every unit test and still be missing from the published module.

**Build Test** closes that gap. After Build and Release succeeds, it installs the version that was just published, from your own package feed, and runs the tests in the `buildTest` folder against it. It is optional, and off until you enable it.

---

## What it checks

The scaffolds add `buildTest/Module.Build.Tests.ps1`. Against the installed module, it checks:

- the module imports, and is the version its manifest says,
- every function in `source/functions` is exported, and no others,
- every alias declared in `source/functions` is exported, and no others. That means `[Alias()]` on a function, or `Set-Alias` / `New-Alias` with a literal name at the top of a file.

It works out what *should* be exported by reading your source itself, not by asking ModuleForge. So if a ModuleForge build ever drops something, this test notices. That is not hypothetical: an early 1.4 prerelease stopped exporting aliases made with `Set-Alias`, and this check is what catches it.

It understands a `DefaultCommandPrefix`, so `Get-Thing` is expected as `Get-<Prefix>Thing`.

---

## Enable it

### GitHub

1. Rename `.github/workflows/buildTest.yml.example` to `buildTest.yml`.
2. Commit it to `main`.

That's all. It runs after every successful **Build and Release**, and reads your repository's own GitHub Packages feed with the built-in token, so it needs no secrets.

If you renamed your Build and Release workflow, change the `workflows:` entry near the top of `buildTest.yml` to match.

### Azure DevOps

1. Rename `.azuredevops/pipelines/buildTest.yml.example` to `buildTest.yml`, and commit it to `main`.
2. Create a pipeline for it, as you did for the others.
3. Make sure your Build and Release pipeline is named exactly **Build and Release**. Build Test finds it by name, in its `resources` section. If yours has another name or is in a folder, rename it, or change `source:` in `buildTest.yml` to match, including the folder, such as `'\MyModule\Build and Release'`.
4. If your feed isn't named `psPackages`, change the `feed_name` default in `buildTest.yml`.

It then runs after every successful Build and Release. It needs no branch policy, as it tests what was published, not a pull request.

---

## Add your own tests

Every `*.Tests.ps1` in `buildTest/` runs. Add files beside `Module.Build.Tests.ps1` that use your module the way a user would: import it by name and call its commands. Don't dot-source anything from `source/`, as the point is to test what was installed.

```powershell
# buildTest/MyModule.Build.Tests.ps1
BeforeAll {
    Import-Module MyModule -Force
}

Describe 'Published MyModule' {
    It 'Get-Greeting works once installed' {
        Get-Greeting -Name 'World' | Should -Be 'Hello, World!'
    }
    It 'reads its bundled resource file' {
        Get-WelcomeMessage | Should -Not -BeNullOrEmpty
    }
}
```

Good candidates are the things unit tests can't reach: resource files read through `$PSScriptRoot`, classes and enums used through your commands, validation attributes, and aliases.

If a `.mfignore` file leaves some of `source/functions` out of the build on purpose, `Module.Build.Tests.ps1` reports those functions as missing, because it reads them from the source. Edit its `BeforeDiscovery` block to leave those files out.

---

## Run it locally

Build the module, put the build folder first on `PSModulePath`, and run the folder:

```powershell
Build-MFProject -Version 0.0.1
$env:PSModulePath = "$(Resolve-Path ./build)$([IO.Path]::PathSeparator)$env:PSModulePath"
Invoke-Pester ./buildTest
```

---

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| **GitHub:** Build Test never runs | The file is still `.example`, or the `workflows:` entry doesn't match your Build and Release workflow's name |
| **Azure DevOps:** the Build Test pipeline shows *Configuring the trigger failed, edit and save the pipeline again* | Usually the Build and Release pipeline name didn't match `source:` when the trigger was set up. Check the name, then open the Build Test pipeline, choose **Edit**, and **Save** |
| **Azure DevOps:** *No feed named 'psPackages'* | The feed has another name, or the build service can't see it. Set `feed_name`, and give `<Project> Build Service` the **Feed Reader** role on the feed |
| A test file fails to load and the run fails, with no failed tests | A `BeforeAll` or discovery error. Build Test fails on these deliberately, rather than reporting a pass |
| Functions reported missing that you excluded on purpose | See the `.mfignore` note above |

---

## Related

- [How ModuleForge Tests Itself](../Concepts/IntegrationTesting.md): the same idea, taken further
- [Using Private Package Feeds](./private-package-feeds.md)
- [Writing Pester Tests](../Concepts/Pester.md)
