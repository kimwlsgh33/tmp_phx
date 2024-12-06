# Development Documentation

This directory contains comprehensive documentation for developers working on the AVR-TChan project.

## Directory Structure

```
development/
├── guidelines/           # Development guidelines and standards
│   ├── code/            # Code style and practices
│   ├── documentation/   # Documentation standards
│   └── testing/         # Testing practices
├── implementation/      # Implementation plans
│   ├── active/         # Current implementation plans
│   └── completed/      # Archived implementation plans
├── processes/          # Development processes
│   ├── review/        # Code review process
│   ├── release/       # Release management
│   └── testing/       # Testing procedures
└── rules/             # Project rules and conventions
    ├── coding/        # Coding standards
    └── naming/        # Naming conventions
```

## Quick Links

### Guidelines
- [Code Style Guidelines](guidelines/code/style.md)
- [Documentation Guidelines](guidelines/documentation/README.md)
- [Testing Guidelines](guidelines/testing/README.md)

### Implementation
- [Active Plans](implementation/active/README.md)
- [Completed Plans](implementation/completed/README.md)

### Processes
- [Code Review Process](processes/review/README.md)
- [Release Management](processes/release/README.md)
- [Testing Procedures](processes/testing/README.md)

### Rules
- [Coding Standards](rules/coding/README.md)
- [Naming Conventions](rules/naming/README.md)

## Key Development Practices

### Naming Conventions
Consistent naming is crucial for maintainability. We follow strict naming conventions for:
- State machine variables (`st_` prefix)
- Timer IDs (`tid_` prefix)
- Event variables (`evt_` prefix)
- Position/value variables (descriptive names)

See [Naming Conventions](rules/naming/README.md) for detailed guidelines.

## For New Developers

1. Start with the [Code Style Guidelines](guidelines/code/style.md)
2. Review the [Documentation Guidelines](guidelines/documentation/README.md)
3. Understand our [Code Review Process](processes/review/README.md)

## Contributing

Before contributing:
1. Review relevant guidelines in the `guidelines/` directory
2. Check implementation plans in `implementation/active/`
3. Follow processes outlined in `processes/`
4. Adhere to rules in `rules/`
