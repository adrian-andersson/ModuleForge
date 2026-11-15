---
layout: default
title: Build Dependencies and Version Pinning
parent: Concepts
nav_order: 7
---

# Build Dependencies and Version Pinning

Your pipelines install modules before they do anything: Pester to test, PSScriptAnalyzer to lint, ModuleForge to build, PlatyPS for docs. Installing "whatever is newest" means a release of any of them can change your build without you changing anything. `BuildDependencies.psd1` pins them, so builds and tests use versions you chose.

---

## Built on what PSResourceGet already does

ModuleForge doesn't invent a dependency format. `BuildDependencies.psd1` is a [RequiredResourceFile](https://learn.microsoft.com/powershell/module/microsoft.powershell.psresourceget/install-psresource), the format `Install-PSResource -RequiredResourceFile` reads natively. Version ranges, prerelease handling, repositories and the install itself are all PSResourceGet's. ModuleForge adds a small script around it, `scripts/Install-MFBuildDependencies.ps1`, for the things CI needs: choosing a source, installing only part of the file, and reporting exactly what was installed.

```powershell
@{
    'ModuleForge' = @{
        version = '[1.4.0, 2.0.0)'
        repository = 'PSGallery'
    }
    'Pester' = @{
        version = '[6.0.0, 7.0.0)'
        repository = 'PSGallery'
    }
    'PSScriptAnalyzer' = @{
        version = '[1.25.0, 2.0.0)'
        repository = 'PSGallery'
    }
    'Microsoft.PowerShell.PlatyPS' = @{
        version = '[1.0.3, 2.0.0)'
        repository = 'PSGallery'
    }
}
```

Versions use NuGet range syntax:

| Range | Means |
| --- | --- |
| `'1.2.3'` | Exactly 1.2.3 |
| `'[1.2.3, ]'` | 1.2.3 or newer |
| `'[1.2.3, 2.0.0)'` | 1.2.3 or newer, but not 2.0.0 |

Add `prerelease = 'true'` to an entry to allow its prerelease versions. Add your own module's dependencies too, such as anything in `RequiredModules`, so your tests can import them.

PSResourceGet itself isn't in the file, as it does the installing. PowerShell 7.4 and newer include it, and the script installs it only if it's missing or older than 1.0.

---

## Where it is used

| Pipeline | Installs | Choice |
| --- | --- | --- |
| **Pester tests** | What `testDependencies` asks for (below). Never ModuleForge, as tests load from source | `testDependencies` in `moduleForgeConfig.xml` |
| **Lint** and **Project Rules** | PSScriptAnalyzer | Pinned |
| **Build and Release** | ModuleForge | `dependency_source` input |
| **PSGallery Release** | ModuleForge | `dependency_source` input |
| **Docs update** | ModuleForge and PlatyPS | Pinned |
| **Build Test** | Pester | Pinned |

Each pipeline then imports exactly the version it resolved, so a newer copy elsewhere on a runner can't take its place. The pull request comments say where each module came from: pinned, the latest from PSGallery and why, or the runner's own.

### `dependency_source`

Build and Release, and PSGallery Release, take a `dependency_source` input:

| Value | Installs |
| --- | --- |
| `required-resource-file` *(default)* | The version pinned in `BuildDependencies.psd1` |
| `psgallery-latest` | The latest stable version from PSGallery |
| `psgallery-prerelease` | The latest version from PSGallery, prereleases included. Useful for trying a ModuleForge prerelease before you pin it |

### `testDependencies`

Set in `moduleForgeConfig.xml` with `New-MFProject -TestDependencies` or `Update-MFProject -TestDependencies`:

| Value | Pester workflows install |
| --- | --- |
| `None` | Nothing. Tests use the modules the runner already has |
| `PesterAndScriptAnalyzer` *(default)* | Pester and PSScriptAnalyzer |
| `All` | Everything in `BuildDependencies.psd1` except ModuleForge. Mock what you can rather than relying on this |

---

## How the ModuleForge pin is set

`Add-MFProjectScripts`, which the scaffolds and `New-MFProject` run, writes `BuildDependencies.psd1` if it's missing. It pins ModuleForge to the version running it, up to the next major version: running 1.4.0 writes `[1.4.0, 2.0.0)`. The templates it adds are written for that version, so the pipelines and the ModuleForge that runs them stay matched.

To move to a newer ModuleForge, change the pin. Re-running a scaffold with `-Force` also rewrites the file, which **resets any pins you changed**.

---

## Private feeds and other repositories

Each entry can name a `repository`. That name must be a PSResource repository **already registered on the runner**, with whatever credentials it needs, before the install step runs. If it isn't, the install fails.

ModuleForge deliberately doesn't register feeds or manage their credentials for you. Every private feed, whether Artifactory, a self-hosted NuGet server, an Azure Artifacts feed or another organization's GitHub Packages, has its own address, authentication and permissions, and those belong to you and your platform. In practice that means:

- **Register the feed** in a step before the install, with `Register-PSResourceRepository`.
- **Give the pipeline access**: a secret mapped into that step, or for a feed on the same platform, a grant to the pipeline's identity. See [Using Private Package Feeds](../tutorials/private-package-feeds.md).
- **Check it works** with a manual run before relying on it.

If the file is missing, or doesn't list a module a pipeline needs, that module comes from PSGallery with a warning, so a project still builds without the file.

---

## Related

- [`Add-MFProjectScripts`](../functions/Add-MFProjectScripts.md)
- [Using Private Package Feeds](../tutorials/private-package-feeds.md)
- [Required Modules vs External Module Dependencies](./RequiredModules_vs_ExternalModuleDependencies.md)
