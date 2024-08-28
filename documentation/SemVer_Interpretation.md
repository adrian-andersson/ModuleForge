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

### Prerelease

Test version of any of the above.

Since PSGallery only supports SemVer V1, considerations must be made in how we version our PreReleases. Since we cannot use the SemVer V2 Build version with our PreRelease Tag [As per the Documentation here](https://learn.microsoft.com/en-us/powershell/gallery/concepts/module-prerelease-support?view=powershellget-3.x#identifying-a-module-version-as-a-prerelease).

Specifically these points:

- Only SemVer v1.0.0 prerelease strings are supported at this time. Prerelease string must not contain either period or + [.+], which are allowed in SemVer 2.0.
- The Prerelease string may contain only ASCII alphanumerics [0-9A-Za-z-]. It is a best practice to begin the Prerelease string with an alpha character, as it will be easier to identify that this is a prerelease version when scanning a list of packages.
- Prerelease string may only be specified when the ModuleVersion is 3 segments for Major.Minor.Build. This aligns with SemVer v1.0.0.

As such, care must be taken to ensure that newer preRelease versions are not incorrectly ordered, and that we are adhereing to something that is compatible. For example:

`1.0.0-PREv2` will order more recently than than `1.0.0-PREv10`, even though from a readability stand-point v2 is much lower than v10.

```PowerShell

$versionStrings = @(
    '1.0.0-PREv1'
    '1.0.0-PREv2'
    '1.0.0-PREv3'
    '1.0.0-PREv4'
    '1.0.0-PREv5'
    '1.0.0-PREv6'
    '1.0.0-PREv7'
    '1.0.0-PREv8'
    '1.0.0-PREv9'
    '1.0.0-PREv10'
    '1.0.0-PREv11'
    '1.0.0-PREv12'
)

$versions = $versionStrings.foreach{[semver]::New($_)}
$versions|sort-object

```

As such, in order to clearly identify correct versions whilst maintaining simplicity and compatibility with SEMVER v1 will be to use the following formatting:

`{MAJOR}.{MINOR}.{PATCH}-{PreReleaseTag}v{XXX}`

- The default PreRelease Tag will be PRE
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
    '1.0.0-PREv001' #The first build
    '1.0.0-PREv002' #Tested and fixed some bugs
    '1.0.1' #First actual release after testing
    '1.0.2-PREv001' #Optimisation Rework
    '1.0.2' #Second Release
    '1.1.0-PREv001' #New function added
    '1.1.0-PREv002' #New function bugfixed
    '1.1.0' #Third Release
    '1.1.1-PREv001' #Bugfix Pass
    '1.1.1-PREv002' #Bugfix Pass 2
    '1.1.1' #Fourth Release
    '1.1.2-PREv001' #Optimisation Pass
    '1.1.2' #Fifth Release
    '1.2.0-PREv001' #Change to Validators in a function
    '1.2.0' #Sixth Release
    '2.0.0-PREv001' #Changes to Return for existing Functions
    '2.0.0-PREv002' #Bugfix for previous
    '2.0.0-PREv003' #Bugfix for previous
    '2.0.0-PREv004' #Optimisation
    '2.0.0-PREv005' #More Optimisation
    '2.0.0' #Seventh Release
)
$versions = $versionStrings.foreach{[semver]::New($_)}

#All Versions sorted 
$versions|sort-object

#Current Latest
($versions|sort-object -descending|select -first 1)

```
