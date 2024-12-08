# Unit Testing Guide

This guide covers unit testing practices for our Phoenix application using ExUnit.

## Overview

Unit tests in our Phoenix application focus on testing individual components in isolation. We use ExUnit, Elixir's built-in testing framework.

## Writing Unit Tests

### Test Structure
- One test module per source module
- Clear test descriptions
- Proper setup and teardown

### Best Practices
- Test one thing at a time
- Use descriptive test names
- Keep tests independent
- Follow the Arrange-Act-Assert pattern

## Running Tests

```bash
# Run all tests
mix test

# Run specific test file
mix test test/path/to/test_file.exs

# Run tests with line number
mix test test/path/to/test_file.exs:10
```

## Test Helpers

### Factory Setup
We use ExMachina for test data factories.

### Common Assertions
- assert/refute for boolean checks
- assert_raise for exception testing
- assert_receive for message testing

## Code Coverage

We use ExCoveralls for test coverage reporting.
