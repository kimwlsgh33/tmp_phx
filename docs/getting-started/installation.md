# Installation Guide

## Prerequisites

### System Requirements
- Erlang/OTP 24 or later
- Elixir 1.14 or later
- PostgreSQL 14 or later
- Node.js 16 or later (for asset compilation)
- Git

### Development Tools
- Code editor with Elixir support (Windsurf recommended)
- PostgreSQL client
- Terminal application

## Installation Steps

### 1. Install Erlang and Elixir
#### macOS (using Homebrew)
```bash
brew install erlang
brew install elixir
```

#### Other platforms
Visit the [official Elixir installation guide](https://elixir-lang.org/install.html)

### 2. Install Phoenix
```bash
mix local.hex
mix archive.install hex phx.new
```

### 3. Database Setup
#### Install PostgreSQL
```bash
brew install postgresql@14
brew services start postgresql@14
```

### 4. Project Setup
1. Clone the repository:
```bash
git clone [repository-url]
cd [project-directory]
```

2. Install dependencies:
```bash
mix deps.get
mix deps.compile
```

3. Setup database:
```bash
mix ecto.setup
```

4. Install Node.js dependencies:
```bash
cd assets && npm install
cd ..
```

### 5. Configuration
1. Copy the example environment file:
```bash
cp config/dev.exs.example config/dev.exs
```

2. Update the database configuration in `config/dev.exs`

### 6. Start the Application
```bash
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) in your browser.

## Verification
- Phoenix server running at `localhost:4000`
- Database connections successful
- Asset compilation working
- All tests passing (`mix test`)

## Troubleshooting

### Common Issues
1. **Database Connection Issues**
   - Check PostgreSQL is running
   - Verify database credentials in `config/dev.exs`

2. **Dependency Issues**
   - Run `mix deps.clean --all`
   - Delete `_build` directory
   - Run `mix deps.get` again

3. **Asset Compilation Issues**
   - Verify Node.js installation
   - Clear `assets/node_modules`
   - Run `npm install` in assets directory

## Next Steps
- Review the [Configuration Guide](configuration.md)
- Check out the [Quick Start Guide](quick-start.md)
- Read about [Development Workflow](../development/workflow.md)
