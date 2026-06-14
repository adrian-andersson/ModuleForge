---
layout: default
title: Publishing your private modules to PSGallery
parent: Github
grand_parent: Tutorials
nav_order: 3
---
# Publishing your private modules to PSGallery

The `psgalleryRelease.yml` workflow publishes a tagged release from your GitHub Packages feed directly to [PSGallery](https://www.powershellgallery.com/). It is included in the ModuleForge GitHub scaffold and is triggered manually - you choose which release to publish and when.

> **PSGallery is permanent.** Once a version is published it cannot be deleted, only unlisted. Publish intentionally.

---

## Step 1 - Get the workflow file

The `psgalleryRelease.yml` file is bundled with ModuleForge's GitHub scaffold. If you have already run `Add-MFGithubScaffold`, run it again without `-Force` to pick up any new workflow files while leaving your existing customised workflows untouched:

```powershell
Add-MFGithubScaffold
```

Files that already exist in your `.github/` folder are skipped. Only missing files - including `psgalleryRelease.yml` if it wasn't there before - are copied.

Commit the new file to `main` before continuing:

```text
chore: add PSGallery release workflow
```

---

## Step 2 - Add a PSGallery API key secret

The workflow reads your PSGallery API key from a repository secret named `PSGALLERY`.

**To get your API key:**

1. Log in at [powershellgallery.com](https://www.powershellgallery.com/)
2. Go to your account settings - the **API Keys** section is on the right side of the page
3. Create a key scoped to **Push new packages and package versions** for your module (or all packages)

**To add it to your repository:**

1. Go to your repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `PSGALLERY`
4. Value: your API key
5. Save

---

## Step 3 - Run the workflow

Navigate to **Actions → PSGallery Release → Run workflow**.

### Inputs

#### `release_selector` (required)

Controls which tagged release is published. The workflow fetches your full release list and filters it accordingly.

| Option | What it selects |
| --- | --- |
| `latest-release` *(default)* | The most recently created release, regardless of stable or prerelease status |
| `latest-stable` | The most recent release that is **not** marked as a prerelease |
| `latest-prerelease` | The most recent release that **is** marked as a prerelease |

> If you publish a prerelease version to PSGallery, it will appear there as a prerelease - hidden from `Find-PSResource` / `Find-Module` unless `-AllowPrerelease` is passed. Use `latest-stable` unless you specifically intend to publish a prerelease to PSGallery.

#### `moduleforge_release_toggle` (optional)

Controls which version of ModuleForge is used internally by the workflow itself. Leave this at the default (`moduleforge-latest-stable-only`) unless you are testing a ModuleForge prerelease build.

---

## What the workflow does

1. **Reads the release list** - uses the `gh` CLI to list releases and selects one based on your `release_selector` choice
2. **Installs ModuleForge and PSResourceGet**
3. **Registers your GitHub Packages feed** as a PSResource repository using the built-in `GITHUB_TOKEN`
4. **Finds the specific version** in GitHub Packages by matching the release tag
5. **Installs the module** from GitHub Packages locally on the runner
6. **Resolves module case** - calls `Resolve-MFModuleCase` to handle NuGet's case-insensitive install behaviour, ensuring the module folder name matches the manifest exactly for PSGallery compatibility
7. **Checks for duplicates** - queries PSGallery to confirm the version does not already exist; throws if it does, preventing accidental republishing
8. **Publishes to PSGallery** using `Publish-PSResource` with your `PSGALLERY` API key

---

## Troubleshooting

**"No matching release found"** - No release exists that matches the selector. Check that at least one release has been created via the Build and Release workflow.

**"Version X already exists on PSGallery"** - The version tag you selected has already been published. You cannot republish the same version. Increment the version with a new Build and Release run before publishing again.

**"Module not found after install"** - The case resolution step failed. Check that `moduleForgeConfig.xml` is present and `moduleName` matches the module's manifest name exactly.

**Workflow passes but module doesn't appear on PSGallery** - PSGallery indexing can take several minutes. Wait a few minutes and search again. If the module is a prerelease, use `Find-PSResource -Name YourModule -AllowPrerelease` to find it.

---

## Verifying without publishing

To do a dry run - install and inspect the module without pushing to PSGallery - comment out the `Publish-PSResource` call in `psgalleryRelease.yml` temporarily and inspect the verbose output from the install step. Revert the comment before merging.
