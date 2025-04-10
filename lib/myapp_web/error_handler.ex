defmodule MyappWeb.ErrorHandler do
  @moduledoc """
  Handles errors in the web layer of the application.

  This module provides functions for converting application errors
  into appropriate HTTP responses. It works with the standardized
  error format provided by `Myapp.ErrorHandler`.

  ## Usage

  ```elixir
  # In a controller
  def show(conn, %{"id" => id}) do
    case Myapp.Accounts.get_user(id) do
      {:ok, user} ->
        render(conn, :show, user: user)

      {:error, error} ->
        MyappWeb.ErrorHandler.handle_error(conn, error)
    end
  end
  ```
  """

  import Plug.Conn
  import Phoenix.Controller

  alias Myapp.ErrorHandler
  alias Myapp.Monitoring.Sentry

  @doc """
  Handles an error by rendering an appropriate response.

  This function takes an error and renders an appropriate response
  based on the error type and the requested format (HTML, JSON, etc.).

  ## Parameters

  - `conn`: The connection
  - `error`: The error to handle
  - `opts`: Additional options (optional)

  ## Options

  - `:format`: The format to render (:html, :json, or :api)
  - `:view`: The view module to use for rendering
  - `:layout`: The layout to use for HTML rendering

  ## Examples

      iex> error = Myapp.ErrorHandler.error(:not_found, "User not found")
      iex> MyappWeb.ErrorHandler.handle_error(conn, error)
      # Renders a 404 response
  """
  def handle_error(conn, error, opts \\ []) do
    # Normalize the error if it's not already in the standard format
    error = normalize_error(error)

    # Set request context for Sentry
    Sentry.set_request_context(conn)

    # Set user context if available
    if conn.assigns[:current_user] do
      Sentry.set_user_context(conn.assigns.current_user)
    end

    # Determine the format based on the request or the provided option
    format = opts[:format] || request_format(conn)

    # Handle the error based on the format
    case format do
      :html -> handle_html_error(conn, error, opts)
      :json -> handle_json_error(conn, error, opts)
      :api -> handle_api_error(conn, error, opts)
      _ -> handle_json_error(conn, error, opts)  # Default to JSON
    end
  end

  @doc """
  Handles an error by returning a JSON response.

  ## Parameters

  - `conn`: The connection
  - `error`: The error to handle
  - `opts`: Additional options (optional)

  ## Examples

      iex> error = Myapp.ErrorHandler.error(:not_found, "User not found")
      iex> MyappWeb.ErrorHandler.handle_json_error(conn, error)
      # Returns a JSON response with status 404 and the error details
  """
  def handle_json_error(conn, error, _opts \\ []) do
    status = error_type_to_status(error.type)

    conn
    |> put_status(status)
    |> put_view(json: MyappWeb.Error.ErrorJSON)
    |> render(:error, error: error)
  end

  @doc """
  Handles an error by rendering an HTML error page.

  ## Parameters

  - `conn`: The connection
  - `error`: The error to handle
  - `opts`: Additional options (optional)

  ## Examples

      iex> error = Myapp.ErrorHandler.error(:not_found, "User not found")
      iex> MyappWeb.ErrorHandler.handle_html_error(conn, error)
      # Renders the 404.html template
  """
  def handle_html_error(conn, error, opts \\ []) do
    status = error_type_to_status(error.type)
    view = opts[:view] || MyappWeb.Error.ErrorHTML
    layout = opts[:layout] || false

    conn
    |> put_status(status)
    |> put_view(html: view)
    |> put_layout(layout)
    |> render(:"#{status}", error: error)
  end

  @doc """
  Handles an error by returning an API-friendly JSON response.

  This is similar to `handle_json_error/3` but formats the response
  in a way that's more suitable for API consumers.

  ## Parameters

  - `conn`: The connection
  - `error`: The error to handle
  - `opts`: Additional options (optional)

  ## Examples

      iex> error = Myapp.ErrorHandler.error(:not_found, "User not found")
      iex> MyappWeb.ErrorHandler.handle_api_error(conn, error)
      # Returns a JSON response with status 404 and a standardized error format
  """
  def handle_api_error(conn, error, _opts \\ []) do
    status = error_type_to_status(error.type)

    response = %{
      error: %{
        type: error.type,
        message: error.message,
        status: status
      }
    }

    # Add details for non-production environments
    response = if Application.get_env(:myapp, :env) != :prod do
      put_in(response, [:error, :details], error.details)
    else
      response
    end

    conn
    |> put_status(status)
    |> json(response)
  end

  # Private functions

  defp normalize_error(%{type: _type, message: _message} = error) do
    # Already a standard error struct
    error
  end

  defp normalize_error(error) do
    case ErrorHandler.normalize(error) do
      {:error, normalized_error} -> normalized_error
      other -> ErrorHandler.error(:unknown_error, "Unknown error: #{inspect(other)}")
    end
  end

  defp error_type_to_status(:not_found), do: 404
  defp error_type_to_status(:unauthorized), do: 401
  defp error_type_to_status(:forbidden), do: 403
  defp error_type_to_status(:validation_error), do: 422
  defp error_type_to_status(:rate_limited), do: 429
  defp error_type_to_status(:bad_request), do: 400
  defp error_type_to_status(:timeout), do: 504
  defp error_type_to_status(:service_unavailable), do: 503
  defp error_type_to_status(:internal_error), do: 500
  defp error_type_to_status(:system_error), do: 500
  defp error_type_to_status(:not_implemented), do: 501
  defp error_type_to_status(_), do: 500

  defp request_format(conn) do
    # Check the Accept header
    accepts = get_req_header(conn, "accept")

    cond do
      accepts_json?(accepts) -> :json
      accepts_html?(accepts) -> :html
      true -> :json  # Default to JSON
    end
  end

  defp accepts_json?(accepts) do
    Enum.any?(accepts, fn accept ->
      String.contains?(accept, "application/json") ||
      String.contains?(accept, "application/vnd.api+json")
    end)
  end

  defp accepts_html?(accepts) do
    Enum.any?(accepts, fn accept ->
      String.contains?(accept, "text/html") ||
      String.contains?(accept, "*/*")
    end)
  end
end
