# Error Monitoring with Sentry

This application uses Sentry for error monitoring and tracking. This document explains how to set up and use Sentry in the application.

## Setup

1. Create a Sentry account at [sentry.io](https://sentry.io)
2. Create a new project for your application
3. Get your DSN (Data Source Name) from the Sentry project settings
4. Add the DSN to your environment variables:

```
SENTRY_DSN=https://your_public_key@your_project.ingest.sentry.io/your_project_id
```

## Configuration

The Sentry configuration is in `config/config.exs`:

```elixir
config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: config_env(),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{
    env: config_env()
  },
  included_environments: [:prod, :dev],
  client: Sentry.HackneyClient
```

## Usage

### Automatic Error Reporting

The application automatically reports errors to Sentry in the following cases:

1. Unhandled exceptions in the application
2. Errors logged with `Logger.error/1`
3. Errors handled by the `Myapp.ErrorHandler` module with `:error` or `:warning` level

### Manual Error Reporting

You can manually report errors to Sentry using the `Myapp.Monitoring.Sentry` module:

```elixir
# Report an error from the ErrorHandler
error = Myapp.ErrorHandler.error(:not_found, "User not found", %{user_id: 123})
Myapp.Monitoring.Sentry.report_error(error)

# Set user context
Myapp.Monitoring.Sentry.set_user_context(user)

# Set request context
Myapp.Monitoring.Sentry.set_request_context(conn)

# Clear context
Myapp.Monitoring.Sentry.clear_context()
```

### Context Information

The application automatically adds the following context to Sentry events:

1. **User Context**: User ID, email, and username (when available)
2. **Request Context**: URL, method, headers, and query string
3. **Tags**: Environment, application version, and request ID
4. **Extra Data**: Error details, source module, and timestamp

## Environments

Sentry is enabled in the following environments:

- Production (`prod`)
- Development (`dev`)

In development, only errors with `:error` level are reported to Sentry.
In production, both `:error` and `:warning` level errors are reported.

## Filtering Sensitive Data

Sentry automatically filters sensitive data from the request:

- Passwords
- Authentication tokens
- Credit card numbers
- Social security numbers

You can add additional fields to filter in the Sentry configuration.

## Troubleshooting

If errors are not being reported to Sentry, check the following:

1. Verify that the `SENTRY_DSN` environment variable is set correctly
2. Check that the current environment is included in `included_environments`
3. Look for any errors in the application logs related to Sentry
4. Verify that the Sentry client is properly initialized in the application startup

## Resources

- [Sentry Documentation](https://docs.sentry.io/)
- [Sentry Elixir SDK](https://hexdocs.pm/sentry/readme.html)
- [Phoenix Integration Guide](https://docs.sentry.io/platforms/elixir/guides/phoenix/)
