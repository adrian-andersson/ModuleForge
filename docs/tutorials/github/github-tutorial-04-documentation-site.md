---
layout: default
title: Publishing a Documentation Site with GitHub Pages
parent: Github
grand_parent: Tutorials
nav_order: 4
---
# Publishing a Documentation Site with GitHub Pages

This tutorial sets up a documentation site for your ModuleForge module: a GitHub Pages site that publishes hand-written guides alongside an always-current function reference that regenerates itself on every release. The site you are reading right now is built exactly this way.

## What you'll build

- A dedicated `docs` branch that GitHub Pages serves from
- A [Just the Docs](https://just-the-docs.com/) themed site with a navigation sidebar
- A `Docs Update` GitHub Actions workflow that regenerates your function reference after each release and opens a pull request against the `docs` branch for you to review and merge

> **Best suited to public, open-source repositories.** GitHub Pages publishes a public website. On the free plan it is only available for public repositories; serving Pages from a private repository requires a paid GitHub plan, and even then you would be publishing documentation for a closed module. If your repository is private or your module is not open-source, weigh that up before following this tutorial. The rest of this guide assumes a public repo.

## The model: two layers of docs

It helps to hold one idea in your head before you start. A ModuleForge docs site is made of two layers:

- **Hand-written pages** (concepts, tutorials, FAQ). You author these and they are yours. They are preserved across regeneration.
- **The generated function reference.** `Write-MFModuleDocs` runs [PlatyPS](https://github.com/PowerShell/platyPS) over your imported module, turns each function's comment-based help into a Markdown page, and rebuilds the `functions/` index. This folder is disposable: it is regenerated from your code every release, so you never hand-edit it.

The practical consequence: the quality of your function reference is the quality of your comment-based help. Good `.SYNOPSIS`, `.DESCRIPTION`, and `.EXAMPLE` blocks become good docs for free. See [PowerShell Style Recommendations](../../Concepts/PowerShellStyle.md) for more on that.

---

## Prerequisites and a clean `docs` branch

Before you start you need a ModuleForge project that already **builds and releases to GitHub Packages**. If you have followed the [Getting Started](./github-tutorial-01-getting-started.md) and [Build and Release](../../build-and-release.md) guides and have at least one release in your repository's Packages, you are ready. The docs workflow installs your module *from that feed*, so there has to be something published to document.

> The `Write-MFModuleDocs` function and the `docsUpdate.yml.example` workflow are added to your project by `Add-MFGithubScaffold`. If you scaffolded your project before these existed, re-run the scaffold with `-Force` to pull them in (see the [upgrade FAQ](../../faq.md)).

The docs site lives on its own **orphan branch** so it carries none of your source history, just the site content. From a clean working tree:

```bash
# Make sure your real branches are committed and pushed first.
git checkout --orphan docs
git rm -rf .          # remove the source files from this branch only; they remain on main
mkdir docs
```

Everything the site needs will live under that `docs/` folder. Add a placeholder homepage so the branch has content to commit:

```bash
# docs/index.md  - a temporary placeholder; the workflow will generate the real homepage later
echo "# My Module Docs" > docs/index.md
git add docs
git commit -m "chore: initialise docs branch"
git push -u origin docs
```

---

## Enabling GitHub Pages and Actions

With the branch pushed, point GitHub Pages at it:

1. Go to your repository's **Settings → Pages**.
2. Under **Build and deployment**, set **Source** to **Deploy from a branch**.
3. Choose branch **`docs`** and folder **`/docs`**, then **Save**.

GitHub will build the site and, after a minute, show you the URL (typically `https://<your-user>.github.io/<your-repo>/`). At this point it will be bare, that is expected; the theme and content come next.

While you are in Settings, confirm **Settings → Actions → General** allows workflows to run (the default for most repositories). You do not need to grant Actions permission to create pull requests, because the docs workflow uses its own token for that (set up further down).

---

## Setting up the config

Just the Docs is configured through a single `_config.yml` at the root of your site content. Create `docs/_config.yml`:

```yaml
remote_theme: just-the-docs/just-the-docs

plugins:
  - jekyll-seo-tag

title: MyModule
description: What my module does

# IMPORTANT: must match your repository name for a project site
baseurl: "/MyModule"

color_scheme: dark

aux_links:
  "GitHub":
    - "https://github.com/<your-user>/MyModule"
aux_links_new_tab: true

mermaid:
  version: "11"
```

The one value people get wrong is `baseurl`. For a project site served at `https://<user>.github.io/MyModule/`, `baseurl` must be `"/MyModule"`, or the theme's CSS and internal links will 404. Commit and push this to the `docs` branch; Pages will rebuild and your site will pick up the theme.

---

## Adding your own pages with front matter

Hand-written pages are just Markdown files under `docs/`, each beginning with a YAML **front matter** block. That block is what Just the Docs reads to build the sidebar. A top-level page looks like this:

```markdown
---
layout: default
title: Getting Started
nav_order: 2
---
# Getting Started

Your content here.
```

To group pages into a section, give them a `parent`, and create an `index.md` for the section itself with `has_children: true`:

```markdown
---
layout: default
title: Concepts
has_children: true
nav_order: 5
---
# Concepts
```

```markdown
---
layout: default
title: Why I built this
parent: Concepts
nav_order: 1
---
# Why I built this
```

A few things worth knowing:

- `nav_order` controls sidebar position within a level. Set it deliberately on pages you care about ordering.
- Just the Docs renders **at most three sidebar levels** (page, parent, grand_parent). Keep your nesting within that.
- You do not strictly have to write front matter by hand. When the workflow runs `Write-MFModuleDocs -StampAllDocs`, it will *non-destructively* stamp front matter onto any page that lacks it, using the page's H1 as the title. Pages that already have front matter are never touched, and your hand-set `nav_order` and titles are preserved across regeneration. Writing it yourself just gives you full control.

This is the layer you own. Add as many concept and tutorial pages as you like; the next steps wire up the generated function reference around them.

---

## Creating a fine-grained token for the workflow

The workflow needs to push a branch and open a pull request against your `docs` branch. GitHub's built-in `GITHUB_TOKEN` cannot do this reliably in all repository configurations, so the workflow uses a fine-grained Personal Access Token for that final step only.

1. Go to **GitHub Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**.
2. **Resource owner:** your account or organisation.
3. **Repository access:** Only select repositories → your module's repository.
4. **Repository permissions:**
   - **Contents:** Read and write (to push the docs-update branch)
   - **Pull requests:** Read and write (to open the PR against `docs`)
5. Generate the token and copy it.
6. In your repository, go to **Settings → Secrets and variables → Actions → New repository secret**, name it **`DOCS_PAT`**, and paste the token.

> Only the final "create pull request" step uses this token. Every earlier step (installing your module, generating docs) uses the standard `GITHUB_TOKEN`.

---

## Enabling the ModuleForge docs workflow

The workflow file ships with your scaffold as `.github/workflows/docsUpdate.yml.example`, on your **default branch** (alongside your other ModuleForge workflows and your source, not on the `docs` branch). It **must** live on the default branch for its triggers to work, so enable it the same way you land any other change to `main`: on a branch, then through a pull request.

```bash
# on a feature branch off main
git mv .github/workflows/docsUpdate.yml.example .github/workflows/docsUpdate.yml
git commit -m "chore: enable docs update workflow"
git push -u origin enable-docs-workflow
# then open a PR into main and merge it
```

Once it is on `main`, the workflow has two triggers:

- **Automatic:** it runs after every successful `Build and Release`, prerelease or stable, and opens a docs pull request for that release. If you do not want a particular update, just close the PR; nothing is forced on you. In practice that PR is a useful nudge, a standing reminder to keep your documentation from drifting away from your code.
- **Manual:** you can also run it on demand from **Actions → Docs Update → Run workflow**, choosing which release to document (`latest-release`, `latest-stable`, or `latest-prerelease`).

When it runs it installs your released module from GitHub Packages, imports it, regenerates the function reference into the `docs` branch with `Write-MFModuleDocs -StampAllDocs`, and opens a pull request titled `docs: update for <tag>` against `docs`. No code is ever changed, only documentation, and nothing lands until you review and merge (or close).

---

## Triggering the first docs PR with a prerelease build

You do not have to wait for a stable release to see this work. A prerelease exercises the whole flow:

1. **Build a prerelease.** Run **Actions → Build and Release → Run workflow** with the release type set to **prerelease**. This publishes a prerelease of your module to GitHub Packages.
2. **Let the docs workflow fire.** When the `Build and Release` run finishes, `Docs Update` triggers automatically and opens a docs pull request for that prerelease. You do not need to do anything to kick it off. (The manual trigger is still there if you ever want to re-document a specific release on demand.)
3. **Review and merge the PR.** The workflow opens a pull request against `docs` (branch `docs-update/<tag>`) containing your freshly generated `functions/` reference and a stamped, navigable structure. Review it like any other PR and merge, or close it if you do not want this particular update.
4. **Watch Pages rebuild.** Once merged, GitHub Pages redeploys and your function reference appears in the sidebar alongside your hand-written pages.

From here on the loop runs itself: every release, prerelease or stable, auto-opens a docs PR you can merge or close. Your job is to keep your comment-based help good and review the PRs.

---

## Customizing when docs are generated

By default the workflow opens a docs PR for **every** release, prerelease and stable. That is intentional: an unwanted PR is one click to close, and its presence is a standing reminder to keep your docs in step with your code. If you would rather automate docs only for stable releases, the workflow is yours to edit.

In `.github/workflows/docsUpdate.yml`, the automatic trigger decides which release to document here:

```powershell
$releaseSelector = if('${{ github.event_name }}' -eq 'workflow_dispatch')
{
    '${{ github.event.inputs.release_selector }}'   # manual run: respects the dropdown you choose
}else{
    'latest-release'                                 # automatic run: documents whatever was just released
}
```

Change the automatic value from `latest-release` to `latest-stable`, and a prerelease build will resolve to the most recent *stable* release instead. That is almost always already documented, so no PR is opened, while stable releases continue to generate docs as normal. The manual **Run workflow** trigger still lets you document any specific release, including a prerelease, on demand.

---

## What you learned

- Docs live on a dedicated `docs` branch served by GitHub Pages, themed with Just the Docs via `_config.yml`.
- Pages are two layers: hand-written content you own, and a function reference generated from your module by `Write-MFModuleDocs`.
- Front matter drives the sidebar; `-StampAllDocs` fills it in non-destructively while preserving anything you set by hand.
- A fine-grained `DOCS_PAT` lets the `Docs Update` workflow open PRs against `docs`.
- Every release, prerelease or stable, auto-opens a docs PR you can merge or close; the manual trigger documents a specific release on demand.

## Next steps and related reading

| Goal | Where to go |
| --- | --- |
| Write better help that becomes better docs | [PowerShell Style Recommendations](../../Concepts/PowerShellStyle.md) |
| Understand the release flow that feeds the docs | [Build and Release Guide](../../build-and-release.md) |
| Re-scaffold to get the latest workflow files | [Upgrade FAQ](../../faq.md) |
| Full function reference for `Write-MFModuleDocs` | [Write-MFModuleDocs](../../functions/Write-MFModuleDocs.md) |
