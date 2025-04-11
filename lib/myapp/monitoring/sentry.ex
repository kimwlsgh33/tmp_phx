defmodule Myapp.Monitoring.Sentry do
  @moduledoc """
  Integration with Sentry for error monitoring.
  
  This module provides functions to report errors to Sentry with
  appropriate context and metadata.
  """
  
  @doc """
  Reports an error to Sentry.
  
  ## Parameters
  
  - `error`: The error struct from ErrorHandler
  - `extra_context`: Additional context to include (optional)
  
  ## Examples
  
      iex> error = ErrorHandler.error(:not_found, "User not found")
      iex> Myapp.Monitoring.Sentry.report_error(error)
  """
  def report_error(%{type: _type, message: _message} = error, extra_context \\ %{}) do
    # Convert our error format to something Sentry expects
    exception = 
      case error.type do
        :validation_error -> 
          %Ecto.InvalidChangesetError{changeset: Map.get(error.details, :changeset, %{})}
        :not_found -> 
          %Ecto.NoResultsError{message: error.message}
        :unauthorized -> 
          %RuntimeError{message: "Unauthorized: #{error.message}"}
        :forbidden -> 
          %RuntimeError{message: "Forbidden: #{error.message}"}
        :rate_limited -> 
          %RuntimeError{message: "Rate Limited: #{error.message}"}
        :database_error -> 
          %DBConnection.ConnectionError{message: error.message}
        _ -> 
          %RuntimeError{message: error.message}
      end
    
    # Prepare extra context
    context = Map.merge(
      %{
        error_type: error.type,
        source: inspect(error.source),
        timestamp: DateTime.to_string(error.timestamp),
        details: error.details
      },
      extra_context
    )
    
    # Report to Sentry
    Sentry.capture_exception(
      exception,
      [
        tags: %{error_type: error.type},
        extra: context
      ]
    )
  end
  
  @doc """
  Sets the user context for Sentry.
  
  ## Parameters
  
  - `user`: The user struct or map with user information
  
  ## Examples
  
      iex> Myapp.Monitoring.Sentry.set_user_context(%{id: 123, email: "user@example.com"})
  """
  def set_user_context(%{id: id} = user) do
    Sentry.Context.set_user_context(%{
      id: id,
      email: Map.get(user, :email),
      username: Map.get(user, :username)
    })
  end
  
  def set_user_context(_), do: :ok
  
  @doc """
  Sets request context for Sentry.
  
  ## Parameters
  
  - `conn`: The connection struct
  
  ## Examples
  
      iex> Myapp.Monitoring.Sentry.set_request_context(conn)
  """
  def set_request_context(conn) do
    Sentry.Context.set_request_context(%{
      url: "#{conn.scheme}://#{conn.host}#{conn.request_path}",
      method: conn.method,
      headers: conn.req_headers,
      query_string: conn.query_string
    })
  end
  
  @doc """
  Clears all context from Sentry.
  """
  def clear_context do
    Sentry.Context.clear_all()
  end
end
