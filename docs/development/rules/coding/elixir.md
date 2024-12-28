# Elixir Coding Standards

## Code Style

- Follow the official [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- Use `mix format` before committing
- Maximum line length: 98 characters

## Naming Conventions

### Modules
- PascalCase for module names
- Full descriptive names
```elixir
defmodule UserAuthentication do
  # ...
end
```

### Functions
- snake_case for function names
- Predicate functions end with ?
```elixir
def valid_user?(user) do
  # ...
end
```

- `fetch_*` for functions that return blank tuples if the data is not found
- `get_*` for functions that return nil if the data is not found

### Variables
- snake_case for variables
- Descriptive names over abbreviations
```elixir
user_count = Repo.aggregate(User, :count)
```

## Documentation

- `@moduledoc` for every module
- `@doc` for public functions
- Include examples in docs
```elixir
@doc """
Creates a new user.

## Examples

    iex> create_user(%{name: "John", email: "john@example.com"})
    {:ok, %User{}}
"""
```

## Testing

- Test all public functions
- Use descriptive test names
- Follow arrange-act-assert pattern
```elixir
test "creates user with valid attributes" do
  # Arrange
  attrs = %{name: "John", email: "john@example.com"}
  
  # Act
  result = Users.create_user(attrs)
  
  # Assert
  assert {:ok, %User{}} = result
end
```

## Error Handling

- Use `with` for multiple operations
- Return tagged tuples
- Avoid raising in public functions
```elixir
def create_user(attrs) do
  with {:ok, user} <- validate_attributes(attrs),
       {:ok, user} <- Repo.insert(user) do
    {:ok, user}
  end
end
```
