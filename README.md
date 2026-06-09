# ModuleForge

[![PowerShell 7+](https://img.shields.io/badge/PowerShell-7%2B-blue?logo=powershell&logoColor=white)](https://github.com/PowerShell/PowerShell)
[![Cross-Platform](https://img.shields.io/badge/Cross--Platform-Yes-brightgreen)](https://adrian-andersson.github.io/ModuleForge/)
[![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-CI%2FCD-2088FF?logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![Azure DevOps](https://img.shields.io/badge/Azure%20DevOps-Pipelines-0078D7?logo=azuredevops&logoColor=white)](https://azure.microsoft.com/en-us/products/devops)
[![PSGallery](https://img.shields.io/badge/PSGallery-ModuleForge-5391FE?logo=powershell&logoColor=white)](https://www.powershellgallery.com/packages/ModuleForge)

> **From a blank slate to a production-ready PowerShell module -> with CI/CD, versioning, release notes and publishing sorted, up and running in minutes**

PowerShell modules are the standard way to package and share reusable PowerShell code, but building and iterating modules with a consistent structure, versioning, tests, and a publishing pipeline involves a lot of moving parts.

**ModuleForge** is a scaffolding and build tool that takes the grunt work out of PowerShell module development. Stop copy-pasting boilerplate, wrestling with versioning, or hand-rolling CI pipelines. ModuleForge handles the infrastructure so you can focus on writing great code.

📦 **[Install from PowerShell Gallery](https://www.powershellgallery.com/packages/ModuleForge)**  
📖 **[Read the Full Documentation](https://adrian-andersson.github.io/ModuleForge/)**

```powershell
Install-PSResource -Name ModuleForge
```

## Why ModuleForge?

Setting up a PowerShell module correctly is tedious. Consistent folder structure, semantic versioning, changelog automation, CI/CD pipelines for both GitHub and Azure DevOps, Pester integration, PSResourceGet compatibility: There is a lot to know, a lot to get right, and even more to maintain across projects.

ModuleForge solves this with a single, opinionated CI/CD toolchain that gets out of your way once you're up and running.

## Key Features

### 🏗️ One-Line Module Scaffolding

Spin up a standardised, ready-to-build module structure in seconds. No more blank-page paralysis or inconsistent project layouts across your team.

### ⚙️ CI/CD Workflows -> GitHub & Azure DevOps

Add production-grade pipelines with full feature parity across both platforms:

- **Pester tests** are hard-fail -> broken code doesn't ship
- **Code coverage** is soft-fail -> tracked without blocking releases
- **PSScriptAnalyzer** runs in advisory mode -> keeping your code clean without the noise
- **Auto-generated PR comments** surface lint and test results directly in your review workflow

![PR Comments](/img/moduleForge_pr_comments.png)

### 🏷️ Tag-Based Semantic Versioning

Auto-Applied tagging tracks build versions so you don't have to, including pre-release support for staging and beta builds.

![Versioning](/img/versions.png)

### 📋 Automated Changelog Generation

Commit prefixes (`feat:`, `fix:`, `chore:`, etc.) drive automatic changelog creation and GitHub Packages release notes -> no manual changelog maintenance required.

![Changelog](/img/changelog.png)

### 📦 Flexible Publishing

Publish to **GitHub Packages** or **Azure DevOps Artifacts** feeds for personal projects or testing, and one-click publish to PSGallery when you're ready.
Options for whatever fits your workflow and requirements

### 🛠️ Full PowerShell 7+ Support

Built for modern PowerShell, including enumerators, classes, and advanced language constructs. Classes, enumerators, complex dependencies -> if PowerShell supports it, ModuleForge handles it.

## Workflow Overview

```mermaid
graph TD
  A[🚀 Start a New PowerShell Module] --> B[💻 Code Your Functions]
  B --> C[🔍 Test Locally]
  C --> D[💾 Commit & Open a PR]
  D --> E
  subgraph "CI ⚙️"
    E[🧪 Pester Tests & PSScriptAnalyzer]
  end
  E -->|Fail| B
  E -->|Pass| F[👀 Review & Merge]
  F --> G
  subgraph "CD 🚚"
    G[🏷️ Build & Release Version]
    G --> H[📤 Deploy & Publish]
  end
  H --> B
```

## Design Goals

ModuleForge was built around a clear set of principles:

| Goal | What It Means |
| - | - |
| **Minimal config** | PowerShell CI/CD that just works |
| **Standardised setup** | Fast, consistent module scaffolding every time |
| **Cross-platform** | Fully OS agnostic; Windows, macOS, Linux |
| **Semantic versioning** | Easy pre-release support and version incrementing |
| **Orchestrator agnostic** | Works with GitHub Actions, Azure DevOps, or your own tooling |
| **Modern stack** | PowerShell 7+, Pester, and PSResourceGet |
| **Scalable** | Handles simple scripts and complex multi-dependency modules alike |

## 🔍 Dependency Visualisation

ModuleForge can map the call relationships between your module's source files and render them in the terminal or as a [Mermaid](https://mermaid.js.org/) flowchart. Run it from your project root:

```powershell
Get-MFDependencyTree
```

Useful for:

- **Writing Pester tests** -> see exactly which private functions a public function calls so you can dot-source the right dependencies in `BeforeAll`
- **Load order** -> identify which classes or private helpers must resolve before a function, informing what goes in `ScriptsToProcess` or `NestedModules`
- **Spotting circular dependencies** -> cycles are immediately visible in the flowchart before they cause a build failure
- **Living architecture docs** -> embed the output directly in a README or docs page and it stays current with the code

For quick local inspection without leaving the terminal (truncated):

```text
.\source\functions\Invoke-MFBuildPreRelease.ps1
     >--DEPENDS-ON--> .\source\functions\Build-MFProject.ps1
         >--DEPENDS-ON--> .\source\functions\Get-MFFolderItemDetails.ps1
             >--DEPENDS-ON--> .\source\functions\Get-MFFolderItems.ps1
     >--DEPENDS-ON--> .\source\private\Get-MFProjectRoot.ps1
```

Add `-OutputType MermaidMarkdown` to embed directly in docs -> GitHub renders it inline (truncated):

```mermaid
flowchart TD
'.\source\functions\Invoke-MFBuildPreRelease.ps1' --> '.\source\functions\Build-MFProject.ps1'
'.\source\functions\Invoke-MFBuildPreRelease.ps1' --> '.\source\private\Get-MFProjectRoot.ps1'
'.\source\functions\Build-MFProject.ps1' --> '.\source\functions\Get-MFFolderItemDetails.ps1'
'.\source\functions\Build-MFProject.ps1' --> '.\source\functions\Get-MFFolderItems.ps1'
'.\source\functions\Get-MFFolderItemDetails.ps1' --> '.\source\functions\Get-MFFolderItems.ps1'
'.\source\functions\Write-MFModuleDocs.ps1' --> '.\source\private\ConvertTo-MFNavTitle.ps1'
'.\source\functions\Write-MFModuleDocs.ps1' --> '.\source\private\Get-MFH1FromFile.ps1'
'.\source\functions\New-MFProject.ps1' --> '.\source\private\add-mfFilesAndFolders.ps1'
```

## Getting Started

Full tutorials, function reference, and examples are available in the **[ModuleForge documentation](https://adrian-andersson.github.io/ModuleForge/)**.

---

## Contributing

Issues and PRs welcome. Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
