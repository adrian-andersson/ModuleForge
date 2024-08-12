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

### Patch

No change to parameters or outputs, only code fixes and optimizations.

#### Patch Examples

- Bug fixes
- changes to any stream except the output stream
  - I.e. changes to the Error, Verbose, Debug, Information and Warning output
- Code optimisations that do not change the returned output or input parameters

### Prerelease

Test version of any of the above.

### Example Version List

Here's a quick PowerShell snippet to show how this works in practice

```PowerShell

$versionStrings = @(
    '1.0.0-prerelease.1'
    '1.0.0-prerelease.2'
    '1.0.0'
    '1.0.1-prerelease.1'
    '1.0.1'
    '1.0.2-prerelease.1'
    '1.0.2'
    '1.1.0-prerelease.1'
    '1.1.0-prerelease.2'
    '1.1.0'
    '1.1.1-prerelease.1'
    '1.1.1-prerelease.2'
    '1.1.1'
    '1.1.2-prerelease.1'
    '1.1.2'
    '1.2.0-prerelease.1'
    '1.2.0'
    '2.0.0-prerelease.1'
    '2.0.0-prerelease.2'
    '2.0.0-prerelease.3'
    '2.0.0-prerelease.4'
    '2.0.0-prerelease.5'
    '2.0.0'
)

$versions = $versionStrings.foreach{[semver]::New($_)}

$versions|sort-object

$versions|Sort-object -descending

$currVer = $versions|sort-object -descending|select -first 1
$currVer
```
