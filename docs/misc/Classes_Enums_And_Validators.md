# Classes, Enums and Validators — Scoping Concerns

When building PowerShell modules that use classes, enums, and custom validator extensions, scoping becomes a significant concern — both at runtime and during testing. Understanding how PowerShell handles these types determines how they should be structured in your module and how they need to be loaded in your Pester `BeforeAll` blocks.

This page covers the scoping fundamentals. For how to apply this in practice when writing tests, see [Pester Testing](./pester-testing/Pester.md).

Throughout this page, classes, enums, and custom validators are referred to collectively as _special types_.

## Scoping Rules for Special Types

- Enums should be loaded first — they have no dependencies on other types
- Classes with inheritance must be loaded in the right order — a child class will not compile if loaded before its parent
- All special types must be fully loaded and compiled before any function that references them is parsed
- Only functions and aliases can be exported via the module manifest — special types cannot be explicitly exported, which means they are always module-scoped unless deliberately broken out
- Being module-scoped is generally correct behaviour for classes and enums — they are implementation details, not public API surface

## Nested Modules

The module manifest supports a `NestedModules` parameter (`New-ModuleManifest -NestedModules @('script1','script2')`), which runs the listed scripts before the root module is imported. In theory this could enforce load order for special types. In practice:

- Nested modules behave inconsistently and break scope — types loaded this way are not available to the root module
- Enums loaded as nested modules cause the module to fail to import
- Classes loaded as nested modules have the same problem
- Validators have the same problem — loading them in the root module causes functions to fail to see them, likely because the validators have not finished compiling when the functions are parsed. Nested modules do not solve this either — see `ScriptsToProcess` below

## ScriptsToProcess

`ScriptsToProcess` (`New-ModuleManifest -ScriptsToProcess @('script1','script2')`) dot-sources the listed scripts at session scope just before importing the module. This makes types available at both session and module scope.

- **Validators must be loaded via `ScriptsToProcess`** — this is the only reliable way to make them visible to functions at parse time
- The trade-off is that `ScriptsToProcess` runs at session scope, so validators remain in the session after the module is imported
- For standard modules this session exposure is acceptable given there is no alternative; for DSL modules it is actually desirable
- **Important limitation:** because `ScriptsToProcess` runs before the module is fully established, validator classes cannot load resources from the module's `resource` folder — the path context is not available at that point, so any file-based lookups inside a validator class will fail due to scoping

## Recommended Approach

Based on the above:

- Load **enums and classes** at the top of the root `.psm1` file, in dependency order
- Load **validators** via `ScriptsToProcess` — this is the only reliable mechanism for making them visible to functions
- If you want special types available outside the module scope (e.g. for a DSL), use `ScriptsToProcess`
- Avoid mixing custom validators with DSC resources in the same module
- **Validator classes cannot load resources from the module's `resource` folder** — do not attempt file-based lookups inside a validator class; the path context is not available when `ScriptsToProcess` runs

This is the default behaviour ModuleForge implements when building your module — enums and classes are injected at the top of the root `.psm1`, and validator classes are wired up via `ScriptsToProcess` automatically.

When deciding whether a custom validator is the right tool, follow this order of preference:

1. **Built-in parameter controls first** — `ValidateSet`, `ValidateRange`, `ValidatePattern`, `ValidateScript`, and similar attributes cover the majority of validation needs without any scoping complexity
2. **Enums second** — where you need a fixed set of named values, an enum is cleaner and more discoverable than a validator class
3. **Custom validators for specific cases only** — reserve them for validation logic that genuinely cannot be expressed with the above, such as complex cross-field validation or lookups that require custom type behaviour. Be aware that custom validators lose tab completion — the shell cannot introspect a `Validate()` method. You can restore it by stacking `[ArgumentCompletions()]` (PowerShell 7.0+) above the validator attribute, like below, but it is likely your complex validator cannot make use of this anyway:

    ```powershell
    [ArgumentCompletions('optionA','optionB','optionC')]
    [ValidateMyCustomAttribute()]
    [string]$MyParameter
    ```

    The completions are offered by the shell and the validation runs when the value is bound — the two attributes work independently.

## A Note on DSC Resources

> **Note:** These observations are from testing circa 2018 and may not reflect current behaviour. DSC support in ModuleForge is not currently in scope — see [Community Contributions](../../CONTRIBUTING.md).

When DSC resources are present, `NestedModules` and `ScriptsToProcess` appear not to load in time (or possibly at all). This means everything must be loaded together in the root module in the correct order. It also implies that custom validator classes and DSC resources should not coexist in the same module.
