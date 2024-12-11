# Installation Guide

This guide will help you set up your development environment for our Phoenix application.

## Prerequisites

### Required Software
- Elixir (~> 1.14)
- Erlang
- PostgreSQL
- Node.js (for asset management)
- Git

### Optional Tools
- Docker (for containerized development)
- Visual Studio Code with ElixirLS extension

## Step-by-Step Installation

### 1. Install Elixir and Erlang
```bash
# Using asdf (recommended)
asdf plugin-add erlang
asdf plugin-add elixir

# Or using Homebrew on macOS
brew install elixir
```

### 2. Install PostgreSQL
```bash
# Using Homebrew on macOS
brew install postgresql@14
brew services start postgresql@14
```

### 3. Install Node.js
```bash
# Using nvm (recommended)
nvm install node
nvm use node

# Or using Homebrew
brew install node
```

### 4. Clone the Repository
```bash
git clone <repository-url>
cd tmp_phx
```

### 5. Install Dependencies
```bash
# Install Elixir dependencies
mix deps.get

# Install and setup assets
# You need to configure database (see docs/architecture/postgresql.md) first
mix setup
```

### 6. Database Setup
```bash
# Create and migrate database
mix ecto.setup
```

### 7. Install Frontend Tools
The project uses Tailwind CSS and esbuild, which will be installed automatically when running:
```bash
mix assets.setup
```

## Development Environment

### Start the Server
```bash
# Start Phoenix server
mix phx.server

# Or in interactive mode
iex -S mix phx.server
```

### Running Tests
```bash
mix test
```

### Building Assets
```bash
# Development build
mix assets.build

# Production build
mix assets.deploy
```

## IDE Setup

### VS Code Configuration
1. Install ElixirLS extension
2. Add recommended settings:
```json
{
  "elixir.enableTestLenses": true,
  "elixir.suggestSpecs": true
}
```

## Troubleshooting

### Common Issues
1. PostgreSQL connection issues
   - Check PostgreSQL service is running
   - Verify database credentials in config/dev.exs

2. Asset compilation issues
   - Run `mix assets.setup` to reinstall tools
   - Clear node_modules and reinstall

3. Dependency conflicts
   - Delete _build and deps directories
   - Run `mix deps.clean --all`
   - Run `mix deps.get`
