# Human in the loop

A more thorough and encompassing review of ModuleForge to ensure design principles are surviving multiple AI contributions

## Reasoning

Since early 2026, I've been using more and more AI-assisted coding. Whilst individual items get reviewed each commit and PR, I deemed it a good idea for code quality and project consistency to review the whole project end to end.

## Method

Human Eyeball 1.0

- Go through Source Folder
- Check each subfolder 1-by-1
- Read Function files first, check for code artefacts, check style, check parameter names and verbosity make sense. Check inline help
- Read test files, ensure they follow the expected BeforeAll, clean env checks etc, check they make sense

## Review details

Date: 2026-11-20
By: Adrian.Andersson
MFVersion: 1.4.1-prerelease series

## Findings

- GitHub workflows are good
  - Note that for ModuleForge, it runs ProjectRules from source/scripts. Compare to what the scaffold runs
  - Git scaffold runs from scripts folder. Good compromise
  - Azure DevOps scaffold is the same. Good
  - Other parts of the scaffold look appropriate
- Build
  - Functions:
    - Mostly unchanged and hand-coded by me
    - No concerns
  - Tests:
    - Tests look good. Readable in spite of complexity of functions
- Docs
  - Functions:
    - Follows coding style very well. No issues
  - Tests:
    - Comprehensive, no issues
- Insights
  - Functions:
    - No issues. Mostly human-written code
  - Tests:
    - Consistent, style matches, no issues
- Publish
  - Functions:
    - No issues
  - Tests:
    - No issues
  - Observations:
    - Resolve-MFModuleCase was largely AI-driven, and is a good style match for the rest of the module
- Scaffold
  - Functions:
    - Functions are still mostly hand-coded by me
    - No issues
  - Tests:
    - No issues
  - Observations:
    - The newer AI-written parts closely match my own style
    - The MFProjectRules tests match the style of some of my earlier hand-coded tests, including the use of here-strings
    - The main give-away is that some of the parameter names aren't what I would have chosen
- Versioning
  - Functions:
    - No issues
  - Tests:
    - No issues
- Private Functions
  - Common
    - Functions:
      - No issues
    - Tests:
      - No issues
    - Observations:
      - The code comments closely match my own commenting style
  - Docs
    - Functions:
      - Great style matching
      - Nice small, purposeful functions
    - Tests:
      - No issues
  - Insights
    - Functions:
      - No issues
    - Tests:
      - No issues
  - Scaffold
    - Functions:
      - No issues
    - Tests:
      - No issues
- Root-level Tests
  - No issues

## Conclusion

- With a large enough code sample, Claude seems to be great at matching style, naming, and quality from intent prompting.
  - No issues with code sprawl or unintended outcomes
  - Code quality matches or exceeds my own
- AI-assisted dev is clearly better than me at specific things:
  - Writing tests
  - Writing tests and regression tests when errors happen
  - Writing the inline help
- Overall, I'm happy with the state of the code, the styling, and the outcomes
