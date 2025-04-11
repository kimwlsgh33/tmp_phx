# Error Handling System

This document describes the standardized error handling system used throughout the application.

## Overview

The error handling system provides a consistent way to:

1. Create standardized error structures
2. Normalize errors from different sources
3. Handle errors appropriately at different layers of the application
4. Log errors with appropriate severity levels
5. Present user-friendly error messages

## Core Components

### `Myapp.ErrorHandler`

The central module for error handling. It provides functions for:

- Creating standardized error structs
- Normalizing various error formats
- Handling errors with appropriate logging
- Extracting user-friendly messages

```elixir
# Creating a standard error
error = Myapp.ErrorHandler.error(:not_found, "User not found", %{user_id: 123})

# Normalizing an external error
{:error, normalized_error} = Myapp.ErrorHandler.normalize({:error, :not_found})

# Handling an error with proper logging
{:error, handled_error} = Myapp.ErrorHandler.handle(error, MyModule)

# Getting a user-friendly message
message = Myapp.ErrorHandler.user_message(error)
```

### `Myapp.ApiError`

Specialized module for handling API-related errors. It provides functions for:

- Handling HTTP responses based on status codes
- Handling HTTP client errors
- Normalizing errors from different API providers

```elixir
# Handling an HTTP response
case HTTPoison.get(url, headers) do
  {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
    Myapp.ApiError.handle_response(status, body, :twitter)
    
  {:error, %HTTPoison.Error{} = error} ->
    Myapp.ApiError.handle_http_error(error, :twitter)
end
```

### `MyappWeb.ErrorHandler`

Web-specific error handling for controllers and LiveViews. It provides functions for:

- Converting application errors to appropriate HTTP responses
- Rendering errors in different formats (HTML, JSON, API)

```elixir
# In a controller
def show(conn, %{"id" => id}) do
  case Accounts.get_user(id) do
    {:ok, user} ->
      render(conn, :show, user: user)
      
    {:error, error} ->
      MyappWeb.ErrorHandler.handle_error(conn, error)
  end
end
```

### `MyappWeb.FallbackController`

A controller that handles various error formats and converts them to appropriate HTTP responses.

```elixir
# In a controller module
defmodule MyappWeb.UserController do
  use MyappWeb, :controller
  
  action_fallback MyappWeb.FallbackController
  
  def show(conn, %{"id" => id}) do
    case Accounts.get_user(id) do
      {:ok, user} -> render(conn, :show, user: user)
      error -> error  # This will be handled by the fallback controller
    end
  end
end
```

## Standard Error Types

The system defines standard error types to ensure consistency:

| Type | Description | HTTP Status | Log Level |
|------|-------------|-------------|-----------|
| `:not_found` | Resource not found | 404 | info |
| `:unauthorized` | Authentication required | 401 | warning |
| `:forbidden` | Permission denied | 403 | warning |
| `:validation_error` | Invalid input data | 422 | info |
| `:rate_limited` | Rate limit exceeded | 429 | warning |
| `:bad_request` | Invalid request | 400 | info |
| `:timeout` | Operation timed out | 504 | warning |
| `:service_unavailable` | External service unavailable | 503 | warning |
| `:internal_error` | Internal server error | 500 | error |
| `:system_error` | System-level error | 500 | error |
| `:api_error` | Error from external API | varies | warning |
| `:http_error` | HTTP client error | varies | warning |
| `:unknown_error` | Unclassified error | 500 | error |

## Error Structure

Standard errors have the following structure:

```elixir
%{
  type: :error_type,        # Atom indicating the type of error
  message: "Error message", # Human-readable error message
  details: %{...},          # Additional details about the error
  source: SourceModule,     # Module or other source of the error
  timestamp: ~U[...]        # When the error occurred
}
```

## Usage Guidelines

### Creating Errors

Always use `Myapp.ErrorHandler.error/4` to create errors:

```elixir
# Basic error
error = Myapp.ErrorHandler.error(:not_found, "User not found")

# Error with details
error = Myapp.ErrorHandler.error(
  :validation_error,
  "Invalid user data",
  %{fields: %{email: "invalid format"}}
)

# Error with source
error = Myapp.ErrorHandler.error(
  :internal_error,
  "Database connection failed",
  %{},
  Myapp.Repo
)
```

### Returning Errors

Use the standard `{:error, error}` tuple pattern:

```elixir
def get_user(id) do
  case Repo.get(User, id) do
    %User{} = user -> {:ok, user}
    nil -> {:error, Myapp.ErrorHandler.error(:not_found, "User not found", %{id: id})}
  end
end
```

### Handling Errors

Use the appropriate error handling function for the context:

```elixir
# In application code
case result do
  {:ok, value} -> # Handle success
  {:error, error} -> Myapp.ErrorHandler.handle(error, __MODULE__)
end

# In controllers
case result do
  {:ok, value} -> render(conn, :show, value: value)
  {:error, error} -> MyappWeb.ErrorHandler.handle_error(conn, error)
end

# For API calls
case HTTPoison.get(url, headers) do
  {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
    Myapp.ApiError.handle_response(status, body, :provider_name)
  
  {:error, %HTTPoison.Error{} = error} ->
    Myapp.ApiError.handle_http_error(error, :provider_name)
end
```

### Using the Fallback Controller

For controllers that need to handle errors:

```elixir
defmodule MyappWeb.UserController do
  use MyappWeb, :controller
  
  action_fallback MyappWeb.FallbackController
  
  # Now you can just return error tuples directly
  def show(conn, %{"id" => id}) do
    Accounts.get_user(id)
  end
end
```

## Best Practices

1. **Be Specific**: Use the most specific error type that applies
2. **Include Details**: Add relevant details to help with debugging
3. **User-Friendly Messages**: Ensure error messages are understandable by end users
4. **Consistent Patterns**: Follow the established patterns for error handling
5. **Proper Logging**: Let the error handling system handle logging
6. **Security Awareness**: Don't expose sensitive information in error messages

## Migration Guide

If you're updating existing code to use the new error handling system:

### Before:

```elixir
def get_user(id) do
  case Repo.get(User, id) do
    %User{} = user -> {:ok, user}
    nil -> {:error, :not_found}
  end
end

# In controller
def show(conn, %{"id" => id}) do
  case Accounts.get_user(id) do
    {:ok, user} ->
      render(conn, :show, user: user)
    
    {:error, :not_found} ->
      conn
      |> put_status(:not_found)
      |> json(%{error: "User not found"})
    
    {:error, reason} ->
      conn
      |> put_status(:internal_server_error)
      |> json(%{error: "An error occurred"})
  end
end
```

### After:

```elixir
def get_user(id) do
  case Repo.get(User, id) do
    %User{} = user -> {:ok, user}
    nil -> {:error, Myapp.ErrorHandler.error(:not_found, "User not found", %{id: id})}
  end
end

# In controller
defmodule MyappWeb.UserController do
  use MyappWeb, :controller
  
  action_fallback MyappWeb.FallbackController
  
  def show(conn, %{"id" => id}) do
    Accounts.get_user(id)
  end
end
```

## Testing

When testing code that uses the error handling system:

```elixir
test "returns error when user not found" do
  result = Accounts.get_user(999)
  
  assert {:error, error} = result
  assert error.type == :not_found
  assert error.message == "User not found"
  assert error.details.id == 999
end
```
