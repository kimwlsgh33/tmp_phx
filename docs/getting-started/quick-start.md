# Quick Start Guide

This guide will help you get started with development on our Phoenix application.

## First Time Setup

1. Clone and setup the project:
```bash
git clone <repository-url>
cd myapp
mix setup
```

2. Start the development server:
```bash
mix phx.server
```

3. Visit [`localhost:4000`](http://localhost:4000) in your browser.

## Development Workflow

### Running the Application

#### Development Mode
```bash
# Start the server
mix phx.server

# Start with interactive console
iex -S mix phx.server
```

#### Asset Development
```bash
# Watch mode for assets
mix assets.build

# One-time build
mix assets.deploy
```

### Database Operations

#### Migration Commands
```bash
# Create and migrate
mix ecto.setup

# Just run migrations
mix ecto.migrate

# Reset database
mix ecto.reset
```

#### Working with Seeds
```bash
# Run seeds
mix run priv/repo/seeds.exs
```

### Testing

#### Running Tests
```bash
# Run all tests
mix test

# Run specific test file
mix test test/path/to/test.exs

# Run tests with line number
mix test test/path/to/test.exs:42
```

### LiveView Development

#### Creating New LiveView
```bash
# Generate a LiveView module
mix phx.gen.live Context Schema schemas table_fields
```

#### LiveView Routes
Add to `lib/myapp_web/router.ex`:
```elixir
live "/path", MyLiveView
```

### Common Tasks

#### Generate Resources
```bash
# Generate context and schema
mix phx.gen.context Context Schema schemas fields

# Generate complete HTML resources
mix phx.gen.html Context Schema schemas fields

# Generate JSON resources
mix phx.gen.json Context Schema schemas fields
```

#### Database Management
```bash
# Create new migration
mix ecto.gen.migration migration_name

# Roll back last migration
mix ecto.rollback
```

## Deployment

### Production Build
```bash
# Build release
MIX_ENV=prod mix release

# Run migrations in production
_build/prod/rel/myapp/bin/myapp eval "Myapp.Release.migrate"
```

## Next Steps
- Review the [Architecture Documentation](../architecture/overview.md)
- Check the [API Documentation](../api/rest.md)
- Explore [LiveView Components](../frontend/components.md)
