# Useful Phoenix/Elixir Commands

This document provides a reference for commonly used commands when working with this Phoenix project.

## Development Commands

### Starting the Development Server
```bash
# Start Phoenix server with interactive Elixir shell
mix phx.server

# Alternative way to start the server with an IEx session
iex -S mix phx.server
```

### Database Management
```bash
# Create and migrate database
mix ecto.setup

# Run migrations only
mix ecto.migrate

# Reset database (drop, create, migrate)
mix ecto.reset

# Generate a new migration
mix ecto.gen.migration migration_name
```

### Routes
```bash
# List all routes in the application
mix phx.routes
```

### Code Generation
```bash
# Generate a new context
mix phx.gen.context ContextName Resource resources field:type

# Generate a complete HTML resource
mix phx.gen.html ContextName Resource resources field:type

# Generate a JSON API resource
mix phx.gen.json ContextName Resource resources field:type

# Generate a LiveView
mix phx.gen.live ContextName Resource resources field:type
```

### Testing
```bash
# Run all tests
mix test

# Run specific test file
mix test test/path/to/test_file.exs

# Run tests with line number
mix test test/path/to/test_file.exs:42

# Run tests with coverage reporting
mix test --cover
```

### Assets
```bash
# Watch and compile assets during development
mix assets.deploy

# Deploy assets for production
mix assets.deploy
```

## Deployment Commands

### Release Management
```bash
# Build a release
MIX_ENV=prod mix release

# Build and deploy to production
MIX_ENV=prod mix phx.digest
MIX_ENV=prod mix compile
MIX_ENV=prod mix release
```

### Production Database
```bash
# Run migrations in production
_build/prod/rel/myapp/bin/myapp eval "MyApp.Release.migrate"
```

## Debugging

### IEx Commands
```elixir
# Retrieve a value from application config
Application.get_env(:myapp, :key)

# Reload a module in IEx
r(ModuleName)

# Get information about a module
i(ModuleName)

# Debug piped operations
expression |> dbg()
```

### Helpful Mix Tasks
```bash
# Format code
mix format

# Check code for compiler warnings
mix compile --warnings-as-errors

# Check code for potential bugs and inconsistencies
mix credo

# Generate project documentation
mix docs
```
