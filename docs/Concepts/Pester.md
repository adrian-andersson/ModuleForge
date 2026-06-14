---
layout: default
title: Writing Pester Tests
parent: Concepts
nav_order: 4
---
# Writing Pester Tests

[Pester](https://pester.dev) is the standard testing framework for PowerShell. ModuleForge is built around Pester 5+ and expects tests to live alongside their functions in the source folder - each `FunctionName.ps1` has a corresponding `FunctionName.Tests.ps1` in the same directory. This convention keeps tests close to the code they cover and makes the dependency between them explicit.

## Role in the CI/CD Pipeline

Pester tests are a hard-fail gate in the CI pipeline - a failed test run blocks the build. Code coverage is tracked as a soft-fail advisory: it surfaces in PR comments and is visible in the pipeline output, but does not block a merge on its own. The goal is to meet the default Pester coverage threshold, which gives a meaningful signal without making coverage an absolute blocker.

> **Scope of coverage:** ModuleForge runs tests and measures code coverage against both your exported functions (`source/functions`) and your private functions (`source/private`). Classes, enums, and validation classes are deliberately excluded - Pester's coverage instrumentation for PowerShell classes is unreliable - as are the binary and template folders (`bin`, `lib`, `resource`), which hold no PowerShell logic. This scope covers the code paths that matter while keeping the automation simple.
>
> Because private functions are now in scope, you can practise test-driven development at the private function level and have the pipeline pick it up automatically - write `PrivateHelper.Tests.ps1` alongside `PrivateHelper.ps1` in `source/private` and it is discovered, run, and measured for coverage exactly like an exported function. Tests against exported functions still behave more like integration tests (they exercise the whole call chain), but you are no longer limited to that style.
>
> If you prefer a separate home for tests - integration tests, for example - a root-level `tests` folder (matched case-insensitively) is auto-detected and added to test discovery. Tests stored in this location are run in addition to co-located tests, so mixing both methods will not break testing functionality. Code-Coverage is distinct and separate to where the test files are located.
>
> **Constrained Language Mode:** Pester's coverage instrumentation cannot run under CLM. Pass `-SkipCodeCoverage` to `Invoke-MFPester.ps1` to run tests without coverage on locked-down systems.

The typical flow looks like this:

1. Commit changes and open a PR
2. Pester tests run automatically - hard fail if any test fails
3. Code coverage is reported as an advisory in the PR
4. On merge, the build pipeline validates that the latest Pester run passed before proceeding
5. Build the module with a new prerelease version
6. Publish to the artifacts feed for validation
7. Promote to a stable release when ready

## The Problem with Testing Module Source

Testing a compiled `.psm1` is one option, but it creates scoping problems - `InModuleScope` produces complicated code coverage results, and it is harder to isolate whether a failure is in a dependency or the function under test.

The better approach is to test directly against the source `.ps1` files, but this introduces its own dependency problem. If `function1.ps1` calls `privateFunction2.ps1`, that private function needs to be loaded before the test can run. With a small module this is manageable, but as dependencies grow - many small functions composing into a larger one - dot-sourcing everything individually in each test's `BeforeAll` becomes unmanageable.

## Solving the Dependency Problem

ModuleForge includes [`Get-MFDependencyTree`](../functions/Get-MFDependencyTree.md) to map function dependencies. Run it against your source folder to see exactly what each function depends on:

```powershell
$folderItemDetails = Get-MFFolderItemDetails -path $sourcePath
Get-MFDependencyTree -referenceData $($folderItemDetails | Select-Object relativePath, Dependencies)
```

Example output:

```text
.\source\functions\build\Build-MFProject.ps1
     >--DEPENDS-ON--> .\source\functions\insights\Get-MFDependencyTree.ps1
     >--DEPENDS-ON--> .\source\functions\build\Get-MFFolderItemDetails.ps1
         >--DEPENDS-ON--> .\source\functions\build\Get-MFFolderItems.ps1
     >--DEPENDS-ON--> .\source\functions\build\Get-MFFolderItems.ps1
.\source\functions\build\Get-MFFolderItemDetails.ps1
     >--DEPENDS-ON--> .\source\functions\build\Get-MFFolderItems.ps1
.\source\functions\scaffold\New-MFProject.ps1
     >--DEPENDS-ON--> .\source\private\scaffold\Add-MFFilesAndFolders.ps1
```

Use the output to populate the `BeforeAll` block of each test with only what it needs.

## BeforeAll Pattern

The pattern below builds a one-time map of every `.ps1` file under `source/` (filename to full path), then loads each dependency by **filename**, in declared order, before dot-sourcing the file under test:

```powershell
BeforeAll {

    $currentPath = $(Get-Location).path
    $sourcePath = Join-Path -path $currentPath -childPath 'source'

    # Map every source file by name, so dependencies resolve no matter which subfolder they live in. List order is load order.
    $sourceMap = @{}
    Get-ChildItem -Path $sourcePath -Recurse -Filter '*.ps1' -File | ForEach-Object {
        if (-not $sourceMap.ContainsKey($_.Name)) { $sourceMap[$_.Name] = $_.FullName }
    }

    # Declare dependencies in load order - types (enums, classes, validators) before the functions that use them
    $dependencies = @(
        'MyEnum.ps1'
        'MyClass.ps1'
        'HelperFunction.ps1'
        'PrivateHelper.ps1'
    )

    $dependencies.ForEach{
        if ($sourceMap.ContainsKey($_)) {
            write-verbose "Dependency identified at: $($sourceMap[$_])"
            . $sourceMap[$_]
        } else {
            Write-Warning "Dependency not found under source: $_"
        }
    }

    # Store the file path and function name explicitly - used by the Clean Environment check below
    $fileName = $PSCommandPath.Replace('.Tests.ps1', '.ps1')
    $functionName = 'MyFunctionName'
    . $fileName
}
```

Resolving by filename keeps the test independent of the folder layout: because ModuleForge organises `source/functions` and `source/private` into scope-based subfolders, a dependency can move between subfolders (or sit in a different scope to the function under test) without breaking the test. You only list the filenames you need.

Order still matters: list dependencies so that types (enums, classes, validation classes) load before the functions that reference them - PowerShell needs those types defined at parse time. The final three lines replace a simple dot-source at the end; storing `$fileName` and `$functionName` explicitly enables the clean environment check described below.

## Check Clean Environment

It is good practice to add a `Describe 'Check Clean Environment'` block as the first test in every test file. This verifies that the function under test was loaded from the source file directly rather than from an installed or imported version of the module - a subtle but important distinction that can cause tests to pass against stale code if the module happens to be imported in the same session.

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

The first assertion confirms the resolved path matches what was loaded. The second confirms the function has no module source - if `(Get-Command $functionName).Source` returns a value, the function is being resolved from an imported module rather than the dot-sourced file, which means the test is not running against the code you think it is.

## Further Reading

- [Classes, Enums and Validators - Scoping Concerns](./Classes_Enums_And_Validators.md) - why load order in your `BeforeAll` matters, and how PowerShell scopes special types
- [Pester documentation](https://pester.dev/docs/quick-start) - official Pester 5 quick start
