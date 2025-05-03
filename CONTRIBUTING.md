# Contributing to MindBlitz Contracts

Thank you for your interest in contributing to MindBlitz Contracts! This document provides guidelines and instructions for contributing to our project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Pull Request Process](#pull-request-process)
- [Code Style and Standards](#code-style-and-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Questions and Support](#questions-and-support)

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct. Please be respectful and considerate of others.

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/mindblitz_contracts_fork.git
   ```
3. Set up your development environment:

- Install [Scarb](https://docs.swmansion.com/scarb/download)
- Install [Dojo](https://dojoengine.org/docs/getting-started/installation)

## Development Workflow

1. Create a new branch for your feature/fix:

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following the code style guidelines

3. Test your changes:

   ```bash
   # Build the project
   sozo build

   # Run tests
   sozo test
   ```

4. Commit your changes with a descriptive commit message:
   ```bash
   git commit -m "feat: add new feature"  # for new features
   git commit -m "fix: resolve bug"       # for bug fixes
   git commit -m "docs: update docs"      # for documentation
   ```

## Pull Request Process

1. Ensure your branch is up to date with the main branch
2. Push your changes to your fork
3. Create a Pull Request (PR) with a clear description of the changes
4. Include any relevant issue numbers in the PR description
5. Wait for review and address any feedback

## Code Style and Standards

- Use meaningful variable and function names
- Include comments for complex logic
- Keep functions focused and single-purpose
- Write tests for new features and bug fixes

## Testing

- Write unit tests for new features
- Ensure all tests pass before submitting a PR
- Include test cases for edge cases
- Follow the existing test structure in the project

## Documentation

- Update documentation for any new features or changes
- Include clear examples in the documentation
- Keep the README.md up to date
- Document any breaking changes

## Questions and Support

- Join our [Discord community]()
- Check the [Dojo documentation](https://www.dojoengine.org)
- Open an issue for specific questions or problems

## License

By contributing to this project, you agree that your contributions will be licensed under the project's [LICENSE](LICENSE) file.

Thank you for contributing to MindBlitz Contracts!
