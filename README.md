# ModuleForge

![PowerShell 7+](https://img.shields.io/badge/PowerShell-7%2B-blue?logo=powershell&logoColor=white)
![Cross-Platform](https://img.shields.io/badge/Cross--Platform-Yes-brightgreen)
![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-CI%2FCD-2088FF?logo=github-actions&logoColor=white)
![Azure DevOps](https://img.shields.io/badge/Azure%20DevOps-Pipelines-0078D7?logo=azuredevops&logoColor=white)

ModuleForge is a scaffolding and build tool designed to streamline PowerShell module creation. It simplifies the process of setting up a module, automating versioning, and ensuring compatibility with modern CI/CD workflows with a minimal amount of effort.

## Full Documentation Available Here

Tutorials, function documentation, examples, and other information is published [here](https://adrian-andersson.github.io/ModuleForge/)

## Design Goals

ModuleForge was built to achieve the following goals


- PowerShell CI/CD with minimal config
- Standardised, fast module setup
- Cross-platform, OS agnostic
- Semantic Versioning with easy prerelease support and incrementing
- Orchestration tool agnostic
- Support and use the latest versions of PowerShell 7+, Pester, and PSResourceGet
- Compatible with GitHub Packages
- Support simple and complex PowerShell modules alike
- Easily identify function and file dependencies in your project

ModuleForge is designed for flexibility.

## Key Features

- One-line module scaffolding with standard file layout
- Add CI workflows for GitHub or Azure DevOps (Feature Parity)
  - Pester tests are hard-fail, code coverage is soft-fail, ScriptAnalyzer is advisory
  - PR comments auto-generated with lint/test results
  - ![PR Comments](/img/moduleForge_pr_comments.png)
- Semantic changelog automation from commit prefixes (`feat`, `fix`, etc.)
  - GitHub Packages release integration
  - ![GH Release](/img/changelog.png)
- Support for enumerators, classes, and advanced PowerShell constructs
- Tag-based automated versioning with pre-release support
  - ![GH Release](/img/versions.png)
- Works with GitHub Packages and Azure DevOps feeds for module repositories

## Workflow Overview

```mermaid

graph LR
  A[Start A New Module Project] --> B[Code]
  B --> C[Test]
  C --> D[Commit & PR]
  D --> E[Automated Tests]
  E --> F[Release]
  F --> G[Deploy & Use]
  G --> B
```
