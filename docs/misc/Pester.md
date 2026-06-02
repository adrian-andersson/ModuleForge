---
layout: default
title: Writing Pester Tests
parent: Concepts
nav_order: 4
---
# Writing Pester Tests

[Pester](https://pester.dev) is the standard testing framework for PowerShell. ModuleForge is built around Pester 5+ and expects tests to live alongside their functions in the source folder — each `FunctionName.ps1` has a corresponding `FunctionName.Tests.ps1` in the same directory. This convention keeps tests close to the code they cover and makes the dependency between them explicit.

## Role in the CI/CD Pipeline

Pester tests are a hard-fail gate in the CI pipeline — a failed test run blocks the build. Code coverage is tracked as a soft-fail advisory: it surfaces in PR comments and is visible in the pipeline output, but does not block a merge on its own. The goal is to meet the default Pester coverage threshold, which gives a meaningful signal without making coverage an absolute blocker.

> **Scope of coverage:** ModuleForge runs tests and measures code coverage against exported functions only — the contents of the `functions` folder. Private functions, classes, and enums are deliberately excluded. The reasoning is that private functions are always called through exported functions, so testing the exported surface implies the downstream dependencies are exercised too. Coverage figures are therefore not a complete picture of every code path, but this scope keeps the automation simple and the test surface manageable — a deliberate trade-off in favour of usability over precision.
>
> This does mean that ModuleForge's CI/CD pipeline is not designed for traditional test-driven development (TDD). Tests against exported functions behave more like integration tests than unit tests, which makes pinpointing failures in private dependencies less direct. If you want to practise TDD at the private function level, you can — nothing stops you from writing tests alongside your private functions. You will need to invoke them separately with your own test-execution script rather than relying on the built-in pipeline automation. That is a limitation of the CI/CD design, not of Pester or your module structure.

The typical flow looks like this:

1. Commit changes and open a PR
2. Pester tests run automatically — hard fail if any test fails
3. Code coverage is reported as an advisory in the PR
4. On merge, the build pipeline validates that the latest Pester run passed before proceeding
5. Build the module with a new prerelease version
6. Publish to the artifacts feed for validation
7. Promote to a stable release when ready

## The Problem with Testing Module Source

Testing a compiled `.psm1` is one option, but it creates scoping problems — `InModuleScope` produces complicated code coverage results, and it is harder to isolate whether a failure is in a dependency or the function under test.

The better approach is to test directly against the source `.ps1` files, but this introduces its own dependency problem. If `function1.ps1` calls `privateFunction2.ps1`, that private function needs to be loaded before the test can run. With a small module this is manageable, but as dependencies grow — many small functions composing into a larger one — dot-sourcing everything individually in each test's `BeforeAll` becomes unmanageable.

## Solving the Dependency Problem

ModuleForge includes [`Get-MFDependencyTree`](../functions/Get-MFDependencyTree.md) to map function dependencies. Run it against your source folder to see exactly what each function depends on:

```powershell
$folderItemDetails = Get-MFFolderItemDetails -path $sourcePath
Get-MFDependencyTree -referenceData $($folderItemDetails | Select-Object relativePath, Dependencies)
```

Example output:

```text
.\source\functions\build-mfProject.ps1
     >--DEPENDS-ON--> .\source\functions\get-mfDependencyTree.ps1
     >--DEPENDS-ON--> .\source\functions\get-mfFolderItemDetails.ps1
         >--DEPENDS-ON--> .\source\functions\get-mfFolderItems.ps1
     >--DEPENDS-ON--> .\source\functions\get-mfFolderItems.ps1
.\source\functions\get-mfFolderItemDetails.ps1
     >--DEPENDS-ON--> .\source\functions\get-mfFolderItems.ps1
.\source\functions\new-mfProject.ps1
     >--DEPENDS-ON--> .\source\private\add-mfFilesAndFolders.ps1
```

Use the output to populate the `BeforeAll` block of each test with only what it needs.

## BeforeAll Pattern

The following pattern loads dependencies by type in the correct order (enums and classes before functions) before dot-sourcing the file under test:

```powershell
BeforeAll {

    $currentPath = $(Get-Location).path
    $sourcePath = Join-Path -path $currentPath -childPath 'source'

    # Declare dependencies in load order — replace with actual file names
    $dependencies = [ordered]@{
        enums      = @('MyEnum.ps1')
        classes    = @('MyClass.ps1')
        functions  = @('HelperFunction.ps1')
        private    = @('PrivateHelper.ps1')
    }

    $dependencies.GetEnumerator().ForEach{
        $directoryRef = Join-Path -path $sourcePath -childPath $_.Key
        $_.Value.ForEach{
            $itemPath = Join-Path -path $directoryRef -childPath $_
            $itemRef = Get-Item $itemPath -ErrorAction SilentlyContinue
            if ($itemRef) {
                write-verbose "Dependency identified at: $($itemRef.fullname)"
                . $itemRef.FullName
            } else {
                Write-Warning "Dependency not found at: $itemPath"
            }
        }
    }

    # Store the file path and function name explicitly — used by the Clean Environment check below
    $fileName = $PSCommandPath.Replace('.Tests.ps1', '.ps1')
    $functionName = 'MyFunctionName'
    . $fileName
}
```

The `[ordered]` hashtable ensures enums and classes are loaded before functions that depend on them — load order matters in PowerShell when types are involved. Note that the final two lines replace the simple dot-source at the end — storing `$fileName` and `$functionName` explicitly enables the clean environment check described below.

## Check Clean Environment

It is good practice to add a `Describe 'Check Clean Environment'` block as the first test in every test file. This verifies that the function under test was loaded from the source file directly rather than from an installed or imported version of the module — a subtle but important distinction that can cause tests to pass against stale code if the module happens to be imported in the same session.

```powershell
Describe 'Check Clean Environment' {
    BeforeAll {
        Write-Warning "PSCommandPath: $psCommandPath; scriptToLoad: $($PSCommandPath.Replace('.Tests.ps1','.ps1'))"
    }
    It 'Should have loaded the script directly, not from the module' {
        $PSCommandPath.Replace('.Tests.ps1', '.ps1') | Should -Be $fileName
        (Get-Command $functionName).Source | Should -BeNullOrEmpty
    }
}
```

The first assertion confirms the resolved path matches what was loaded. The second confirms the function has no module source — if `(Get-Command $functionName).Source` returns a value, the function is being resolved from an imported module rather than the dot-sourced file, which means the test is not running against the code you think it is.

## Further Reading

- [Classes, Enums and Validators — Scoping Concerns](./Classes_Enums_And_Validators.md) — why load order in your `BeforeAll` matters, and how PowerShell scopes special types
- [Pester documentation](https://pester.dev/docs/quick-start) — official Pester 5 quick start
