defmodule Myapp.Shared.ErrorHandler do
  @moduledoc """
  Centralized error handling for the application.

  This module provides a standardized way to handle errors across the application.
  It defines common error types, normalizes errors from different sources,
  and ensures consistent logging and reporting.

  ## Usage

  ```elixir
  # Creating a standard error
  {:error, Myapp.ErrorHandler.error(:not_found, "User not found", %{user_id: 123})}

  # Normalizing an external error
  external_result
  |> Myapp.ErrorHandler.normalize()

  # Handling an error with proper logging
  case result do
    {:ok, value} ->
      # Handle success
    {:error, error} ->
      Myapp.ErrorHandler.handle(error, __MODULE__)
      # Return or propagate the error
  end
  ```
  """

  require Logger
  alias Myapp.Monitoring.Sentry

  @type error_type :: atom()
  @type error_message :: String.t()
  @type error_details :: map()
  @type error_source :: module() | String.t()
  @type error_context :: map()
  @type error :: %{
    type: error_type(),
    message: error_message(),
    details: error_details(),
    source: error_source(),
    timestamp: DateTime.t()
  }

  @doc """
  Creates a standardized error struct.

  ## Parameters

  - `type`: The type of error (e.g., `:not_found`, `:validation_error`)
  - `message`: A human-readable error message
  - `details`: Additional details about the error (optional)
  - `source`: The source of the error, typically a module name (optional)

  ## Examples

      iex> Myapp.ErrorHandler.error(:not_found, "User not found")
      %{type: :not_found, message: "User not found", details: %{}, source: nil, timestamp: ~U[2023-01-01 00:00:00Z]}

      iex> Myapp.ErrorHandler.error(:validation_error, "Invalid email", %{field: "email"}, MyApp.Accounts)
      %{type: :validation_error, message: "Invalid email", details: %{field: "email"}, source: MyApp.Accounts, timestamp: ~U[2023-01-01 00:00:00Z]}
  """
  @spec error(error_type(), error_message(), error_details(), error_source()) :: error()
  def error(type, message, details \\ %{}, source \\ nil) do
    %{
      type: type,
      message: message,
      details: details,
      source: source,
      timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Normalizes various error formats into the standard error struct.

  This function handles different error formats from various parts of the application
  and external libraries, converting them to a consistent format.

  ## Examples

      iex> Myapp.ErrorHandler.normalize({:error, :not_found})
      {:error, %{type: :not_found, message: "Resource not found", details: %{}, source: nil, timestamp: ~U[2023-01-01 00:00:00Z]}}

      iex> Myapp.ErrorHandler.normalize({:error, "Connection failed"})
      {:error, %{type: :system_error, message: "Connection failed", details: %{}, source: nil, timestamp: ~U[2023-01-01 00:00:00Z]}}

      iex> Myapp.ErrorHandler.normalize({:error, %Ecto.Changeset{}})
      {:error, %{type: :validation_error, message: "Validation failed", details: %{changeset: %Ecto.Changeset{}}, source: nil, timestamp: ~U[2023-01-01 00:00:00Z]}}
  """
  @spec normalize(any()) :: {:ok, any()} | {:error, error()}
  def normalize({:ok, _value} = success), do: success

  def normalize({:error, reason}) do
    {:error, normalize_reason(reason)}
  end

  def normalize(other) do
    # If it's not a standard {:ok, _} or {:error, _} tuple, assume it's an error
    {:error, normalize_reason(other)}
  end

  @doc """
  Handles an error by logging it appropriately and optionally performing additional actions.

  ## Parameters

  - `error`: The error to handle
  - `source`: The source of the error, typically a module name (optional)
  - `context`: Additional context for the error (optional)

  ## Examples

      iex> error = Myapp.ErrorHandler.error(:not_found, "User not found")
      iex> Myapp.ErrorHandler.handle(error, MyApp.UserController)
      {:error, %{type: :not_found, message: "User not found", details: %{}, source: MyApp.UserController, timestamp: ~U[2023-01-01 00:00:00Z]}}
  """
  @spec handle(error() | any(), error_source(), error_context()) :: {:error, error()}
  def handle(error, source, context \\ %{})
  
  def handle(%{type: _type} = error, source, context) do
    # Ensure the error has a source
    error = Map.put(error, :source, error.source || source)

    # Add context to details if provided
    error = if map_size(context) > 0 do
      Map.update(error, :details, context, &Map.merge(&1, context))
    else
      error
    end

    # Log the error
    log_error(error)

    # Return the error
    {:error, error}
  end

  def handle(other, source, context) do
    # If it's not already a standard error struct, normalize it first
    other
    |> normalize_reason()
    |> handle(source, context)
  end

  @doc """
  Extracts error messages from an error struct in a format suitable for end users.

  ## Examples

      iex> error = Myapp.ErrorHandler.error(:not_found, "User not found")
      iex> Myapp.ErrorHandler.user_message(error)
      "User not found"

      iex> error = Myapp.ErrorHandler.error(:validation_error, "Validation failed", %{fields: %{email: "invalid format"}})
      iex> Myapp.ErrorHandler.user_message(error)
      "Validation failed: email (invalid format)"
  """
  @spec user_message(error()) :: String.t()
  def user_message(%{type: :validation_error, message: message, details: %{fields: fields}}) do
    field_errors = fields
                   |> Enum.map(fn {field, error} -> "#{field} (#{error})" end)
                   |> Enum.join(", ")
    "#{message}: #{field_errors}"
  end

  def user_message(%{message: message}) do
    message
  end

  def user_message(other) do
    other
    |> normalize_reason()
    |> user_message()
  end

  # Private functions

  defp normalize_reason(%{type: _type, message: _message} = error) do
    # Already a standard error struct
    error
  end

  defp normalize_reason(%Ecto.Changeset{} = changeset) do
    {message, details} = format_changeset_errors(changeset)
    error(:validation_error, message, details)
  end

  defp normalize_reason(%HTTPoison.Error{reason: reason}) do
    error(:http_error, "HTTP request failed", %{reason: reason})
  end

  defp normalize_reason(reason) when is_atom(reason) do
    {type, message} = atom_to_error(reason)
    error(type, message)
  end

  defp normalize_reason(reason) when is_binary(reason) do
    error(:system_error, reason)
  end

  defp normalize_reason(%{__struct__: struct} = struct_error) do
    error(:system_error, "Error in #{inspect(struct)}", %{error: struct_error})
  end

  defp normalize_reason(reason) when is_map(reason) do
    if Map.has_key?(reason, "error") || Map.has_key?(reason, :error) do
      # Likely an API error response
      message = reason["error"] || reason[:error] || "API error"
      error(:api_error, message, reason)
    else
      error(:system_error, "Unknown error", reason)
    end
  end

  defp normalize_reason(reason) do
    # Fallback for any other error format
    error(:unknown_error, "Unknown error: #{inspect(reason)}")
  end

  defp atom_to_error(:not_found), do: {:not_found, "Resource not found"}
  defp atom_to_error(:unauthorized), do: {:unauthorized, "Unauthorized access"}
  defp atom_to_error(:forbidden), do: {:forbidden, "Access forbidden"}
  defp atom_to_error(:invalid_credentials), do: {:unauthorized, "Invalid credentials"}
  defp atom_to_error(:invalid_token), do: {:unauthorized, "Invalid token"}
  defp atom_to_error(:token_expired), do: {:unauthorized, "Token expired"}
  defp atom_to_error(:rate_limit_exceeded), do: {:rate_limited, "Rate limit exceeded"}
  defp atom_to_error(:timeout), do: {:timeout, "Operation timed out"}
  defp atom_to_error(:bad_request), do: {:bad_request, "Bad request"}
  defp atom_to_error(:internal_error), do: {:internal_error, "Internal server error"}
  defp atom_to_error(:service_unavailable), do: {:service_unavailable, "Service unavailable"}
  defp atom_to_error(:not_implemented), do: {:not_implemented, "Feature not implemented"}
  defp atom_to_error(atom), do: {:system_error, "Error: #{atom}"}

  defp format_changeset_errors(%Ecto.Changeset{} = changeset) do
    errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)

    message = "Validation failed"
    details = %{changeset: changeset, fields: errors}

    {message, details}
  end

  defp log_error(%{type: type, message: message, details: details, source: source} = error) do
    # Determine log level based on error type
    level = error_type_to_log_level(type)

    # Format the log message
    source_str = if source, do: " [#{inspect(source)}]", else: ""
    details_str = if map_size(details) > 0, do: " #{inspect(details)}", else: ""
    log_message = "#{message}#{source_str}#{details_str}"

    # Log the error
    case level do
      :error ->
        Logger.error(log_message)
        # Report to Sentry for error-level issues
        Sentry.report_error(error)
      :warning ->
        Logger.warning(log_message)
        # Report to Sentry for warning-level issues in production
        if Application.get_env(:myapp, :env) == :prod do
          Sentry.report_error(error)
        end
      :info -> Logger.info(log_message)
      # :debug -> Logger.debug(log_message)  # Removed to avoid unused clause warning
    end
  end

  defp error_type_to_log_level(:not_found), do: :info
  defp error_type_to_log_level(:unauthorized), do: :warning
  defp error_type_to_log_level(:forbidden), do: :warning
  defp error_type_to_log_level(:validation_error), do: :info
  defp error_type_to_log_level(:rate_limited), do: :warning
  defp error_type_to_log_level(:timeout), do: :warning
  defp error_type_to_log_level(:bad_request), do: :info
  defp error_type_to_log_level(:api_error), do: :warning
  defp error_type_to_log_level(:http_error), do: :warning
  defp error_type_to_log_level(:internal_error), do: :error
  defp error_type_to_log_level(:system_error), do: :error
  defp error_type_to_log_level(:service_unavailable), do: :warning
  defp error_type_to_log_level(:not_implemented), do: :info
  defp error_type_to_log_level(:unknown_error), do: :error
  defp error_type_to_log_level(_), do: :error
end
