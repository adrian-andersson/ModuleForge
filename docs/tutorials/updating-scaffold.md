---
layout: default
title: Updating Your Workflows and Templates
parent: Tutorials
nav_order: 6
---
# Updating Your Workflows and Templates

New ModuleForge versions often improve the workflows, pipelines and pull request template it scaffolded into your project. Your project keeps the old copies until you update them. This page shows how to update them safely, without losing changes you made yourself.

**The short version:** update ModuleForge, make a branch, run the scaffold again with `-Force`, put back anything of yours it overwrote, and open a pull request.

> **This is a temporary process.** A future version of ModuleForge will tell you which files are out of date, update the ones you haven't changed, and only ask you to review the ones you have. Until then, this page is the safe way to do it by hand.

> **Why copy the workflows into your project at all?** GitHub can share workflows between repositories, which would avoid updating them like this. ModuleForge doesn't use that, so it works the same way on GitHub and Azure DevOps, and on any other platform it might support in future.

---

## Before you start

- **Your working tree is clean.** Commit or stash anything in progress, so the only changes on the branch are the update.
- **You're on an up-to-date main branch.** Run `git switch main` then `git pull`.
- **Expect to spend about 15 minutes**, most of it reviewing the changes.

---

## 1. Update ModuleForge

```powershell
Update-PSResource -Name ModuleForge
```

If you installed it with `Install-Module`, use `Update-Module -Name ModuleForge` instead. Then start a new PowerShell session, so the new version is the one that runs, and check it:

```powershell
Import-Module ModuleForge
(Get-Module ModuleForge).Version
```

## 2. Create a branch

```powershell
git switch -c chore/update-scaffold
```

## 3. Run the scaffold again

Run the line for your platform, from your project's root folder:

```powershell
# GitHub
Add-MFGithubScaffold -Force

# Azure DevOps
Add-MFAzureDevOpsScaffold -Force
```

Then the scripts the workflows call, and, if you use Project Rules, the rules:

```powershell
Add-MFProjectScripts -Force

# Only if your project has a PSScriptAnalyzer folder
Add-MFProjectRules -Force
```

Each command prints a warning for every file it overwrites. That list is a good guide to what to review next.

> `Add-MFProjectScripts -Force` also replaces `BuildDependencies.psd1`, pinning ModuleForge to the version you just installed. That is usually what you want, so CI runs the same ModuleForge as your new workflows. If you pinned anything else in that file, you'll put it back in step 4.

## 4. Review the changes

> **Never changed these files?** Then everything that changed is ModuleForge's own update, and this step is a quick skim. Changing a version pin in `BuildDependencies.psd1` counts as a change, and if you enabled any optional workflows, still do step 5.

See what changed:

```powershell
git status
```

- **Modified** files are the ones that were updated.
- **Untracked** files are new, added by this ModuleForge version.

Open each modified file's diff, in your editor's source control view or with `git diff <file>`. Most of the changes will be ModuleForge's improvements, which you keep. **What you're looking for is lines you wrote that have been removed.** Common ones:

| File | Changes you may have made |
| --- | --- |
| Build and Release | Feed name, branch names, runner image, extra steps |
| Pester and lint workflows | Runner OS, the Pester or PSScriptAnalyzer settings |
| Pull request template | Your own sections or checklist items |
| `BuildDependencies.psd1` | Version pins other than ModuleForge |
| `buildTest/` tests | Checks you added for your published module |
| Project Rules files | Edits to the rule files or `projectRules.yml` |

Put each of yours back. In VS Code, select the lines in the diff and use **Revert Selected Ranges**, or just edit the file.

> If you made a lot of changes to a file, it can be easier to do the opposite: undo the update to that file with `git restore <file>`, then copy ModuleForge's improvements into your version by hand.

## 5. Check the workflows you enabled

The optional workflows ship as `.example` files, and you enable one by renaming it, such as `docsUpdate.yml.example` to `docsUpdate.yml`. **The scaffold never changes a file you've renamed.** Instead, it adds a fresh `.example` file next to it, which shows up as untracked in step 4.

For each one, compare the new example with your enabled file:

```powershell
git diff --no-index .github/workflows/docsUpdate.yml .github/workflows/docsUpdate.yml.example
```

If you want the changes, copy the example over your file and put your own changes back, as in step 4:

```powershell
Copy-Item .github/workflows/docsUpdate.yml.example .github/workflows/docsUpdate.yml -Force
```

Then delete the `.example` file, unless you want to keep it as a reference.

> `projectRules.yml` is the exception. `Add-MFProjectRules -Force` updates it directly, so it was covered in step 4.

## 6. Commit and open a pull request

```powershell
git add .
git commit -m "chore: update workflows and templates to ModuleForge <version>"
git push -u origin chore/update-scaffold
```

In the pull request:

- **Type of change:** Non-module change
- **Release:** No build yet. Nothing in the module itself has changed, so there's nothing to release

The checks on the pull request run with the updated Pester and lint workflows, so a passing pull request shows they work. Changes to the Build and Release form show up once the pull request is merged.

---

## When to do this

- **When a release says so.** Release notes say when a version changes the scaffold in a way you'll want, such as a new Build and Release form.
- **When something you've read about in the docs isn't in your project**, such as a new input or an optional workflow.
- **Not after every release.** The old workflows keep working with newer ModuleForge versions, as `BuildDependencies.psd1` pins the version they run.
