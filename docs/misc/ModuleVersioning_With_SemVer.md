# Module Versioning with SemVer

Semantic Versioning (SemVer) is a versioning convention that communicates the nature of changes through the version number itself — `MAJOR.MINOR.PATCH`. The full specification is at [semver.org](https://semver.org/). The following describes how those principles are applied in the context of PowerShell modules and ModuleForge specifically, including the constraints imposed by PSGallery's SemVer V1 support.

SemVer also defines the concept of a prerelease version — an explicitly unstable build that precedes a stable release. For PowerShell modules this is particularly valuable in a healthy SDLC: prerelease versions allow changes to be built, published, and validated in real environments before being promoted to stable. This decouples the act of building from the act of releasing, giving teams the ability to iterate and test without risking disruption to anyone consuming the stable version. A prerelease version extends the standard `MAJOR.MINOR.PATCH` format with a label — for example `1.1.0-prev001` signals a work-in-progress build toward what will eventually become `1.1.0`.

## Definitions

### Major

A change to a function that is likely to break backwards compatibility and existing scripts

#### Major Change Examples

- Changing a parameter to be mandatory
- Changing a parameter name without an alias
- Breaking change to the output object
- Rewrite or refactor

### Minor

Introduction of new functionality or non-breaking changes to existing functions — no backwards compatibility impact.

#### Minor Change Examples

- New function added
- New optional parameter added
- Non-breaking change to function output
- Parameter renamed with a backwards-compatible alias
- Moving a block of code or subfunction into a separate function and calling that from the primary function
- Change to input validation of a parameter

### Patch

No change to parameters or outputs, only code fixes and optimizations.

#### Patch Examples

- Bug fixes
- Stream output changes (Verbose, Warning, Error, Information, Debug) — any stream except the output stream
- Performance or style improvements that do not change returned output or input parameters
- Test updates or additions

### Prerelease

A prerelease is a test build of a Major, Minor, or Patch change — used to validate changes before committing to a stable release. In the PR template this maps to the **PreRelease series** release intent.

Use prerelease versions when:

- Testing a change across one or more builds before promoting to stable
- Iterating on a feature that isn't ready to ship
- Sharing a work-in-progress build for review or feedback without affecting the stable version

Prereleases are published to Artifacts feeds but are excluded from stable listings with both `Find-Module` and `Find-PsResource` (And their install equivalent) functions. They can still be found and installed explicitly with `-AllowPrerelease`.

#### PSGallery Compatibility and Version Ordering

PSGallery only supports SemVer V1, which imposes constraints on how prerelease strings are formed. The SemVer V2 build metadata syntax is not supported. [Full details in the PSGallery documentation](https://learn.microsoft.com/en-us/powershell/gallery/concepts/module-prerelease-support?view=powershellget-3.x#identifying-a-module-version-as-a-prerelease).

The key constraints are:

- Prerelease strings must contain only ASCII alphanumerics (`[0-9A-Za-z-]`) — no periods or `+`
- The version must be three segments (`Major.Minor.Patch`) when a prerelease string is present
- It is best practice to begin the prerelease string with an alpha character

A further consequence of SemVer V1 is that version ordering is lexicographic, not numeric. Care must be taken to ensure newer prerelease versions are not incorrectly ordered. For example:

`1.0.0-prev2` will order more recently than than `1.0.0-prev10`, even though from a readability stand-point v2 is much lower than v10.

```powershell

$versionStrings = @(
    '1.0.0-prev1'
    '1.0.0-prev2'
    '1.0.0-prev3'
    '1.0.0-prev4'
    '1.0.0-prev5'
    '1.0.0-prev6'
    '1.0.0-prev7'
    '1.0.0-prev8'
    '1.0.0-prev9'
    '1.0.0-prev10'
    '1.0.0-prev11'
    '1.0.0-prev12'
)

$versions = $versionStrings.foreach{[semver]::New($_)}
$versions|sort-object

```

Here is a table that helps demonstrate the results of the above:

|version|Order|Should be|
|-|-|-|
|1.0.0-prev1|✅ 1st| 1st|
|1.0.0-prev10|❌ 2nd|10th|
|1.0.0-prev11|❌ 3rd|11th|
|1.0.0-prev2|❌ 4th|2nd|
|1.0.0-prev3|❌ 4th|3rd|



In order to clearly identify correct versions whilst maintaining simplicity and compatibility with SemVer V1, the following format is used and enforced by `Get-MFNextSemver`:

`{MAJOR}.{MINOR}.{PATCH}-{preReleaseTag}v{XXX}`

- `{preReleaseTag}` defaults to `pre` — see [Prerelease Label](#prerelease-label) below
- `{XXX}` is a three-digit zero-padded counter, i.e. `001` through `999`
  - A fresh prerelease always starts at `v001`
  - In the unlikely event that prereleases for a single Major.Minor.Patch exceed 999, bump the patch version and skip a release
- The `v` separator between the label and counter is intentional — it aids readability and distinguishes the counter from the label itself

The use of standards such as `ALPHA`, `BETA`, `RC` is less common in PowerShell modules, but is supported. The important distinction is simply stable vs preview.

#### Prerelease Label

The default prerelease label used by `Get-MFNextSemver` is `pre` (lowercase). This produces version strings in the form `1.0.0-prev001`.

The label is lowercase by design. There is a known bug in PSResourceGet where uppercase characters in prerelease tags cause incorrect behaviour when resolving or publishing to certain feeds including Azure DevOps Artifacts. Keeping labels lowercase avoids this entirely.

The label can be overridden via the `-prereleaseLabel` parameter on `Get-MFNextSemver`, but lowercase is strongly recommended regardless of what label is chosen.

For how versioning connects to the build and release pipeline, see [Commit Strategy and PR Process](./CommitStrategy_And_PRProcess.md).

### Example Version List

Here's a quick PowerShell snippet to show how this may work in practice

```powershell
$versionStrings = @(
    '1.0.0-prev001' #The first build
    '1.0.0-prev002' #Tested and fixed some bugs
    '1.0.0' #First stable release
    '1.0.1-prev001' #Post-launch patch
    '1.0.1' #Second Release
    '1.0.2-prev001' #Optimisation Rework
    '1.0.2' #Third Release
    '1.1.0-prev001' #New function added
    '1.1.0-prev002' #New function bugfixed
    '1.1.0' #Fourth Release
    '1.1.1-prev001' #Bugfix Pass
    '1.1.1-prev002' #Bugfix Pass 2
    '1.1.1' #Fifth Release
    '1.1.2-prev001' #Optimisation Pass
    '1.1.2' #Sixth Release
    '1.2.0-prev001' #Change to Validators in a function
    '1.2.0' #Seventh Release
    '2.0.0-prev001' #Changes to Return for existing Functions
    '2.0.0-prev002' #Bugfix for previous
    '2.0.0-prev003' #Bugfix for previous
    '2.0.0-prev004' #Optimisation
    '2.0.0-prev005' #More Optimisation
    '2.0.0' #Eighth Release
)
$versions = $versionStrings.foreach{[semver]::New($_)}

#All Versions sorted 
$versions|sort-object

#Current Latest
($versions|sort-object -descending|select -first 1)

```
