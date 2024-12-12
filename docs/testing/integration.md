# Integration Testing Guide

This guide covers integration testing practices for our Phoenix application.

## Overview

Integration tests verify that different parts of the application work together correctly. They test the interaction between controllers, views, and the database.

## Test Categories

### Controller Tests
- Testing HTTP endpoints
- Request/response cycle
- Authentication/authorization
- Session handling

### Feature Tests
We use Wallaby for browser-based feature testing.

### Database Integration
- Ecto sandbox mode
- Transaction rollback
- Database cleanup

## Best Practices

- Use test helpers for common setup
- Clean up test data
- Test happy and error paths
- Mock external services when appropriate

## Running Integration Tests

```bash
# Run all integration tests
mix test test/integration

# Run specific feature test
mix test test/integration/features/user_auth_test.exs
```

## Common Patterns

### Setup Helpers
```elixir
setup do
  # Setup code
  :ok
end
```

### Database Transactions
```elixir
use MyApp.DataCase
```
