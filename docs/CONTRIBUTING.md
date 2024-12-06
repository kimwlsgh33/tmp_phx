# Contributing to AVR-TChan Documentation

This guide outlines how to contribute to the AVR-TChan documentation.

## Documentation Structure

The complete documentation structure can be found in [README.md](README.md#documentation-structure). Here are the key directories relevant for contributors:

### Development Documentation (`development/`)
```
development/
├── processes/       # Development processes
│   └── review/      # Code review guidelines
├── implementation/  # Implementation details
├── rules/          # Development rules
│   ├── coding/     # Coding standards
│   └── naming/     # Naming conventions
└── guidelines/     # Development guidelines
    └── documentation/ # Documentation guidelines
```

This is where most contribution-related resources are located. Pay special attention to:
- `development/guidelines/documentation/` for documentation standards
- `development/rules/coding/` for code style and error handling
- `development/processes/review/` for the review process

## Contributing Guidelines

### 1. Documentation Standards
- Use Markdown for all documentation
- Follow the development documentation guidelines in `development/guidelines/documentation/README.md`
- Include practical examples
- Keep documentation up to date with code
- Follow naming conventions in `development/rules/naming/README.md`

### 2. File Organization
- Place new documentation in the appropriate section (see [README.md](README.md#documentation-structure))
- Follow the established directory hierarchy
- Create/update README.md files for new directories
- Keep related documentation together (e.g., all motor-related docs in hardware/motors/)
- Use consistent file naming based on `development/rules/naming/README.md`

### 3. Content Guidelines
- Write clear, concise content
- Include code examples where relevant
- Document error conditions and error handling (see `development/rules/coding/error_handling.md`)
- Provide troubleshooting guides
- Cross-reference related documentation
- Follow coding style guidelines in `development/rules/coding/style.md`

### 4. Making Changes
1. Create a new branch for documentation changes
2. Follow the documentation guidelines in `development/guidelines/documentation/README.md`
3. Update relevant README files
4. Maintain cross-references
5. Follow the review workflow in `development/processes/review/workflow.md`
6. Submit a pull request

### 5. Documentation Review
- Ensure technical accuracy
- Check for clarity and completeness
- Verify cross-references
- Test code examples
- Review formatting according to documentation guidelines
- Follow the review process outlined in `development/processes/review/workflow.md`

## Documentation Resources
For detailed guidelines, please refer to:
- [Documentation Guidelines](development/guidelines/documentation/README.md)
- [Coding Style Guide](development/rules/coding/style.md)
- [Naming Conventions](development/rules/naming/README.md)
- [Error Handling Guidelines](development/rules/coding/error_handling.md)
- [Review Process](development/processes/review/workflow.md)

## Contributing Guide for Phoenix Application

### Code of Conduct

Please read and follow our Code of Conduct to maintain a welcoming and inclusive environment for all contributors.

### Getting Started

1. Fork the repository
2. Clone your fork
3. Set up the development environment following our [Installation Guide](getting-started/installation.md)

### Development Workflow

#### 1. Branching Strategy
- Main branch: `main`
- Feature branches: `feature/your-feature-name`
- Bug fix branches: `fix/bug-description`
- Release branches: `release/version-number`

#### 2. Development Process
1. Create a new branch from `main`
2. Make your changes
3. Write/update tests
4. Ensure all tests pass (`mix test`)
5. Format your code (`mix format`)
6. Check for compiler warnings (`mix compile --warnings-as-errors`)
7. Run static code analysis (`mix credo`)
8. Submit a pull request

### Pull Request Guidelines

#### Before Submitting
- Update documentation for new features
- Add tests for new functionality
- Ensure all tests pass
- Format your code
- Update CHANGELOG.md if necessary

#### PR Description Should Include
- Purpose of the change
- Related issue numbers
- Breaking changes (if any)
- New dependencies added
- Screenshots (for UI changes)

### Coding Standards

#### Elixir/Phoenix
- Follow the official [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- Use `mix format` for consistent code formatting
- Follow Phoenix best practices for context organization
- Keep functions small and focused
- Write descriptive module, function, and variable names

#### JavaScript/CSS
- Use ES6+ features
- Follow standard JavaScript style guide
- Use CSS modules or TailwindCSS for styling
- Keep components small and reusable

### Testing Guidelines

#### Required Tests
- Unit tests for context functions
- Controller tests for API endpoints
- Integration tests for LiveView features
- System tests for critical user flows

#### Test Best Practices
- Use factories for test data
- Mock external services
- Keep tests focused and isolated
- Use meaningful test descriptions

### Documentation

#### Code Documentation
- Document all public functions
- Include `@moduledoc` for every module
- Add usage examples for complex functions
- Keep documentation up to date with changes

#### Project Documentation
- Update README.md for major changes
- Document new features in appropriate guides
- Include configuration changes in config guide
- Update API documentation for endpoint changes

### Review Process

#### Code Review Guidelines
1. Review for functionality
2. Check code style and conventions
3. Verify test coverage
4. Review documentation updates
5. Check for security implications
6. Verify performance impact

#### Common Review Points
- Function/module organization
- Error handling
- Security considerations
- Performance implications
- Documentation completeness
- Test coverage

### Getting Help

- Join our development discussion on Slack
- Check existing issues and documentation
- Ask questions in pull requests
- Reach out to maintainers

### License

By contributing, you agree that your contributions will be licensed under the project's license.
