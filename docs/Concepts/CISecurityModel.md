---
layout: default
title: CI Security Model
parent: Concepts
nav_order: 13
---

# CI Security Model

A CI pipeline runs code from pull requests, and it holds tokens that can push code, publish packages and comment on pull requests. The scaffolded workflows and pipelines are built so those two things never meet: **a job that runs your code gets no token worth stealing, and a job that holds a useful token never runs your code.**

This page explains the pattern, so you can keep it when you change the templates.

---

## Pull requests: code and comments are separate jobs

Pester, the PSScriptAnalyzer lint and Project Rules all run code from the pull request: your functions, your tests, and for Project Rules, your custom rules. Each is split in two:

| Job | Runs pull request code | Access |
| --- | --- | --- |
| **Runs the tests or rules** | Yes | Read-only. On GitHub, `contents: read` and nothing else. On Azure DevOps, no access token in that step |
| **Posts the comment** | Never. It doesn't check out the repository | Only what commenting needs: `pull-requests: write` on GitHub. On Azure DevOps, a separate job on a separate agent |

The results pass from one job to the other as data. The comment job treats that data as untrusted, because pull request code wrote it: it reads it from environment variables, and never pastes it into script text, where it could run as code.

Jobs that only compare numbers, such as the code coverage check, get no token at all.

---

## Checkout keeps the token off disk

By default, a GitHub checkout leaves the job's token in the repository's git config, where anything the job runs afterwards can read it. The scaffolded workflows turn that off (`persist-credentials: false`).

Build and Release runs your repository's code too, as it builds the module. It only needs a token to push the version tag, so only that one step gets it, passed through its environment rather than on a command line, and masked in the log. Azure DevOps does the same with `persistCredentials: false`, giving the access token only to the tag step.

---

## What gets published

- **No credentials in the manifest.** The project URI usually comes from your git remote, which can contain a token. ModuleForge strips any user name, password or token from it before it goes into the manifest, and warns when it removes a password or token, as one was stored somewhere it shouldn't be.
- **Checksums for every release.** Releases list SHA256 hashes of the built `.psd1` and `.psm1`, and the manifest records which ModuleForge build produced it. See [Release Integrity and Checksums](./ReleaseIntegrity.md).
- **Explicit exports.** Manifests list exported functions and aliases by name, never `*`, so a module exports only what you wrote as public.

---

## Tokens you add

Some optional workflows need a token: publishing to PSGallery, a docs workflow that opens pull requests, or triggering another repository's pipeline. For each one:

- **Give it the narrowest scope that works,** limited to one repository where the platform allows it. A fine-grained GitHub token for "Actions: read and write on one repository" is much safer than a classic token with `repo`.
- **Map it only into the step that uses it,** not the whole job.
- **Set an expiry,** and let the step fail clearly, or warn, when it lapses.
- **Treat custom rule folders and workflow files as sensitive.** A change to them changes what runs in CI. Consider `CODEOWNERS` for `.github/`, `.azuredevops/` and `PSScriptAnalyzer/`.

---

## Worth adding yourself

The templates don't use GitHub [Environments](https://docs.github.com/actions/deployment/targeting-different-environments/using-environments-for-deployment) yet. For the PSGallery release workflow in particular, an environment lets you restrict releases to `main`, require a reviewer, and keep the PSGallery API key in a secret only that environment can read. A PSGallery publish can't be undone, so it's the strongest case for one.

---

## Related

- [Release Integrity and Checksums](./ReleaseIntegrity.md)
- [Project Rules](./ProjectRules.md)
- [How ModuleForge Tests Itself](./IntegrationTesting.md)
