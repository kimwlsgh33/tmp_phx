# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- **Account Management**: Fixed `unlink_account` function to remove reciprocal links between accounts. Previously, when unlinking accounts, only the link from primary_user → linked_user was removed, leaving potential orphaned links in the opposite direction (linked_user → primary_user). This update ensures both directions are properly cleaned up, preventing issues with partially linked accounts and improving data consistency.

