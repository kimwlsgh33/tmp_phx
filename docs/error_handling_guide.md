# Error Handling Guide for Developers

This guide explains how to use the error handling system in our application. It covers both standard error handling and integration with Sentry for error monitoring.

## Basic Error Handling

Our application uses a standardized error handling system through the `Myapp.ErrorHandler` module. This ensures consistent error formats, proper logging, and integration with monitoring tools.

### Creating Errors

Use the `error/4` function to create standardized errors:

```elixir
# Basic error
error = Myapp.ErrorHandler.error(:not_found, "User not found")

# Error with details
error = Myapp.ErrorHandler.error(
  :validation_error, 
  "Invalid user data", 
  %{fields: %{email: "invalid format"}}
)

# Error with source module
error = Myapp.ErrorHandler.error(
  :unauthorized, 
  "Invalid token", 
  %{token: "abc123"}, 
  __MODULE__
)
```

### Handling Errors

Use the `handle/3` function to log and process errors:

```elixir
# Handle an error
Myapp.ErrorHandler.handle(error, __MODULE__)

# Handle with additional context
Myapp.ErrorHandler.handle(error, __MODULE__, %{user_id: 123})
```

### Normalizing External Errors

Use the `normalize/1` function to convert external errors to our standard format:

```elixir
# Normalize an Ecto.Changeset error
{:error, changeset} = Repo.insert(changeset)
normalized_error = Myapp.ErrorHandler.normalize(changeset)

# Normalize an HTTP error
case HTTPoison.get(url) do
  {:ok, response} -> handle_response(response)
  {:error, error} -> 
    normalized_error = Myapp.ErrorHandler.normalize(error)
    Myapp.ErrorHandler.handle(normalized_error, __MODULE__)
end
```

## Error Handling in Controllers

In controllers, use the `MyappWeb.ErrorHandler` module to convert errors to appropriate HTTP responses:

```elixir
def show(conn, %{"id" => id}) do
  case Accounts.get_user(id) do
    {:ok, user} ->
      render(conn, :show, user: user)
      
    {:error, error} ->
      # Automatically handles the error and renders the appropriate response
      MyappWeb.ErrorHandler.handle_error(conn, error)
  end
end
```

## Error Handling in Contexts

In context modules, use the standard pattern of returning `{:ok, result}` or `{:error, reason}`:

```elixir
def get_user(id) do
  case Repo.get(User, id) do
    %User{} = user -> 
      {:ok, user}
      
    nil ->
      error = Myapp.ErrorHandler.error(
        :not_found, 
        "User not found", 
        %{user_id: id}, 
        __MODULE__
      )
      
      Myapp.ErrorHandler.handle(error, __MODULE__)
  end
end
```

## Error Handling with Sentry

Our application automatically reports errors to Sentry through the error handling system. However, you can also manually interact with Sentry when needed:

### Manual Error Reporting

```elixir
# Report an error to Sentry
error = Myapp.ErrorHandler.error(:not_found, "User not found", %{user_id: 123})
Myapp.Monitoring.Sentry.report_error(error)

# Report with additional context
Myapp.Monitoring.Sentry.report_error(error, %{
  transaction_id: "tx_123",
  customer_type: "premium"
})
```

### Setting Context

```elixir
# Set user context
Myapp.Monitoring.Sentry.set_user_context(user)

# Set request context
Myapp.Monitoring.Sentry.set_request_context(conn)

# Clear context
Myapp.Monitoring.Sentry.clear_context()
```

## Best Practices

1. **Use Standard Error Types**: Stick to the predefined error types when possible
2. **Include Relevant Details**: Add context information to help with debugging
3. **Handle Errors at the Boundary**: Handle errors at the boundary of your system (e.g., controllers, API clients)
4. **Don't Swallow Errors**: Always log or report errors, don't silently ignore them
5. **Use Non-Bang Functions**: Prefer functions that return `{:ok, result}` or `{:error, reason}` over bang (!) functions

## Error Types Reference

| Type | Description | HTTP Status | Log Level |
|------|-------------|-------------|-----------|
| `:not_found` | Resource not found | 404 | info |
| `:unauthorized` | Authentication required | 401 | warning |
| `:forbidden` | Permission denied | 403 | warning |
| `:validation_error` | Invalid input data | 422 | info |
| `:rate_limited` | Rate limit exceeded | 429 | warning |
| `:bad_request` | Invalid request | 400 | info |
| `:timeout` | Operation timed out | 504 | warning |
| `:service_unavailable` | Service unavailable | 503 | warning |
| `:internal_error` | Internal server error | 500 | error |
| `:system_error` | System-level error | 500 | error |
| `:not_implemented` | Feature not implemented | 501 | info |
| `:api_error` | External API error | 502 | warning |
| `:http_error` | HTTP request error | 502 | warning |
| `:database_error` | Database operation error | 500 | error |
| `:unknown_error` | Unclassified error | 500 | error |
