---
layout: default
title: How ModuleForge Tests Itself
parent: Concepts
nav_order: 11
---

# How ModuleForge Tests Itself

ModuleForge has a large Pester suite, and [builds and releases itself](./SelfBuild.md). Neither proves the thing that matters most: that a module **built with** a new ModuleForge works once it's published and installed, on each platform ModuleForge supports.

So every ModuleForge build is also tested from the outside, by separate repositories that use ModuleForge the way you do: they scaffold with it, build with it, publish with it, install the result from a real package feed, and test what they installed. This runs automatically for every ModuleForge build.

It earns its keep. During 1.4, a prerelease stopped exporting aliases made with `Set-Alias`. Every ModuleForge unit test passed. A test repository's Build Test caught it, because it was the first thing to install a module built by that prerelease and try to call the alias.

---

## The test repositories

Each one builds the same example module, AstroCmdlets from the [advanced tutorial](../tutorials/github/github-tutorial-02-full-ModuleForge-Featureset.md), so it uses classes, an enum, a validation class, a private function, a resource file and an alias. Each has its own module name, so their packages never collide in a shared feed.

| Repository | Platform | Gets ModuleForge from | Proves |
| --- | --- | --- | --- |
| [ModuleForge.Test.Public](https://github.com/adrian-andersson/ModuleForge.Test.Public) | GitHub Actions | **PSGallery** | The version users install works, through the same path they use |
| ModuleForge.Test.Private | GitHub Actions | **GitHub Packages**, the newest prerelease | A prerelease works, before it's published anywhere public |
| ModuleForge.AZDTest.Private | Azure DevOps | **GitHub Packages**, the newest prerelease | The Azure DevOps scaffold and pipelines work, end to end |

**Why two are private.** They install ModuleForge prereleases from ModuleForge's GitHub Packages feed, which needs credentials, and they publish a stream of throwaway test versions of their own. Keeping them private keeps those tokens, feeds and test packages out of public view, where they would only confuse people. Test.Public deliberately stays public: it's the worked example you can read and copy.

Each repository's pipelines start from the ModuleForge scaffold, changed only where they need to point at the ModuleForge under test. That way the scaffold itself is tested too.

---

## How it flows

```mermaid
flowchart TD
    A["ModuleForge pull request"] --> B["Pester, lint and Project Rules"]
    B --> C["Merge to main"]
    C --> D["ModuleForge Build and Release (prerelease)"]
    D --> E[("GitHub Packages")]
    D -->|"starts, with the exact version"| F["Test.Private: Build and Release"]
    D -->|"starts, with the exact version"| G["AZDTest.Private: Build and Release (Azure DevOps)"]
    F --> F2["Test.Private: Build Test"]
    G --> G2["AZDTest.Private: Build Test"]
    F2 --> H{"Review the results"}
    G2 --> H
    H -->|"Run PSGallery Release by hand"| I[("PSGallery")]
    I -->|"starts, with the exact version"| J["Test.Public: Build and Release"]
    J --> K["Test.Public: Build Test"]
```

There are two stages, with a deliberate gap between them.

1. **Every build, automatically.** When ModuleForge's Build and Release publishes a version, usually a prerelease, it starts Build and Release in Test.Private and AZDTest.Private, passing the exact version it just published. Each builds its module with that version, publishes it to its own feed, and runs [Build Test](../tutorials/build-test.md) against the installed result.
2. **Every PSGallery release, by hand.** Publishing to PSGallery is a decision, not a side effect: several prereleases can build up before one is promoted, and a PSGallery version can never be deleted, only unlisted. Once it's published, PSGallery Release starts Test.Public, which installs that exact version from PSGallery and runs its Build Test. If that fails, the version is unlisted by hand.

A few principles hold throughout:

- **The exact version is passed at every step.** Each test repository builds with the version that was just published, never "whatever is newest", so a result always belongs to a specific build.
- **Starting a test never fails a release.** If a test repository can't be started, the release that triggered it still succeeds, with a warning. The release has already happened, and a broken trigger shouldn't hide that.
- **Each trigger has its own narrowly scoped token.** One that can start Test.Private's pipeline can't touch the others, or push code.

---

## What it covers

Together with ModuleForge's own unit tests, this proves for each build:

- projects scaffolded by it have working pipelines, on GitHub and on Azure DevOps,
- it builds a module that installs from GitHub Packages, Azure Artifacts and PSGallery,
- the installed module exports exactly what its source declares, including aliases,
- classes, enums, validation attributes, private functions and resource files all work once installed,
- the build, publish, tag and test steps work when triggered by another pipeline, not just by hand.

---

## Replicating it for your own modules

You probably don't need all of this. For most modules, [Build Test](../tutorials/build-test.md) on its own gives the most important part: checking the module you published, not just your source.

It becomes worth more when other things depend on your module, such as a shared library several teams build on, or when it needs to work on more than one platform. The idea carries over, even if the details don't:

1. **Test what you published, not what you built.** Install from the real feed, by name, in a clean job, and test that.
2. **Add a consumer.** A separate repository that uses your module the way its users do, and has its own tests. It catches what your own tests are too close to see.
3. **Pass the exact version along.** Have your release start the consumer's pipeline, with the version it just published, so every result is tied to one build.
4. **Give each trigger the smallest token that works,** and never let a failed trigger fail the release that started it.
5. **Keep promotion manual.** Automate the testing, and decide yourself when something goes public.

The mechanisms ModuleForge uses for the triggers are standard: a GitHub `repository_dispatch` or `workflow_dispatch` event between GitHub repositories, and the Azure DevOps [Runs API](https://learn.microsoft.com/rest/api/azure/devops/pipelines/runs/run-pipeline) from GitHub to Azure DevOps. ModuleForge's own `buildandrelease.yml` and `psgalleryRelease_NoModuleForge.yml` workflows show them in use.

---

## Related

- [ModuleForge Builds Itself](./SelfBuild.md)
- [Testing the Published Module (Build Test)](../tutorials/build-test.md)
- [CI Security Model](./CISecurityModel.md)
