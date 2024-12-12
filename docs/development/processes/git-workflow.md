# Git Workflow Guidelines

This document outlines our Git workflow and branching strategy.

## Branch Structure

- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - New features
- `fix/*` - Bug fixes
- `release/*` - Release preparation

## Workflow

1. **Starting New Work**
   - Create branch from `develop`
   - Use appropriate prefix (`feature/`, `fix/`)
   - Use descriptive names (e.g., `feature/user-authentication`)

2. **Commit Guidelines**
   - Write clear commit messages
   - Use present tense ("Add feature" not "Added feature")
   - Reference issue numbers
   - Keep commits focused and atomic

3. **Pull Requests**
   - Create PR against `develop`
   - Fill out PR template
   - Request reviews from team members
   - Address review comments

4. **Merging**
   - Squash and merge to keep history clean
   - Delete branch after merging
   - Ensure CI passes before merge

5. **Releases**
   - Create release branch from `develop`
   - Version bump and changelog
   - Merge to `main` and tag
