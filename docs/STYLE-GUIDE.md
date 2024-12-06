# Documentation Style Guide

## General Principles

### 1. File Format
- Use Markdown (.md) for all documentation
- UTF-8 encoding
- Unix-style line endings (LF)
- One blank line at end of file

### 2. File Structure
```markdown
# Title

## Overview
Brief introduction

## Main Content
Detailed information

## Related Topics
- [Related Link](path/to/file.md)
```

## Code Documentation

### 1. Module Documentation
```elixir
defmodule MyApp.MyModule do
  @moduledoc """
  Brief description of the module's purpose.

  ## Examples

      iex> MyApp.MyModule.my_function(arg)
      {:ok, result}

  """
end
```

### 2. Function Documentation
```elixir
@doc """
Describes what the function does.

## Parameters

  - param1: Description of param1
  - param2: Description of param2

## Returns

Description of return value

## Examples

    iex> my_function(param1, param2)
    {:ok, result}

"""
def my_function(param1, param2) do
  # Implementation
end
```

### 3. Type Specifications
```elixir
@type my_type :: String.t() | integer()

@spec my_function(String.t(), integer()) :: {:ok, term()} | {:error, term()}
```

## API Documentation

### 1. Controller Actions
```elixir
@doc """
Lists all items.

## Response Format

    {
      "data": [
        {
          "id": "123",
          "type": "item",
          "attributes": {
            "name": "Item name",
            "description": "Item description"
          }
        }
      ]
    }

## Status Codes

  - 200: Success
  - 401: Unauthorized
  - 403: Forbidden
"""
```

### 2. LiveView Documentation
```elixir
@moduledoc """
LiveView module for handling real-time item updates.

## Socket Assigns

  - :items - List of items being displayed
  - :loading - Boolean indicating loading state

## Events

  - "load-more" - Loads next page of items
  - "filter" - Filters items by given criteria
"""
```

## Markdown Guidelines

### 1. Headers
```markdown
# H1 - Document Title
## H2 - Major Sections
### H3 - Subsections
#### H4 - Sub-subsections
```

### 2. Code Blocks
- Use fenced code blocks with language specification
- For Elixir code:
  ```elixir
  defmodule Example do
    def hello do
      "world"
    end
  end
  ```
- For Shell commands:
  ```bash
  mix deps.get
  mix phx.server
  ```

### 3. Links
- Use relative links for internal documentation
- Use absolute links for external resources
- Include link text that makes sense out of context

### 4. Lists
- Use `-` for unordered lists
- Use `1.` for ordered lists
- Maintain consistent indentation for nested lists

### 5. Tables
```markdown
| Column 1 | Column 2 |
|----------|----------|
| Cell 1   | Cell 2   |
```

## Configuration Documentation

### 1. Environment Variables
```markdown
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| PORT | integer | 4000 | HTTP port |
```

### 2. Config Files
```elixir
# config/config.exs
config :my_app, MyApp.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "your-secret-key"
```

## Best Practices

1. Keep documentation close to code
2. Update docs with code changes
3. Include examples for complex features
4. Document both success and error cases
5. Use consistent terminology
6. Keep formatting consistent
7. Regular review and updates

## Common Terminology

- Use "Phoenix" not "phoenix"
- Use "Elixir" not "elixir"
- Use "LiveView" not "liveview"
- Use "Ecto" not "ecto"
- Capitalize proper nouns

## Review Checklist

- [ ] Correct spelling and grammar
- [ ] Code examples are tested and work
- [ ] Links are valid
- [ ] Formatting is consistent
- [ ] Documentation matches implementation
- [ ] Examples are clear and helpful
- [ ] All sections are complete
