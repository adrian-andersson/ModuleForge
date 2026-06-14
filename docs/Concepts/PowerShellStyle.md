---
layout: default
title: PowerShell Style Recommendations
parent: Concepts
nav_order: 10
---
# PowerShell Style Recommendations

ModuleForge is deliberately opinionated about *structure* and *workflow*: where files live, how versions increment, how the pipeline runs. It is far less opinionated about *how you write the PowerShell inside your functions*.

This page is **not** a rulebook. It is a set of style preferences collected as a convenient starting point for teams who want a house style but would rather not write one from scratch. Adopt what fits, ignore what doesn't, and document any deliberate deviations in your function's `.NOTES` so the next reader knows it was a choice rather than an accident.

> **This is guidance, not enforcement.** Nothing on this page is checked by the ModuleForge build. The only automated style feedback in a scaffolded project comes from PSScriptAnalyzer, which runs as a *soft-fail advisory* on your pull requests, see [Commit Strategy and PR Process](./CommitStrategy_And_PRProcess.md). Everything below is taste.

---

## What ModuleForge actually requires vs what is taste

It helps to separate the few things the tooling genuinely depends on from the much larger set of things that are simply preference.

| ModuleForge depends on this | This is just style |
| --- | --- |
| One function per `.ps1` file, filename matching the function name (the build maps files to exported functions) | Quoting, aliases, `return`, comment density |
| Source folder layout, see [Getting Started](../getting-started.md) | Generic lists vs arrays, splatting, iteration style |
| Load order for classes/enums/validators, see [Classes, Enums and Validators](./Classes_Enums_And_Validators.md) | Cross-platform path and environment idioms |

Stay inside the left column and your module builds. The right column is where this page lives.

---

## Pester and Code Coverage

You should aim for a high level of Code Coverage for your exported and private functions. It will save you from regression problems and from accidentally adding bugs to existing code. If you have a good habit of writing defensible code (Errors and Warnings that are unlikely to ever surface but exist for those edge cases), you may struggle to achieve perfect code-coverage, which is why Code Coverage itself is a soft-fail advisory, vs the tests being a hard-fail gate.

See [Writing Pester Tests](./Pester.md) for more details.

---

## Everyday conventions

These are the small, high-frequency choices that give a codebase a consistent feel.

| Preference | Rationale |
| --- | --- |
| **Single quotes by default**; double quotes only when you are expanding a variable or expression | Makes it obvious at a glance which strings are interpolated |
| **Avoid aliases** in committed code (`Get-ChildItem`, not `gci`) | Readability and discoverability for the next person |
| **Avoid `return`** unless you genuinely need an early exit; let objects flow to the pipeline | `return` in PowerShell is often misunderstood and rarely needed |
| **Avoid `Write-Host` for data**; return objects to the pipeline, or use `Write-Verbose` / `Write-Information` for status | Since PowerShell 5 it writes to the information stream, so it is display output, not pipeline data a caller can consume |
| **`Write-Verbose`** for narration on meaningful steps and variable assignments | Doubles as living documentation that can be switched on with `-Verbose` |
| **`Write-Warning`** for non-terminating problems; **`throw`** for terminating ones | Clear, conventional severity signalling |
| **Splat** when calling a command with two or more parameters | Keeps long calls readable and diff-friendly |
| **`-WhatIf` / `ShouldProcess`** on any function that changes state | Lets users dry-run destructive operations |

A couple of these warrant a note:

- **Iteration:** the `.ForEach{}` and `.Where{}` methods read cleanly and are the default preference here. Be aware they buffer the whole collection in memory rather than streaming, so for very large or genuinely pipelined input the `ForEach-Object` / `Where-Object` cmdlets can be the better tool. Use judgement.
- **Inline comments:** prefer `Write-Verbose` over comments for *what is happening*. Reserve actual comments for *why* a non-obvious approach was taken over an obvious-but-flawed one. Bitwise operations are a good example of something that always deserves an explanatory comment.
- **`Write-Host` has a legitimate exception:** deliberate, human-facing console output, a welcome banner or coloured interactive status, is a fine use because it genuinely is not data. When you make that call, suppress the `PSAvoidUsingWriteHost` rule with a `Justification` so the intent is on the record, the same "document your deviations" principle this page closes on.

---

## Collections and objects

- **Build collections with a generic list, not by appending to an `@()` array.** Every `+=` on an array allocates a brand new array and copies the old contents in; a list with `.Add()` does not:

  ```powershell
  $results = [System.Collections.Generic.List[object]]::new()
  $items.ForEach{
      $results.Add($_)
  }
  ```

  Once the list is fully built, call `.ToArray()` if you want to hand back a plain array for a more conventional PowerShell experience downstream. The list is the efficient way to *build* the collection; a standard array is often the friendlier thing to *return*:

  ```powershell
  return $results.ToArray()
  ```

  And `List[T]` is not the only option. If your access pattern is first-in-first-out or last-in-first-out, a `[System.Collections.Generic.Queue[object]]` or `[System.Collections.Generic.Stack[object]]` can express intent more clearly than a list you manually index into. It is worth a look at the other `System.Collections.Generic` types when one fits your problem better.

- **Build objects from a hashtable, then cast to `[PSCustomObject]` for output.** Return raw hashtables only where that genuinely is the intent.
- **One space between hashtable keys and values; no column alignment.** Aligned columns look tidy until the longest key changes and you re-touch every line in the diff:

  ```powershell
  # Preferred
  [PSCustomObject]@{
      Name = $response.name
      Id = $response.id
  }
  ```

- **Prefer a reusable select array over a long inline `Select-Object`.** Define it once and reuse it. It makes the code significantly tidier and more readable, and only gets better the larger the select:

  ```powershell
  #The Select Array way
  $CustomSelect = @(
        'Name'
        'Id'
        @{
            Name = 'Computed'
            Expression = {
                $_.Value * 2
                }
        }
  )
  $objects | Select-Object $CustomSelect
  #==================================
  #Vs the more traditional inline way
  $objects | Select-Object 'Name','Id',@{Name = 'Computed';Expression = {$_.Value * 2}}
  ```

> **Where to define reusable select arrays:** put them in the **`begin` block**, alongside your other constants and configuration. They do not change between pipeline items, so building them once in `begin` avoids rebuilding the same array on every object that passes through `process`, and it keeps `process` focused on the actual work. See [Function shape](#function-shape) below.

---

## Cross-platform by default

Assume your module may run on Windows, Linux, and macOS unless you have a specific reason not to.

- Use `Join-Path` and `Split-Path` for **all** path construction. Reach for `[IO.Path]::DirectorySeparatorChar` only in the rare case `Join-Path` genuinely does not fit.
- Prefer `[System.Environment]` properties over `$env:` variables for well-known locations.
- Reference file objects by `.FullName` rather than `.Name`, unless `.Name` is specifically what you want.
- Call executables without an extension (`git`, not `git.exe`).
- Keep hashtable key casing consistent. It does not matter on Windows but can bite you on case-sensitive filesystems.

The CI workflows ModuleForge scaffolds run on `ubuntu-latest` by default, so cross-platform habits pay off immediately, see the [FAQ entry on Windows-only modules](../faq.md) if you hit a platform-specific wall.

---

## Function shape

The preference is for every piece of authored logic to be an **advanced function** with explicit `begin` / `process` blocks. The skeleton below mirrors what ModuleForge's own functions look like:

```powershell
function Verb-Noun
{
    <#
        .SYNOPSIS
            One-line summary.

        .DESCRIPTION
            Detailed description.

        .NOTES
            Note any version-specific features here (for example, 'clean' requires 7.3+).

        .EXAMPLE
            Verb-Noun -Param1 'Value'

            #### DESCRIPTION
            What this example does.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Description of Param1, placed directly above the declaration
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Param1
    )

    begin {
        Write-Verbose "===========Executing $($MyInvocation.InvocationName)==========="
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters | Out-String)"

        # Constants, configuration, and reusable select arrays live here
        $selectArr = @(
            'Param1'
            @{ Name = 'Computed'; Expression = { $_.Param1.ToUpper() } }
        )
    }

    process {
        # Primary logic here
    }
}
```

Recommended habits within that shape:

- Use **approved verbs** (`Get-Verb` lists them). PSScriptAnalyzer will flag unapproved ones.
- Always include `[CmdletBinding()]`; add `SupportsShouldProcess` when the function makes changes.
- Give every parameter a `[Parameter()]` attribute, validation where it makes sense, and a comment directly above it. Use `[Parameter(DontShow)]` for internal or technical parameters.
- Open `begin` with the verbose entry line and debug bound-params dump shown above; this is the convention ModuleForge uses throughout its own source, and it makes `-Verbose` / `-Debug` runs genuinely useful.
- Keep primary logic in `process`.
- `end` and `clean` are optional. Prefer `clean` over `end` where both would apply, but note that **`clean` requires PowerShell 7.3+**, so call it out in `.NOTES` if you use it.
- **Avoid nested functions** inside `begin` / `process` / `end` / `clean`. If you need a helper, make it a standalone private function under `source/private/` (it follows these same conventions and is not exported).
- Write good Descriptions and Examples, and review them after function changes. The inline-help gets translated to Markdown if you have enabled the DocSite and good documentation stands out for all the right reasons.
- If you have a PSScriptAnalyzer rule that you want to accept, you can add the appropriate bypass rule just under the meta-data section and suppress it properly. E.g: `[Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '', Justification='Write-Host makes sense in this function')]`
- When reusing a variable name inside a `.ForEach{}` loop, clear it at the top of each iteration rather than trusting it to be empty:

  ```powershell
  $items.ForEach{
      Remove-Variable -Name result -ErrorAction Ignore
      $result = Do-Something -Input $_
  }
  ```

---

## Code Examples and Pester Test Samples

If you want examples that follow the styles in this guide, you are welcome to inspect the source code and pester tests of ModuleForge itself.

---

## When a request conflicts with your house style

If you adopt a style like this and later find a specific situation where it does not fit, the worst option is to silently break it. Better: make the deviation visible. Document *why* in the function's `.NOTES`, or leave a short `why` comment at the point of departure. Future-you, and your reviewers, will thank you.

And to be clear one last time: this entire page is a recommendation. Your module, your rules. ModuleForge will build it either way.

---

## Related reading

- [Writing Pester Tests](./Pester.md) - the testing conventions ModuleForge does expect
- [Classes, Enums and Validators](./Classes_Enums_And_Validators.md) - load-order and scoping rules that genuinely affect compilation
- [Commit Strategy and PR Process](./CommitStrategy_And_PRProcess.md) - how PSScriptAnalyzer fits into the PR flow
- [Getting Started](../getting-started.md) - the source folder layout and file-placement rules
