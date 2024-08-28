# Contributing to ModuleForge

Thank you for considering contributing to ModuleForge! We welcome contributions from the community and are excited to collaborate

## Getting Started

1. **Fork the Repository**: Click the "Fork" button at the top right of this page to create a copy of this repository under your GitHub account.

2. **Clone Your Fork**: Clone your forked repository to your local machine.
    ```sh
    git clone https://github.com/your-username/your-repo-name.git
    cd your-repo-name
    ```

3. **Create a Branch**: Create a new branch for your changes.
    ```sh
    git checkout -b feature/your-feature-name
    ```

4. **Install Dependencies**: Install any necessary dependencies.
    ```sh
    # Example for a PowerShell project
    Install-Module -Name Pester -Force -Scope CurrentUser
    ```

## Making Changes

1. **Code Style**: Ensure your code follows the style guidelines of this project. Use appropriate verbose, warning, error, and information streams.

2. **Write Tests**: Add tests to prove your changes are effective and that your feature works. Use Pester for testing.
    ```sh
    Invoke-Pester
    ```

3. **Commit Your Changes**: Commit your changes with a clear and descriptive commit message.
    ```sh
    git add .
    git commit -m "Add feature: your-feature-name"
    ```

4. **Push to Your Fork**: Push your changes to your forked repository.
    ```sh
    git push origin feature/your-feature-name
    ```

## Submitting a Pull Request

1. **Open a Pull Request**: Go to the original repository and click the "New pull request" button. Select the branch you created and submit your pull request.

2. **Describe Your Changes**: Provide a clear description of your changes and the related issue. Include relevant motivation and context.

3. **Review Process**: Your pull request will be reviewed by the maintainers. Please be patient as we review your changes.

## Code of Conduct

Please note that this project is released with a Contributor Code of Conduct. By participating in this project, you agree to abide by its terms.

## Additional Resources

- **Documentation**: Check the documentation for more information on how to use and contribute to this project.
- **Issues**: If you encounter any issues, please check the issue tracker and consider opening a new issue if your problem is not already addressed.

Thank you for your contributions!