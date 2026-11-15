---
layout: default
title: Using Private Package Feeds
parent: Tutorials
nav_order: 4
---
# Using Private Package Feeds

ModuleForge's Build and Release publishes your module to a private package feed: GitHub Packages on GitHub, or an Azure Artifacts feed on Azure DevOps. This page covers installing from that feed, on your own machine and in CI, and the quirks you will meet along the way.

You only need to register a feed once per machine. After that, it works like PSGallery, with a credential.

---

## The feed address and token

| | GitHub Packages | Azure Artifacts |
| --- | --- | --- |
| **Feed address** | `https://nuget.pkg.github.com/<owner>/index.json` | Project feed: `https://pkgs.dev.azure.com/<org>/<project>/_packaging/<feed>/nuget/v3/index.json`<br>Organization feed: `https://pkgs.dev.azure.com/<org>/_packaging/<feed>/nuget/v3/index.json` |
| **Scope** | One feed per user or organization, shared by all its repositories | One feed per name, in a project or the organization |
| **Token** | A **classic** personal access token with only `read:packages` | A personal access token with **Packaging: Read** |
| **Username** | Your GitHub username | Anything; your Azure DevOps email is conventional |

> **GitHub only accepts classic tokens for its NuGet feed.** Fine-grained tokens are rejected, even for public packages. A classic token can't be limited to one package or repository: `read:packages` can read every package your account can see. It is read-only, so set an expiry and keep it to that one scope.

If your Azure DevOps organization uses the older `https://<org>.visualstudio.com` address, its feeds are at `https://<org>.pkgs.visualstudio.com/...` instead.

---

## Register the feed

### With a credential each time

Registering a feed doesn't store a credential. You pass it to each `Find-PSResource` or `Install-PSResource` call instead:

```powershell
Register-PSResourceRepository -Name 'MyPackages' -Uri 'https://nuget.pkg.github.com/<owner>/index.json' -Trusted

# Username, and the token as the password
$credential = Get-Credential

Find-PSResource -Name 'MyModule' -Repository 'MyPackages' -Prerelease -Credential $credential
Install-PSResource -Name 'MyModule' -Repository 'MyPackages' -Prerelease -Credential $credential
```

> `Register-PSResourceRepository` has no `-Credential` parameter. To keep the credential with the registration, use a secret vault, below.

### With a secret vault (recommended)

With [Microsoft.PowerShell.SecretManagement](https://learn.microsoft.com/powershell/utility-modules/secretmanagement/overview), PSResourceGet reads the credential from your vault whenever it needs it, so you never pass it again.

1. Store the credential as a secret: the username, with the token as the password.
2. Register the feed with a pointer to that secret:

```powershell
# The PSCredentialInfo type comes from PSResourceGet, and isn't available until the module is imported.
# Without this, you get "Unable to find type [Microsoft.PowerShell.PSResourceGet.UtilClasses.PSCredentialInfo]"
Import-Module Microsoft.PowerShell.PSResourceGet

$credentialInfo = [Microsoft.PowerShell.PSResourceGet.UtilClasses.PSCredentialInfo]::new('VaultName', 'SecretName')
Register-PSResourceRepository -Name 'MyPackages' -Uri 'https://nuget.pkg.github.com/<owner>/index.json' -Trusted -CredentialInfo $credentialInfo

# No -Credential needed from here on
Install-PSResource -Name 'MyModule' -Repository 'MyPackages' -Prerelease
```

---

## Quirks

- **No wildcard searches.** NuGet v3 feeds can't list or search, so `Find-PSResource -Name 'My*'`, or a `Find-PSResource` without `-Name`, returns nothing. Use the exact module name.
- **Prereleases are hidden unless you ask.** Add `-Prerelease` to see and install them. Most of your early builds are prereleases.
- **Updating a prerelease can skip the install.** If `Install-PSResource` reports the module as already installed, add `-Reinstall`. See [the FAQ](../faq.md).
- **A new version can take a moment to appear.** Feeds index a newly published package shortly after the push. If a version your pipeline just published isn't found, wait and try again.
- **Lowercase install folders on Linux and macOS.** GitHub Packages lowercases package names, so `MyModule` can install into a folder named `mymodule`. Windows doesn't mind, but on a case-sensitive file system `Import-Module MyModule` then fails. ModuleForge has `Resolve-MFModuleCase` for this; run it after installing:

```powershell
Resolve-MFModuleCase -ModuleName 'MyModule'
```

The scaffolded workflows do the same thing for you where they install from a feed.

---

## In CI

The scaffolded pipelines already read your feed. These notes are for when you add your own steps, or read another repository's packages.

| | GitHub Actions | Azure DevOps |
| --- | --- | --- |
| **This repository's feed** | The built-in `GITHUB_TOKEN`, with `packages: read` permission on the job | The built-in `System.AccessToken`, mapped into the step's environment |
| **Another repository's package** | The package must grant the reading repository access: on the package, **Package settings → Manage Actions access**, add the repository with the **Read** role | The project's build service needs a role on the feed |
| **Organization-scoped feed** | Not applicable | Add the build service, usually `<Project> Build Service (<Org>)`, to the feed's **Permissions** with **Feed Reader**, or **Feed Publisher (Contributor)** to publish. Organization feeds often don't include it by default |

Any other private feed, such as Artifactory or a self-hosted NuGet server, has to be registered on the runner, with its credentials, before anything installs from it. See [Build Dependencies](../Concepts/BuildDependencies.md).

---

## Related

- [Publishing your module to PSGallery](./github/psGallery-Release-Workflow.md): once it's ready to be public
- [Testing the Published Module](./build-test.md): an automatic check of what you published
- [`Resolve-MFModuleCase`](../functions/Resolve-MFModuleCase.md)
