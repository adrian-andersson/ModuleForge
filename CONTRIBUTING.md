# Contributing to ModuleForge

Thank you for considering contributing to ModuleForge! Contributions welcome via Pull Request.

## Getting Started

1. **Fork the Repository**: Click the "Fork" button at the top right of this page to create a copy of this repository under your GitHub account.

2. **Clone Your Fork**: Clone your forked repository to your local machine.

    ```sh
    git clone https://github.com/your-username/ModuleForge.git
    cd ModuleForge
    ```

3. **Create a Branch**: Create a new branch for your changes.

    ```sh
    git checkout -b feature/your-feature-name
    ```

## Making Changes

1. **Code Style**: Ensure your code follows the style guidelines of this project. Use appropriate verbose, warning, error, and information streams.

2. **Write Tests**: Add Pester tests to prove your changes work and that your feature meets the expected behaviour.

    ```powershell
    Invoke-Pester
    ```

3. **Commit Prefixes**: This project uses commit message prefixes to drive automated changelog generation. Use the appropriate prefix for your change:

    | Prefix | Changelog Section | Notes |
    | --- | --- | --- |
    | `feat:` | New Features | A new function or capability |
    | `fix:` | Bug Fixes | A bug fix |
    | `docs:` | Documentation Changes | Documentation only changes |
    | `refactor:` | Code Rewrite/Refactor | Code change that neither fixes a bug nor adds a feature |
    | `perf:` | Performance Improvements | A code change that improves performance |
    | `chore:` | *(not in default changelog)* | Pipeline, tooling, or housekeeping work |
    | `test:` | *(not in default changelog)* | Adding or updating tests only |

    Example:

    ```sh
    git commit -m "feat: add support for DSC resource scaffolding"
    ```

4. **Push to Your Fork**: Push your changes to your forked repository.

    ```sh
    git push origin feature/your-feature-name
    ```

## Submitting a Pull Request

1. **Open a Pull Request**: Go to the [ModuleForge repository](https://github.com/adrian-andersson/ModuleForge) and click the "New pull request" button. Select your branch and submit.

2. **Describe Your Changes**: Provide a clear description of your changes and the related issue. Include relevant motivation and context.

3. **Review Process**: Your pull request will be reviewed by the maintainers. Please be patient as we review your changes.

## Community Contributions — DSC & GitLab

DSC resource support and GitLab scaffold support are out of scope for the core maintainers but welcome as community contributions. If you'd like to collaborate on either area, please [open an issue](https://github.com/adrian-andersson/ModuleForge/issues) to request contributor access.

## Feature Suggestions & Feedback

Feature suggestions and constructive feedback are always welcome — open an issue and start a conversation.

Feedback should be constructive and focused on the project; unconstructive or hostile comments will be removed.

## Code of Conduct

Please be respectful and constructive in all interactions. Harassment or hostile behaviour will not be tolerated.

## Additional Resources

- [Documentation](https://adrian-andersson.github.io/ModuleForge/)
- [Issue Tracker](https://github.com/adrian-andersson/ModuleForge/issues)
- [Roadmap](Roadmap.md)

Thank you for your contributions!
