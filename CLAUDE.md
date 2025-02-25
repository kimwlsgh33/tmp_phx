# CLAUDE.md - Development Guide

## Build/Test Commands
- `mix setup` - Install dependencies and setup the project
- `mix phx.server` - Start the Phoenix server
- `mix test` - Run all tests
- `mix test test/path/to/file_test.exs` - Run a specific test file
- `mix test test/path/to/file_test.exs:123` - Run a specific test at line 123
- `mix format` - Format code according to Elixir standards
- `mix ecto.reset` - Reset the database

## Code Style Guidelines
- **Modules**: Use structured context modules (like `Myapp.Accounts`) with clear documentation
- **Documentation**: Always include `@moduledoc` and `@doc` with examples for public functions
- **Functions**: Group related functions with comment headers (e.g., `## Database getters`)
- **Error Handling**: Use `with` statements for complex error flows, pattern match on responses
- **Testing**: Follow the test pattern in the codebase - descriptive `describe` blocks and clear assertions
- **Naming**: Use snake_case for variables and functions, CamelCase for modules
- **LiveView**: Follow Phoenix conventions - `mount`, `handle_event`, `render` functions
- **Imports**: Group imports at the top of files, use aliases for readability
- **Types**: Use module attributes for types and specs when appropriate