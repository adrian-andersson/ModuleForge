# AstroCmdlets: An Advanced ModuleForge Tutorial

This tutorial builds on the [GitHub Getting Started tutorial](./github-tutorial-01-getting-started.md) and demonstrates the full range of ModuleForge source folder types by building a space-themed PowerShell module called **AstroCmdlets**.

By the end you will have a module that uses enums, custom validation attributes, classes with inheritance, private functions, resource files, and scope-based subfolder organisation — and you will understand how ModuleForge compiles all of those pieces together.

---

## Prerequisites

- Familiarity with the basic ModuleForge GitHub tutorial
- PowerShell 7.2+
- VSCode
- Git CLI

Required modules:

```powershell
Install-PSResource -Name 'Pester'                             -Version '[5.6.0,)'
Install-PSResource -Name 'PSScriptAnalyzer'                   -Version '[1.24.0,)'
Install-PSResource -Name 'Microsoft.PowerShell.PSResourceGet' -Version '[1.1.1,)'
Install-PSResource -Name 'ModuleForge'                        -Version '[1.2.0,)'
```

---

## Part 1: New Repository

Log in to GitHub and create a new **private** repository named **AstroCmdlets**. Using a private repository is recommended for tutorial work — the built module will be published to GitHub Packages, which will also be private and only accessible to you.

Clone the repository locally, then initialise the ModuleForge project and add GitHub scaffolding:

```powershell
New-MFProject -ModuleName 'AstroCmdlets' -description 'A space-themed demonstration module' -moduleAuthors 'YourName' -moduleTags @('Demo','ModuleForge')
Add-MFGithubScaffold
```

Commit and push:

```
chore: Initialised ModuleForge project with scaffolding & workflows
```

---

## Part 2: Understanding the Full Source Structure

The basic tutorial only uses `source/functions/`. ModuleForge supports several folder types, each compiled in a fixed order:

| Folder | Purpose | Output |
|---|---|---|
| `enums/` | PowerShell enums | Inlined into psm1 (or `Enums.ps1` with `-ExportEnums`) |
| `validationClasses/` | Custom `ValidateArgumentsAttribute` subclasses | Separate `Validators.ps1` via `ScriptsToProcess` |
| `classes/` | PowerShell classes | Inlined into psm1 |
| `private/` | Internal helpers — not exported | Inlined into psm1 |
| `functions/` | Public exported functions | Inlined into psm1, names added to `FunctionsToExport` |
| `resource/` | Data files, templates, bundled assets | Copied as-is to module output |
| `bin/` | Binary dependencies | Copied as-is to module output |

The compilation order is the dependency order. A function can reference a class, a class can reference an enum or validation attribute, because those are compiled first. All of this is handled by ModuleForge so you don't need to worry about the order you code in. This tutorial follows the dependency order for the sake of simplicity.

### Scope-based subfolders

All source folders support one level of subfolders. ModuleForge discovers files recursively and the subfolder name is ignored by the compiler — it exists purely for your organisation.

The temptation is to organise by verb (`Get/`, `New/`, `Set/`), but this just duplicates information already in every PowerShell function name. Organise by scope instead — what domain or concern does this code belong to?

For AstroCmdlets we use two scopes:

- `Visitors/` — everything related to alien visitors and diplomacy
- `Launch/` — everything related to rockets and launches

A real-world networking module might use `DNS/`, `Firewall/`, `Routing/`. A module wrapping a REST API might use `Auth/`, `Users/`, `Reporting/`. The right scope names are the ones that make your module's structure readable at a glance. This is to help you organise your module.

---

## Part 3: Add the Enum

Create `source/enums/Launch/SpaceSuitType.ps1`:

```powershell
enum SpaceSuitType {
    Standard
    Lunar
    Martian
    Galactic
}
```

This enum will be used as a typed parameter in `Start-Blastoff`, providing both validation and tab completion for the suit type.

Commit:

```
feat: Added SpaceSuitType enum
```

---

## Part 4: Add the Validation Class

Create `source/validationClasses/Visitors/ValidateAlienFoodAttribute.ps1`:

```powershell
class ValidateAlienFoodAttribute : System.Management.Automation.ValidateArgumentsAttribute
{
    [void] Validate([object]$arguments,[System.Management.Automation.EngineIntrinsics]$engineIntrinsics)
    {
        $alienFood = $arguments -as [string]
        if ($alienFood -notin @('pizza','chocolate','tacos','Quantum Quinoa','Stellar Sushi')) {
            throw [System.Management.Automation.ValidationMetadataException] "Invalid alien food preference. Must be pizza, chocolate, tacos, Quantum Quinoa, or Stellar Sushi."
        }
    }
}
```

> **When to use a custom validator vs `[ValidateSet()]`**
>
> For a static list like this, PowerShell's built-in `[ValidateSet('pizza','chocolate','tacos')]`, or an enum like `SpaceSuitType` above, is normally the better choice. It is simpler, shorter, and gives you **tab completion for free**.
>
> Reach for a custom `ValidateArgumentsAttribute` when your validation logic cannot be expressed as a fixed set: reading valid values from a database or config file at runtime, cross-parameter conditions, complex regex with custom error messages, or any case requiring arbitrary code.
>
> The trade-off is that the PowerShell completion engine cannot introspect a custom `Validate()` method, so **tab completion is lost**. You can restore it by stacking `[ArgumentCompletions()]` (PS 7.0+) above your custom validator — the completions are offered by the shell, and the validation runs when the value is bound:
>
> ```powershell
> [ArgumentCompletions('pizza','chocolate','tacos','Quantum Quinoa','Stellar Sushi')]
> [ValidateAlienFoodAttribute()]
> [string]$FavoriteFood
> ```

> **Why validation classes have their own folder and output file**
>
> ModuleForge compiles validation classes into a separate `Validators.ps1` file, referenced in the module manifest via `ScriptsToProcess`. This runs the file in the caller's scope *before* the main module psm1 is even parsed.
>
> This matters because attributes like `[ValidateAlienFoodAttribute()]` on class properties and function parameters are resolved at **parse time**, not at runtime. If the type is not already defined when the psm1 parser encounters it, the module fails to load. `ScriptsToProcess` ensures the type exists first.

Commit:

```
feat: Added ValidateAlienFoodAttribute validation class
```

---

## Part 5: Add the Classes

Create `source/classes/Visitors/AlienVisitor.ps1`:

```powershell
class AlienVisitor {
    [string]$Name
    [string]$HomePlanet

    [ValidateAlienFoodAttribute()]
    [string]$FavoriteFood

    AlienVisitor([string]$Name, [string]$HomePlanet, [string]$FavoriteFood) {
        $this.Name = $Name
        $this.HomePlanet = $HomePlanet
        $this.FavoriteFood = $FavoriteFood
    }

    [string] GetIntroduction() {
        return "Greetings, Earthlings! I am $($this.Name) from planet $($this.HomePlanet). My favorite food here is $($this.FavoriteFood)."
    }

    hidden [string] GetReflectedIntroduction([AlienVisitor]$Ref) {
        return "Greetings, Earthlings! I am $($Ref.Name) from planet $($Ref.HomePlanet). My favorite food here is $($Ref.FavoriteFood)."
    }
}
```

`[ValidateAlienFoodAttribute()]` on the `$FavoriteFood` property is why the validation class had to be compiled first.

Create `source/classes/Visitors/GalacticAmbassador.ps1`:

```powershell
class GalacticAmbassador : AlienVisitor {
    [string]$Title

    GalacticAmbassador([string]$Name, [string]$HomePlanet, [string]$FavoriteFood, [string]$Title) : base([string]$Name, [string]$HomePlanet, [string]$FavoriteFood) {
        $this.Title = $Title
    }

    [string] GetIntroduction() {
        $BaseIntro = "Greetings, Earthlings! I am $($this.Name) from planet $($this.HomePlanet). My favorite food here is $($this.FavoriteFood).`n"
        return "$BaseIntro I am the Galactic Ambassador, holding the esteemed title of $($this.Title)."
    }
}
```

`GalacticAmbassador` inherits from `AlienVisitor` using `: base(...)` to call the parent constructor, and overrides `GetIntroduction()` to append the ambassador title.

> **Class inheritance and the dependency tree**
>
> `Get-MFDependencyTree` (covered in Part 10) detects dependencies by scanning for explicit type references like `[AlienVisitor]`. The inheritance declaration `class GalacticAmbassador : AlienVisitor` uses different syntax that the scanner does not recognise, so `GalacticAmbassador` will not appear as depending on `AlienVisitor` in the tree.
>
> This is a known limitation. Within a source folder, ModuleForge processes files alphabetically — `AlienVisitor.ps1` before `GalacticAmbassador.ps1` — which is why this works in practice. Naming base classes so they sort before derived classes is a good defensive convention.

Commit:

```
feat: Added AlienVisitor and GalacticAmbassador classes
```

---

## Part 6: Add the Private Function

Create `source/private/Visitors/Get-AlienVisitorWelcome.ps1`:

```powershell
function Get-AlienVisitorWelcome
{

    <#
        .SYNOPSIS
            Returns the introduction string for an AlienVisitor.

        .DESCRIPTION
            Calls the GetIntroduction() method on the provided AlienVisitor object and
            returns the result as a string. This is a private helper used internally by
            Get-GalacticReception and is not exported from the module.

        ------------
        .EXAMPLE
            $visitor = New-AlienVisitor -Name 'Zog' -HomePlanet 'Xenon-9' -FavoriteFood 'Quantum Quinoa'
            Get-AlienVisitorWelcome -Visitor $visitor

            #### DESCRIPTION
            Returns the introduction string for the specified AlienVisitor.

            #### OUTPUT
            Greetings, Earthlings! I am Zog from planet Xenon-9. My favorite food here is Quantum Quinoa.

        .NOTES
            Author: YourName

    #>

    [CmdletBinding()]
    [OutputType([string])]
    PARAM(
        #The AlienVisitor object to introduce
        [Parameter(Mandatory)]
        [AlienVisitor]$Visitor
    )
    begin{
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }

    process{
        Write-Verbose "Retrieving introduction for visitor: $($Visitor.Name) from $($Visitor.HomePlanet)"
        $Visitor.GetIntroduction()
    }

}
```

Functions in `source/private/` are compiled into the psm1 but their names are **not** added to `FunctionsToExport`. They are available within the module but invisible to module consumers — this is how you write helpers that support your public API without cluttering it.

Commit:

```
feat: Added Get-AlienVisitorWelcome private function
```

---

## Part 7: Add the Resource File

Create `source/resource/text.txt`:

```
Welcome to the Galactic Reception Centre!
All visitors must declare a favourite food from the approved list.
Unauthorised food preferences will result in immediate deportation.
```

The `resource/` and `bin/` folders are not compiled — ModuleForge copies them as-is to the module output directory alongside the psm1. This is the right place for anything your module needs to ship with its code: lookup tables, configuration templates, embedded assets, static data files.

Commit:

```
feat: Added resource file
```

---

## Part 8: Create the Public Functions

### Start-Blastoff

Create `source/functions/Launch/Start-Blastoff.ps1`. Note the `[SpaceSuitType]` typed parameter and the `Set-Alias` call at the bottom — `Set-Alias` at module scope is compiled into the psm1 verbatim and runs at module load time:

```powershell
function Start-Blastoff
{

    <#
        .SYNOPSIS
            Initiates a rocket launch countdown sequence.

        .DESCRIPTION
            Runs a countdown sequence for the named rocket, displays the astronaut suit type,
            and confirms a successful launch. Uses the SpaceSuitType enum to validate and
            describe the astronaut's suit selection.

        ------------
        .EXAMPLE
            Start-Blastoff -RocketName 'Starship Voyager' -AstronautSuit Lunar

            #### DESCRIPTION
            Launches Starship Voyager with astronauts in Lunar spacesuits.

            #### OUTPUT
            Countdown initiated for rocket 'Starship Voyager'...
            Astronauts are suiting up in their Lunar spacesuits.
            T-minus 3 seconds...
            T-minus 2 seconds...
            T-minus 1 seconds...
            Launch successful! 'Starship Voyager' has reached orbit!

        .NOTES
            Author: YourName

    #>

    [CmdletBinding()]
    [OutputType([string])]
    PARAM(
        #Name of the rocket to launch
        [Parameter(Mandatory)]
        [string]$RocketName,

        #Type of spacesuit the astronauts are wearing. Must be a valid SpaceSuitType enum value: Standard, Lunar, Martian, Galactic
        [Parameter(Mandatory)]
        [SpaceSuitType]$AstronautSuit
    )
    begin{
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }

    process{
        Write-Verbose "Initiating launch sequence for rocket: $RocketName"
        "Countdown initiated for rocket '$RocketName'..."
        "Astronauts are suiting up in their $AstronautSuit spacesuits."
        Write-Verbose "Beginning countdown"
        3..1 | ForEach-Object {
            "T-minus $_ seconds..."
            Start-Sleep -Milliseconds 200
        }
        Write-Verbose "Countdown complete, launching"
        "Launch successful! '$RocketName' has reached orbit!"
    }

}

Set-Alias -Name blastOff -Value Start-Blastoff
```

Commit:

```
feat: Added Start-Blastoff function
```

### New-AlienVisitor

Create `source/functions/Visitors/New-AlienVisitor.ps1`. Note `[ArgumentCompletions()]` stacked above `[ValidateAlienFoodAttribute()]` on the `$FavoriteFood` parameter:

```powershell
function New-AlienVisitor
{

    <#
        .SYNOPSIS
            Creates a new AlienVisitor object.

        .DESCRIPTION
            Constructs and returns an AlienVisitor instance with the specified name,
            home planet, and favourite food. FavoriteFood is validated against the
            known list of acceptable alien food preferences via ValidateAlienFoodAttribute.

        ------------
        .EXAMPLE
            New-AlienVisitor -Name 'Zog' -HomePlanet 'Xenon-9' -FavoriteFood 'Quantum Quinoa'

            #### DESCRIPTION
            Creates an AlienVisitor named Zog from Xenon-9 who enjoys Quantum Quinoa.

            #### OUTPUT
            An AlienVisitor object with Name, HomePlanet, and FavoriteFood properties populated.

        .NOTES
            Author: YourName

    #>

    [CmdletBinding()]
    [OutputType([AlienVisitor])]
    PARAM(
        #Name of the alien visitor
        [Parameter(Mandatory)]
        [string]$Name,

        #Home planet of the alien visitor
        [Parameter(Mandatory)]
        [string]$HomePlanet,

        #Favourite food of the alien visitor. Must be one of: pizza, chocolate, tacos, Quantum Quinoa, Stellar Sushi
        [Parameter(Mandatory)]
        [ArgumentCompletions('pizza','chocolate','tacos','Quantum Quinoa','Stellar Sushi')]
        [ValidateAlienFoodAttribute()]
        [string]$FavoriteFood
    )
    begin{
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }

    process{
        Write-Verbose "Creating AlienVisitor: $Name from $HomePlanet"
        $alien = [AlienVisitor]::new($Name, $HomePlanet, $FavoriteFood)
        Write-Verbose "AlienVisitor created successfully"
        $alien
    }

}
```

Commit:

```
feat: Added New-AlienVisitor function
```

### Get-GalacticAmbassador

Create `source/functions/Visitors/Get-GalacticAmbassador.ps1`:

```powershell
function Get-GalacticAmbassador
{

    <#
        .SYNOPSIS
            Creates a GalacticAmbassador and returns their introduction.

        .DESCRIPTION
            Instantiates a GalacticAmbassador object using the provided details and returns
            a formatted introduction string. All parameters have defaults so the function
            can be called with no arguments.

        ------------
        .EXAMPLE
            Get-GalacticAmbassador

            #### DESCRIPTION
            Creates the default GalacticAmbassador using built-in values.

            #### OUTPUT
            Greetings, Earthlings! I am Zarnak from planet Nebula-7. My favorite food here is Quantum Quinoa.
             I am the Galactic Ambassador, holding the esteemed title of Celestial Diplomat.

        .EXAMPLE
            Get-GalacticAmbassador -Name 'Vexor' -HomePlanet 'Andromeda-3' -FavoriteFood 'pizza' -Title 'Supreme Envoy'

            #### DESCRIPTION
            Creates a GalacticAmbassador with fully custom values.

            #### OUTPUT
            Greetings, Earthlings! I am Vexor from planet Andromeda-3. My favorite food here is pizza.
             I am the Galactic Ambassador, holding the esteemed title of Supreme Envoy.

        .NOTES
            Author: YourName

    #>

    [CmdletBinding()]
    [OutputType([string])]
    PARAM(
        #Name of the Galactic Ambassador
        [Parameter()]
        [string]$Name = 'Zarnak',

        #Home planet of the Galactic Ambassador
        [Parameter()]
        [string]$HomePlanet = 'Nebula-7',

        #Favourite food of the Galactic Ambassador. Must be one of: pizza, chocolate, tacos, Quantum Quinoa, Stellar Sushi
        [Parameter()]
        [ArgumentCompletions('pizza','chocolate','tacos','Quantum Quinoa','Stellar Sushi')]
        [ValidateAlienFoodAttribute()]
        [string]$FavoriteFood = 'Quantum Quinoa',

        #Diplomatic title held by the Ambassador
        [Parameter()]
        [string]$Title = 'Celestial Diplomat'
    )
    begin{
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }

    process{
        Write-Verbose "Creating GalacticAmbassador '$Name' from '$HomePlanet' with title '$Title'"
        $ambassador = [GalacticAmbassador]::new($Name, $HomePlanet, $FavoriteFood, $Title)
        Write-Verbose "Returning ambassador introduction"
        $ambassador.GetIntroduction()
    }

}
```

Commit:

```
feat: Added Get-GalacticAmbassador function
```

### Get-GalacticReception

Create `source/functions/Visitors/Get-GalacticReception.ps1`. This function depends on both `New-AlienVisitor` (another public function) and `Get-AlienVisitorWelcome` (the private function), making it the most connected piece in the module:

```powershell
function Get-GalacticReception
{

    <#
        .SYNOPSIS
            Welcomes an AlienVisitor with a formal reception greeting.

        .DESCRIPTION
            Passes an AlienVisitor to the internal Get-AlienVisitorWelcome function and returns
            the visitor's introduction string. If no visitor is provided, a default visitor
            named Zog from Xenon-9 is summoned automatically.

        ------------
        .EXAMPLE
            Get-GalacticReception

            #### DESCRIPTION
            Summons the default visitor Zog and returns their welcome greeting.

            #### OUTPUT
            Greetings, Earthlings! I am Zog from planet Xenon-9. My favorite food here is Quantum Quinoa.

        .EXAMPLE
            $visitor = New-AlienVisitor -Name 'Grok' -HomePlanet 'Nebula-7' -FavoriteFood 'Stellar Sushi'
            Get-GalacticReception -Visitor $visitor

            #### DESCRIPTION
            Welcomes a previously created AlienVisitor object.

            #### OUTPUT
            Greetings, Earthlings! I am Grok from planet Nebula-7. My favorite food here is Stellar Sushi.

        .NOTES
            Author: YourName

    #>

    [CmdletBinding()]
    [OutputType([string])]
    PARAM(
        #The AlienVisitor to welcome. If not provided, a default visitor named Zog from Xenon-9 is summoned
        [Parameter()]
        [AlienVisitor]$Visitor
    )
    begin{
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }

    process{
        if (-not $Visitor) {
            Write-Verbose "No visitor provided, summoning default visitor: Zog from Xenon-9"
            $Visitor = New-AlienVisitor -Name 'Zog' -HomePlanet 'Xenon-9' -FavoriteFood 'Quantum Quinoa'
        } else {
            Write-Verbose "Visitor provided: $($Visitor.Name) from $($Visitor.HomePlanet)"
        }
        Write-Verbose "Passing visitor to reception handler"
        Get-AlienVisitorWelcome -Visitor $Visitor
    }

}
```

Commit:

```
feat: Added Get-GalacticReception function
```

### Get-WelcomeMessage

Create `source/functions/Visitors/Get-WelcomeMessage.ps1`. This function reads from the bundled resource file and demonstrates the `$mockPsScriptRoot` pattern:

```powershell
function Get-WelcomeMessage
{

    <#
        .SYNOPSIS
            Returns the welcome message for the Galactic Reception Centre.

        .DESCRIPTION
            Reads the welcome message from the bundled text.txt resource file and returns
            it as a string. Demonstrates how module resource files are accessed via
            $PSScriptRoot, which resolves to the module directory in the compiled module
            and must be overridden with $mockPsScriptRoot when testing pre-build.

        ------------
        .EXAMPLE
            Get-WelcomeMessage

            #### DESCRIPTION
            Returns the welcome message bundled with the module.

            #### OUTPUT
            Welcome to the Galactic Reception Centre!
            All visitors must declare a favourite food from the approved list.
            Unauthorised food preferences will result in immediate deportation.

        .NOTES
            Author: YourName

    #>

    [CmdletBinding()]
    [OutputType([string])]
    PARAM()
    begin{
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        if($mockPsScriptRoot)
        {
            Write-Warning 'Using $mockPsScriptRoot for resource path. This should only be done for testing.'
            $resourceFolder = Join-Path $mockPsScriptRoot 'resource'
        }
        else
        {
            $resourceFolder = Join-Path $PSScriptRoot 'resource'
        }

        $resourceFile = Join-Path $resourceFolder 'text.txt'

        if(-not (Test-Path $resourceFile))
        {
            throw "Get-WelcomeMessage: unable to find resource file at: $resourceFile"
        }
    }

    process{
        Write-Verbose "Reading welcome message from: $resourceFile"
        Get-Content $resourceFile -Raw
    }

}
```

> **The `$mockPsScriptRoot` pattern**
>
> In the compiled module, `$PSScriptRoot` in a function's `begin{}` block resolves to the module directory, which sits directly alongside `resource/`. This is correct.
>
> The problem is testing. When Pester dot-sources a function file, `$PSScriptRoot` resolves to the *source function's own directory* — nowhere near the source root where `resource/` actually lives.
>
> The fix is to check for a local variable named `$mockPsScriptRoot` before falling back to `$PSScriptRoot`. Because PowerShell functions resolve variables by walking up the call stack, setting `$mockPsScriptRoot` in a Pester `BeforeAll` block makes it visible to the function's `begin{}` when the function is called within that scope.
>
> Set it in the test's outer `BeforeAll` — before dot-sourcing the function — and remove it in `AfterAll`:
>
> ```powershell
> BeforeAll{
>     $currentPath    = $(get-location).path
>     $sourcePath     = join-path -path $currentPath -childPath 'source'
>     $mockPsScriptRoot = $sourcePath   # must be set before dot-sourcing
>     . $PSCommandPath.Replace('.Tests.ps1','.ps1')
> }
> AfterAll{
>     Remove-Variable mockPsScriptRoot -ErrorAction Ignore
> }
> ```

Commit:

```
feat: Added Get-WelcomeMessage function
```

---

## Part 9: Create the Pester Tests

Create a `.Tests.ps1` file alongside each function in its subfolder. The key pattern across all test files is the **ordered dependency-loading `BeforeAll`** block.

Pester runs individual source files in isolation — unlike the built module where everything is compiled in order into a single psm1, a test must manually load every type and function the subject depends on before dot-sourcing the function under test. The order must mirror the ModuleForge compilation order.

> **PSScriptAnalyzer in the CI workflow**
>
> The PSScriptAnalyzer GitHub Actions workflow runs only against function source files and excludes the `PSAvoidTrailingWhitespace` rule. Test files are not analysed by CI. The `PSUseDeclaredVarsMoreThanAssignments` false positive discussed below will not appear in your pull request analysis.
>
> Adding the suppression attribute is still good practice for a clean IDE experience.

### Start-Blastoff.Tests.ps1

Create `source/functions/Launch/Start-Blastoff.Tests.ps1`. This function has no type dependencies, so the `BeforeAll` is minimal:

```powershell
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{
    $currentPath = $(get-location).path
    $sourcePath  = join-path -path $currentPath -childPath 'source'
    $dependencies = [ordered]@{
        enums = @('Launch/SpaceSuitType.ps1')
    }

    $dependencies.GetEnumerator().ForEach{
        $dir = join-path $sourcePath $_.Key
        $_.Value.ForEach{
            $item = join-path $dir $_
            if(test-path $item){ . $item }else{ write-warning "Dependency not found: $item" }
        }
    }

    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
}

Describe "Start-Blastoff" {

    Context "Output content" {
        BeforeAll {
            $output = Start-Blastoff -RocketName 'Starship Voyager' -AstronautSuit Lunar
        }

        It "Returns multiple output lines" {
            $output.Count | Should -BeGreaterThan 1
        }

        It "Output contains the countdown initiation message" {
            $output | Should -Contain "Countdown initiated for rocket 'Starship Voyager'..."
        }

        It "Output contains the spacesuit type" {
            $output | Should -Contain "Astronauts are suiting up in their Lunar spacesuits."
        }

        It "Output contains the launch confirmation" {
            $output | Should -Contain "Launch successful! 'Starship Voyager' has reached orbit!"
        }
    }

    Context "Alias" {
        It "blastOff alias resolves to Start-Blastoff" {
            (Get-Alias -Name 'blastOff').ResolvedCommandName | Should -Be 'Start-Blastoff'
        }
    }

    Context "Validation" {
        It "Throws on an invalid AstronautSuit value" {
            { Start-Blastoff -RocketName 'Test' -AstronautSuit 'InvalidSuit' } | Should -Throw
        }
    }

}
```

Commit:

```
test: Added Pester tests for Start-Blastoff
```

### New-AlienVisitor.Tests.ps1

Create `source/functions/Visitors/New-AlienVisitor.Tests.ps1`. The `[ordered]` hashtable ensures dependencies load in the correct sequence:

```powershell
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{
    $currentPath = $(get-location).path
    $sourcePath  = join-path -path $currentPath -childPath 'source'
    $dependencies = [ordered]@{
        validationClasses = @('Visitors/ValidateAlienFoodAttribute.ps1')
        classes           = @('Visitors/AlienVisitor.ps1')
    }

    $dependencies.GetEnumerator().ForEach{
        $dir = join-path $sourcePath $_.Key
        $_.Value.ForEach{
            $item = join-path $dir $_
            if(test-path $item){ . $item }else{ write-warning "Dependency not found: $item" }
        }
    }

    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
}

Describe "New-AlienVisitor" {

    Context "Object creation" {
        BeforeAll {
            $alien = New-AlienVisitor -Name 'Zog' -HomePlanet 'Xenon-9' -FavoriteFood 'Quantum Quinoa'
        }

        It "Returns a non-null result" {
            $alien | Should -Not -BeNullOrEmpty
        }

        It "Returns an object of type AlienVisitor" {
            $alien.GetType().Name | Should -Be 'AlienVisitor'
        }

        It "Name property is set correctly" {
            $alien.Name | Should -BeExactly 'Zog'
        }

        It "HomePlanet property is set correctly" {
            $alien.HomePlanet | Should -BeExactly 'Xenon-9'
        }

        It "FavoriteFood property is set correctly" {
            $alien.FavoriteFood | Should -BeExactly 'Quantum Quinoa'
        }
    }

    Context "Validation" {
        It "Throws on an invalid FavoriteFood value" {
            { New-AlienVisitor -Name 'Zog' -HomePlanet 'Xenon-9' -FavoriteFood 'broccoli' } | Should -Throw
        }
    }

}
```

Commit:

```
test: Added Pester tests for New-AlienVisitor
```

### Get-GalacticAmbassador.Tests.ps1

Create `source/functions/Visitors/Get-GalacticAmbassador.Tests.ps1`:

```powershell
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{
    $currentPath = $(get-location).path
    $sourcePath  = join-path -path $currentPath -childPath 'source'
    $dependencies = [ordered]@{
        validationClasses = @('Visitors/ValidateAlienFoodAttribute.ps1')
        classes           = @('Visitors/AlienVisitor.ps1','Visitors/GalacticAmbassador.ps1')
    }

    $dependencies.GetEnumerator().ForEach{
        $dir = join-path $sourcePath $_.Key
        $_.Value.ForEach{
            $item = join-path $dir $_
            if(test-path $item){ . $item }else{ write-warning "Dependency not found: $item" }
        }
    }

    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
}

Describe "Get-GalacticAmbassador" {

    Context "Default parameters" {
        BeforeAll {
            $result = Get-GalacticAmbassador
        }

        It "Returns a non-empty result" {
            $result | Should -Not -BeNullOrEmpty
        }

        It "Returns a string" {
            $result | Should -BeOfType [string]
        }

        It "Output contains the default ambassador name" {
            $result | Should -Match "Zarnak"
        }

        It "Output contains the default home planet" {
            $result | Should -Match "Nebula-7"
        }

        It "Output contains the default title" {
            $result | Should -Match "Celestial Diplomat"
        }
    }

    Context "Custom parameters" {
        BeforeAll {
            $result = Get-GalacticAmbassador -Name 'Vexor' -HomePlanet 'Andromeda-3' -FavoriteFood 'pizza' -Title 'Supreme Envoy'
        }

        It "Output contains the custom ambassador name" {
            $result | Should -Match "Vexor"
        }

        It "Output contains the custom home planet" {
            $result | Should -Match "Andromeda-3"
        }

        It "Output contains the custom title" {
            $result | Should -Match "Supreme Envoy"
        }
    }

    Context "Validation" {
        It "Throws on an invalid FavoriteFood value" {
            { Get-GalacticAmbassador -FavoriteFood 'broccoli' } | Should -Throw
        }
    }

}
```

Commit:

```
test: Added Pester tests for Get-GalacticAmbassador
```

### Get-GalacticReception.Tests.ps1

Create `source/functions/Visitors/Get-GalacticReception.Tests.ps1`. This test loads the most dependencies — the full Visitors chain — to mirror what the compiled module provides automatically:

```powershell
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{
    $currentPath = $(get-location).path
    $sourcePath  = join-path -path $currentPath -childPath 'source'
    $dependencies = [ordered]@{
        validationClasses = @('Visitors/ValidateAlienFoodAttribute.ps1')
        classes           = @('Visitors/AlienVisitor.ps1','Visitors/GalacticAmbassador.ps1')
        private           = @('Visitors/Get-AlienVisitorWelcome.ps1')
        functions         = @('Visitors/New-AlienVisitor.ps1')
    }

    $dependencies.GetEnumerator().ForEach{
        $dir = join-path $sourcePath $_.Key
        $_.Value.ForEach{
            $item = join-path $dir $_
            if(test-path $item){ . $item }else{ write-warning "Dependency not found: $item" }
        }
    }

    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
}

Describe "Get-GalacticReception" {

    Context "With a provided visitor" {
        BeforeAll {
            $visitor = New-AlienVisitor -Name 'Grok' -HomePlanet 'Nebula-7' -FavoriteFood 'Stellar Sushi'
            $result  = Get-GalacticReception -Visitor $visitor
        }

        It "Returns a non-empty result" {
            $result | Should -Not -BeNullOrEmpty
        }

        It "Returns the correct greeting for the provided visitor" {
            $result | Should -Be "Greetings, Earthlings! I am Grok from planet Nebula-7. My favorite food here is Stellar Sushi."
        }
    }

    Context "Without a provided visitor" {
        BeforeAll {
            $result = Get-GalacticReception
        }

        It "Returns a non-empty result" {
            $result | Should -Not -BeNullOrEmpty
        }

        It "Summons the default visitor Zog" {
            $result | Should -Be "Greetings, Earthlings! I am Zog from planet Xenon-9. My favorite food here is Quantum Quinoa."
        }
    }

}
```

Commit:

```
test: Added Pester tests for Get-GalacticReception
```

### Get-WelcomeMessage.Tests.ps1

Create `source/functions/Visitors/Get-WelcomeMessage.Tests.ps1`. This is the only test that uses `$mockPsScriptRoot` — note it is set before dot-sourcing the function and cleaned up in `AfterAll`. Also note that Pester's `$TestDrive` provides a clean empty temporary directory, used here to exercise the missing-file error path:

```powershell
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSScriptAnalyzer cannot see Pester BeforeAll scoping')]
param()

BeforeAll{
    $currentPath  = $(get-location).path
    $sourcePath   = join-path -path $currentPath -childPath 'source'
    $mockPsScriptRoot = $sourcePath

    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
}

AfterAll{
    Remove-Variable mockPsScriptRoot -ErrorAction Ignore
}

Describe "Get-WelcomeMessage" {

    Context "Resource file access" {
        BeforeAll {
            $result = Get-WelcomeMessage
        }

        It "Returns a non-empty result" {
            $result | Should -Not -BeNullOrEmpty
        }

        It "Returns a string" {
            $result | Should -BeOfType [string]
        }

        It "Output contains the welcome heading" {
            $result | Should -Match "Galactic Reception Centre"
        }
    }

    Context "Missing resource file" {
        It "Throws when the resource file cannot be found" {
            $mockPsScriptRoot = (Get-Item $TestDrive).FullName
            { Get-WelcomeMessage } | Should -Throw
        }
    }

}
```

> **Coverage gap for the production path**
>
> The `else` branch in `Get-WelcomeMessage`'s `begin{}` block (`$resourceFolder = Join-Path $PSScriptRoot 'resource'`) will never be exercised by tests. Tests always take the `$mockPsScriptRoot` path. This line will appear as a missed command in the coverage report.
>
> This is intentional and acceptable. The production path is verified when you build and import the module. Do not contort your test structure trying to cover it.

Commit:

```
test: Added Pester tests for Get-WelcomeMessage
```

---

## Part 10: Explore the Dependency Tree

Before opening a pull request, run `Get-MFDependencyTree` to see how ModuleForge understands your module's internal structure:

```powershell
Get-MFDependencyTree
```

```
.\source\functions\Visitors\Get-GalacticAmbassador.ps1
     >--DEPENDS-ON--> .\source\classes\Visitors\GalacticAmbassador.ps1
.\source\functions\Visitors\Get-GalacticReception.ps1
     >--DEPENDS-ON--> .\source\private\Visitors\Get-AlienVisitorWelcome.ps1
         >--DEPENDS-ON--> .\source\classes\Visitors\AlienVisitor.ps1
     >--DEPENDS-ON--> .\source\functions\Visitors\New-AlienVisitor.ps1
         >--DEPENDS-ON--> .\source\classes\Visitors\AlienVisitor.ps1
         >--DEPENDS-ON--> .\source\validationClasses\Visitors\ValidateAlienFoodAttribute.ps1
     >--DEPENDS-ON--> .\source\classes\Visitors\AlienVisitor.ps1
.\source\functions\Visitors\New-AlienVisitor.ps1
     >--DEPENDS-ON--> .\source\classes\Visitors\AlienVisitor.ps1
     >--DEPENDS-ON--> .\source\validationClasses\Visitors\ValidateAlienFoodAttribute.ps1
.\source\functions\Launch\Start-Blastoff.ps1
     >--DEPENDS-ON--> .\source\enums\Launch\SpaceSuitType.ps1
.\source\private\Visitors\Get-AlienVisitorWelcome.ps1
     >--DEPENDS-ON--> .\source\classes\Visitors\AlienVisitor.ps1
```

`Get-GalacticReception` is the most connected function — it chains through a private function, another public function, and the base class directly. The tree makes the full chain visible at a glance and is useful when deciding which dependencies to load in a test's `BeforeAll`.

Note that `GalacticAmbassador.ps1` does not appear as depending on `AlienVisitor.ps1` even though it inherits from it. This is the scanner limitation described in Part 5.

To generate a Mermaid diagram suitable for embedding in your `README.md`:

```powershell
Get-MFDependencyTree -OutputType MermaidMarkdown
```

Copy the output into your README inside a fenced code block tagged `mermaid`. GitHub renders it automatically as a dependency diagram.

---

## Part 11: Pull Request and Release

Push your changes to a feature branch:

```
feature/astro-cmdlets
```

Open a pull request. Two GitHub Actions workflows run automatically as PR checks:

- **PSScriptAnalyzer** — analyses your function source files and posts a lint report as a PR comment
- **Pester** — runs your test suite and posts results as a PR comment

After merging to `main`, dispatch the **Build and Release** workflow from the Actions tab. Choose your version increment type and whether this is a stable or prerelease build.

The build automatically derives the next version from git tags, generates a changelog from your commit history (this is why small, well-prefixed commits matter), compiles the module, copies the `resource/` folder to the output, appends SHA256 checksums to the release notes, and publishes the module to your repository's **GitHub Packages** feed.

---

## Part 12: Install from GitHub Packages

Your module is published as a NuGet package to GitHub Packages, which is private to your repository. To install it using PSResourceGet you need a **Classic Personal Access Token** with `read:packages` scope, generated from your GitHub account settings.

Register the GitHub Packages feed as a PSResource repository using the credential of your choice. The two common approaches are an inline credential or SecretManagement:

**Inline credential:**

```powershell
$token      = 'your-github-pat'
$credential = [System.Management.Automation.PSCredential]::new(
    'your-github-username',
    (ConvertTo-SecureString $token -AsPlainText -Force)
)

Register-PSResourceRepository `
    -Name       'MyGitHubPackages' `
    -Uri        'https://nuget.pkg.github.com/your-github-username/index.json' `
    -Trusted    $true `
    -Credential $credential
```

**SecretManagement:**

```powershell
$credentialInfo = [Microsoft.PowerShell.PSResourceGet.UtilClasses.PSCredentialInfo]::new(
    'VaultName',
    'SecretName'
)

Register-PSResourceRepository `
    -Name           'MyGitHubPackages' `
    -Uri            'https://nuget.pkg.github.com/your-github-username/index.json' `
    -Trusted        $true `
    -CredentialInfo $credentialInfo
```

Once registered, install the module:

```powershell
Install-PSResource -Name 'AstroCmdlets' -Repository 'MyGitHubPackages'
```

> **Note:** PSResourceGet does not support wildcard searching from NuGet v3 APIs. You must know the exact module name. `Find-PSResource -Repository 'MyGitHubPackages'` will not return results.
