# Security Policy

## Reporting a Vulnerability

Please report security vulnerabilities exclusively through [GitHub Private Vulnerability Reporting](https://github.com/adrian-andersson/ModuleForge/security/advisories/new).

**Do not** report security issues via:
- Public GitHub Issues, Discussions, or Pull Requests
- Social media
- Direct messages to maintainers or administrators unless you have already been engaged through the private reporting channel

All reports submitted through this channel will be treated as confidential. This ensures they are handled appropriately and do not inadvertently disclose vulnerabilities before they are remediated.

---

## Supported Versions

| Version | Supported |
| --- | --- |
| Latest stable release | ✅ |
| Latest prerelease | ✅ |
| Older versions | Support reviewed on a case-by-case basis depending on severity |

Where a vulnerability is assessed as High or Critical, all reasonable efforts will be made to protect consumers regardless of the version affected — including proactive removal from GitHub Releases and unlisting from PSGallery where appropriate.

---

## Expected Response Times

These are targets, not commitments. ModuleForge is maintained by a solo developer alongside full-time employment.

| Severity | Acknowledgement Target |
| --- | --- |
| High / Critical | 3 business days |
| Medium / Low | 21 days |

If you have not received acknowledgement after **21 days**, a second report via the same channel would be appreciated — the original may have been lost or received during a period of unavailability.

All reports will receive best-effort triage. Severity assessment will follow standard industry definitions.

---

## Public Disclosure

Public disclosure is acceptable after **90 days** from the date of the initial report, to allow reasonable time for remediation. A request to defer disclosure may be made depending on the nature and scope of the issue, and is appreciated where practical.

This applies to vulnerabilities that directly relate to ModuleForge. Vulnerabilities in dependencies (see below) are handled differently.

---

## Information Required

To help triage effectively, please include as much of the following as possible:

- **Description** — what the vulnerability is and how it manifests
- **Scope** — which area of the project is affected:
  - Scaffolding and project initialisation
  - Module build and compilation
  - GitHub Actions or Azure DevOps workflow files or templates
  - Documentation site content or generation
  - Secret or PII disclosure
- **Specific functions or filenames** — if known
- **Replication steps** — if available
- **Estimated impact** — who is affected and under what conditions
- **Proposed mitigations or workarounds** — if already identified

Partial information is still valuable — please report even if you cannot provide all of the above.

---

## Disclosure Approach

If a report is validated, work on a fix will begin as early as practical. Fix notes in the release may be intentionally limited in detail until broader remediation is complete.

A GitHub Security Advisory will be published once remediation is complete and a post-incident review has been conducted.

### Dependency Vulnerabilities

If a reported vulnerability relates to a dependency not maintained by ModuleForge — including PowerShell itself, GitHub Actions workflow dependencies, Pester, PlatyPS, or other third-party modules — ModuleForge reserves the right to provide an acknowledgement response only. Care will always be taken to thank the reporter for the awareness, and where appropriate the issue will be raised with the relevant upstream maintainer.

---

## Security Resolution

Where a validated vulnerability is remediated, the preferred resolution path includes:

- A new prerelease build with a fix, with release notes that may be intentionally limited in detail depending on the nature of the concern
- Removal of affected versions from GitHub Releases and unlisting from PSGallery (note: PSGallery does not support version deletion — affected versions will be unlisted from search results)
- Updates to workflow templates and scaffolded files as required
- A specific note in the stable release directing users to update via PSGallery

---

## Maintainer Determination

ModuleForge maintainers reserve the right to make the final determination on whether a submitted report constitutes a security vulnerability. Determinations may be reconsidered if additional evidence or clarity is provided in a professional and appropriate manner.

---

## A Note on Good Faith

ModuleForge is an open source project. Security is taken seriously and all reasonable efforts will be made to respond to and remediate valid reports. Candid, good-faith reports with sufficient detail are genuinely appreciated — they make the tool safer for everyone who uses it.

Thank you for taking the time to report responsibly.
