---
layout: default
title: Required Modules vs External Module Dependencies
parent: Concepts
nav_order: 6
---
# Required Modules vs External Module Dependencies

The module manifest supports two ways to declare dependencies: `RequiredModules` and `ExternalModuleDependencies`. They behave quite differently, and choosing between them depends on what you need from the dependency relationship.

## Quick Comparison

| | `RequiredModules` | `ExternalModuleDependencies` |
| --- | --- | --- |
| Auto-installs on `Install-PSResource` | ✅ Yes | ❌ No |
| Blocks publish if dependency missing from feed | ✅ Yes | ❌ No |
| Requires dependency to be in the same repository | ✅ Yes | ❌ No |
| Flexible about how the dependency was installed | ❌ No | ✅ Yes |
| Avoids republishing third-party modules to private feeds | ❌ No | ✅ Yes |

## RequiredModules

`RequiredModules` creates a hard dependency. When publishing, the repository (e.g. PSGallery) checks that all listed modules are already present — if they're not, the publish will fail. On the user side, `Install-PSResource` or `Install-Module` will automatically pull in the dependencies.

This is useful when you need to pin to a specific version of a module and you can be confident that dependency will remain available in the target repository. In practice it can be too rigid — any module you list must exist in every repository you publish to, which becomes a problem with private feeds.

## ExternalModuleDependencies

`ExternalModuleDependencies` declares a dependency without enforcing it at publish time. The module will publish regardless of whether the dependency exists in the feed, and installation does not pull it in automatically. The responsibility for installing the dependency falls on the consumer.

This is the more flexible approach for most real-world scenarios — it avoids republishing third-party modules to private repositories, keeps feed trust boundaries clean, and removes any license concerns around redistributing other authors' packages.

To make the dependency clear to consumers, it is good practice to add an explicit check in the `begin` block of any function that requires it:

```powershell
begin {
    $requiredModules = @(
        'Microsoft.Graph.Authentication'
        'Microsoft.Graph.Beta.DeviceManagement'
        'Microsoft.Graph.Users'
    )
    $requiredModules.foreach{
        if (-not (get-module $_ -listavailable)) {
            throw "Module '$_' not found. Please install it before using this module."
        }
        write-verbose "Found module: $_"
    }
}
```

If many functions share the same dependency check, a private helper function keeps things tidy:

```powershell
function Test-ModuleDependency {
    param(
        [string[]]$Modules
    )
    $Modules.foreach{
        if (-not (get-module $_ -listavailable)) {
            throw "Module '$_' not found. Please install it before using this module."
        }
        write-verbose "Found module: $_"
    }
}
```

Call it from the `begin` block of any function that has an external dependency. This makes the error clear to the consumer without dictating how or from where the dependency was installed.

## Which Should I Use?

For most PowerShell modules — particularly those that depend on large third-party packages like the Microsoft Graph SDK — `ExternalModuleDependencies` is the better fit. Use `RequiredModules` when you are pinning a specific version of a small, stable dependency that you know is already present in every feed you publish to.

Both parameters are available on `New-MFProject` when scaffolding a new module, so dependencies can be declared from the start.

## A Note on Official Documentation Intent

The Microsoft documentation suggests a dual-listing approach: list all dependencies (internal and external) in `RequiredModules`, then also list the external ones in `ExternalModuleDependencies` to signal they are not bundled in the package. In practice this is uncommon and reintroduces the publish-time enforcement problem for external dependencies. The guidance on this page reflects real-world usage rather than a strict reading of the spec.

For more background, the [OneGet GitHub issue #164](https://github.com/OneGet/oneget/issues/164) has a useful discussion on how this distinction evolved.

## Further Reading

- [New-ModuleManifest — Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/new-modulemanifest) — official parameter reference for both `RequiredModules` and `ExternalModuleDependencies`

