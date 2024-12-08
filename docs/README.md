# Technical Documentation

Welcome to the technical documentation for TmpPhx. This documentation provides comprehensive information about the project's architecture, development practices, and technical components.

## Documentation Overview

Our documentation is organized into several major sections, each serving a specific purpose:

### 1. Getting Started (`getting-started/`)
- Development environment setup
- Initial configuration
- First-time contributor guide

### 2. Development (`development/`)
- Development processes and workflows
- Implementation details and decisions
- Coding standards and rules
- Documentation guidelines
- Git workflow and review process

### 3. Architecture (`architecture/`)
- System design and components
- Database schema
- Context organization
- Component interactions

### 4. API (`api/`)
- REST API endpoints
- GraphQL schema
- Authentication & authorization
- API versioning

### 5. Frontend (`frontend/`)
- LiveView components
- JavaScript interop
- CSS/styling guidelines
- Asset management

### 6. Deployment (`deployment/`)
- Environment configuration
- Deployment procedures
- Production checklist
- Monitoring and logging

### 7. Testing (`testing/`)
- Testing strategies
- Test coverage requirements
- Integration testing
- Performance testing

## Directory Structure

```
docs/
├── README.md          # This file
├── CONTRIBUTING.md    # Contribution guidelines
├── STYLE-GUIDE.md    # Coding style guidelines
├── getting-started/   # New developer onboarding
│   ├── installation.md    # Development environment setup
│   ├── configuration.md   # Application configuration
│   └── quick-start.md     # Quick start guide
├── development/      # Development processes and guidelines
│   ├── processes/    # Development workflows
│   │   ├── git-workflow.md    # Git branching and commits
│   │   ├── review/           # Code review process
│   │   └── release.md        # Release process
│   ├── implementation/  # Implementation details
│   │   └── decisions/   # Architecture decisions
│   ├── rules/          # Development rules
│   │   ├── coding/     # Coding standards
│   │   └── naming/     # Naming conventions
│   └── guidelines/     # Development guidelines
│       ├── documentation/  # Documentation guidelines
│       ├── testing/       # Testing guidelines
│       └── security/      # Security guidelines
├── architecture/     # System architecture documentation
│   ├── contexts.md   # Phoenix contexts design
│   ├── schema.md     # Database schema
│   └── components.md # Major components overview
├── api/             # API documentation
│   ├── rest.md      # REST API endpoints
│   ├── graphql.md   # GraphQL schema and queries
│   └── auth.md      # Authentication and authorization
├── frontend/        # Frontend documentation
│   ├── components.md # LiveView components
│   ├── js-interop.md # JavaScript integration
│   └── styling.md    # CSS and styling guide
├── deployment/      # Deployment documentation
│   ├── staging.md   # Staging environment
│   └── production.md # Production environment
└── testing/        # Testing documentation
    ├── unit.md     # Unit testing guide
    └── integration.md # Integration testing guide
```

## Using This Documentation

1. **New to the Project?**
   Start with the [Getting Started Guide](getting-started/installation.md)

2. **Want to Contribute?**
   Review the [Development Guidelines](development/README.md) and [Contributing Guide](CONTRIBUTING.md)

3. **Looking for Specific Topics?**
   - API development: [API Documentation](api/README.md)
   - Frontend development: [Frontend Guide](frontend/README.md)
   - Deployment: [Deployment Guide](deployment/README.md)

## Documentation Maintenance

This documentation is maintained according to the guidelines in [Documentation Guidelines](development/guidelines/documentation/README.md). If you find any issues or have suggestions for improvement, please follow the contribution process outlined in our [Contributing Guide](CONTRIBUTING.md).
