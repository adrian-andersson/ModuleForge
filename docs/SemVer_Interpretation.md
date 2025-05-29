# My interpretation of how to use SemVer with PowerShell modules

## Definitions

### Major

A change to a function that is likely to break backwards compatibility and existing scripts

#### Major Change Examples

- Changing a parameter to be mandatory
- Changing a parameter name
- Breaking change to the output object
- Rewrite or refactor

### Minor

Introduction of a new function that does not significantly alter the result output object or parameters of an existing function

#### Examples

- Moving a block of code or subfunction into a separate function and calling that from the primary function
- Creation of an entirely new function that does not alter the result output object or parameters of existing functions
- Change to input validation of a parameter

### Patch

No change to parameters or outputs, only code fixes and optimizations.

#### Patch Examples

- Bug fixes
- changes to any stream except the output stream
  - I.e. changes to the Error, Verbose, Debug, Information and Warning output
- Code optimisations that do not change the returned output or input parameters

### prerelease

Test version of any of the above.

Since PSGallery only supports SemVer V1, considerations must be made in how we version our preReleases. Since we cannot use the SemVer V2 Build version with our preRelease Tag [As per the Documentation here](https://learn.microsoft.com/en-us/powershell/gallery/concepts/module-prerelease-support?view=powershellget-3.x#identifying-a-module-version-as-a-prerelease).

Specifically these points:

- Only SemVer v1.0.0 prerelease strings are supported at this time. prerelease string must not contain either period or + [.+], which are allowed in SemVer 2.0.
- The prerelease string may contain only ASCII alphanumerics [0-9A-Za-z-]. It is a best practice to begin the prerelease string with an alpha character, as it will be easier to identify that this is a prerelease version when scanning a list of packages.
- prerelease string may only be specified when the ModuleVersion is 3 segments for Major.Minor.Build. This aligns with SemVer v1.0.0.

As such, care must be taken to ensure that newer preRelease versions are not incorrectly ordered, and that we are adhereing to something that is compatible. For example:

`1.0.0-prev2` will order more recently than than `1.0.0-prev10`, even though from a readability stand-point v2 is much lower than v10.

```PowerShell

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

 > Special Note o prerelease label casing: There is a small, obsucre bug in PSResourceGet (Issue:Status: #1787) that occurs if uppercase is used in prerelease tags. I would prefer to use upper-case pre as I think it looks a little better, but to avoid this bug, I will stick to lower-case labels, and recommend for custom labels that others do the same.

As such, in order to clearly identify correct versions whilst maintaining simplicity and compatibility with SEMVER v1 will be to use the following formatting:

`{MAJOR}.{MINOR}.{PATCH}-{preReleaseTag}v{XXX}`

- The default preRelease Tag will be pre
  - See above note on casing
  - This can be over-written if desired
  - The use of standards such as ALPHA,BETA,RC etc seem less prudent for PowerShell modules, the important part is identifying whether something should be considered stable or a preview.
  - If using proper standards makes sense for your use-case, please do so
- The XXX will be a three digit number with leading zeroes
  - I.e. 001 through to 999
  - In the unlikely event that your prereleases exceed 999 versions for a single Major,Minor,Patch level, you should consider bumping the patch version and skipping a release.

### Example Version List

Here's a quick PowerShell snippet to show how this may work in practice

```PowerShell
$versionStrings = @(
    '1.0.0-prev001' #The first build
    '1.0.0-prev002' #Tested and fixed some bugs
    '1.0.1' #First actual release after testing
    '1.0.2-prev001' #Optimisation Rework
    '1.0.2' #Second Release
    '1.1.0-prev001' #New function added
    '1.1.0-prev002' #New function bugfixed
    '1.1.0' #Third Release
    '1.1.1-prev001' #Bugfix Pass
    '1.1.1-prev002' #Bugfix Pass 2
    '1.1.1' #Fourth Release
    '1.1.2-prev001' #Optimisation Pass
    '1.1.2' #Fifth Release
    '1.2.0-prev001' #Change to Validators in a function
    '1.2.0' #Sixth Release
    '2.0.0-prev001' #Changes to Return for existing Functions
    '2.0.0-prev002' #Bugfix for previous
    '2.0.0-prev003' #Bugfix for previous
    '2.0.0-prev004' #Optimisation
    '2.0.0-prev005' #More Optimisation
    '2.0.0' #Seventh Release
)
$versions = $versionStrings.foreach{[semver]::New($_)}

#All Versions sorted 
$versions|sort-object

#Current Latest
($versions|sort-object -descending|select -first 1)

```
