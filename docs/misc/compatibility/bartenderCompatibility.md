# Bartender module compatibility

If you used my previous module for this: [bartender](https://github.com/DomainGroupOSS/bartender), I tried to keep it backwards compatible. Some Notes on this

- The versioning should now be tracked by your build orchestration tool. PSake, GitHub Actions etc, not the module itself.
  - I'm partial to GitHub tags, but you could also retrieve the version from a PSRepository directly
  - I've included a function, `get-mfNextSemver` to help with figuring out what your next version could be
  - I've moved to SemVer v1.0 myself, this supports using GitHub packages and psgallery. `get-mfNextSemver` uses that
  - Check [this](./SemVer_Interpretation.md) for how I'm using this
- ModuleForge is cross-platform compatible and works well with GitHub Actions Ubuntu Latest
- I've added a `add-mfRepositoryXmlData` function if you want to use GitHub Packages