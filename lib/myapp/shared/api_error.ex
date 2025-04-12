defmodule Myapp.Shared.ApiError do
  @moduledoc """
  Specialized error handling for API interactions.

  This module provides functions for handling errors from external APIs,
  particularly social media platforms. It normalizes different error formats
  from various APIs into a consistent structure.

  ## Usage

  ```elixir
  # Handle an HTTP response
  case HTTPoison.get(url, headers) do
    {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
      Myapp.ApiError.handle_response(status, body, :twitter)

    {:error, %HTTPoison.Error{} = error} ->
      Myapp.ApiError.handle_http_error(error, :twitter)
  end
  ```
  """

  # alias Myapp.Shared.ErrorHandler  # Uncomment when needed

  @doc """
  Handles an HTTP response based on status code and body.

  ## Parameters

  - `status_code`: The HTTP status code
  - `body`: The response body (usually JSON)
  - `provider`: The API provider (e.g., `:twitter`, `:tiktok`)
  - `context`: Additional context for the error (optional)

  ## Examples

      iex> Myapp.ApiError.handle_response(200, ~s({"data": {"id": "123"}}), :twitter)
      {:ok, %{"data" => %{"id" => "123"}}}

      iex> Myapp.ApiError.handle_response(404, ~s({"errors": [{"message": "Not found"}]}), :twitter)
      {:error, %{type: :not_found, message: "Not found", details: %{provider: :twitter, status_code: 404, response: %{"errors" => [%{"message" => "Not found"}]}}, source: Myapp.ApiError, timestamp: ~U[2023-01-01 00:00:00Z]}}
  """
  def handle_response(status_code, body, provider, context \\ %{}) when is_integer(status_code) do
    cond do
      status_code in 200..299 ->
        parse_success_response(body)

      status_code == 401 ->
        handle_unauthorized(body, provider, context)

      status_code == 403 ->
        handle_forbidden(body, provider, context)

      status_code == 404 ->
        handle_not_found(body, provider, context)

      status_code == 422 ->
        handle_validation_error(body, provider, context)

      status_code == 429 ->
        handle_rate_limit(body, provider, context)

      status_code >= 500 ->
        handle_server_error(body, provider, context, status_code)

      true ->
        handle_unknown_error(body, provider, context, status_code)
    end
  end

  @doc """
  Handles an HTTP client error.

  ## Parameters

  - `error`: The HTTPoison error
  - `provider`: The API provider (e.g., `:twitter`, `:tiktok`)
  - `context`: Additional context for the error (optional)

  ## Examples

      iex> Myapp.ApiError.handle_http_error(%HTTPoison.Error{reason: :timeout}, :twitter)
      {:error, %{type: :timeout, message: "API request timed out", details: %{provider: :twitter, reason: :timeout}, source: Myapp.ApiError, timestamp: ~U[2023-01-01 00:00:00Z]}}
  """
  def handle_http_error(%HTTPoison.Error{reason: reason}, provider, context \\ %{}) do
    details = Map.merge(%{provider: provider, reason: reason}, context)

    error_type = case reason do
      :timeout -> :timeout
      :econnrefused -> :service_unavailable
      :closed -> :connection_closed
      _ -> :http_error
    end

    message = case reason do
      :timeout -> "API request timed out"
      :econnrefused -> "Connection refused by the server"
      :closed -> "Connection closed unexpectedly"
      _ -> "HTTP request failed: #{inspect(reason)}"
    end

    {:error, Myapp.Shared.ErrorHandler.error(error_type, message, details, __MODULE__)}
  end

  @doc """
  Normalizes errors from different social media APIs into a consistent format.

  ## Parameters

  - `status_code`: The HTTP status code
  - `body`: The response body (usually JSON string)
  - `provider`: The API provider (e.g., `:twitter`, `:tiktok`)

  ## Examples

      iex> Myapp.ApiError.normalize_error(429, ~s({"errors":[{"code":88,"message":"Rate limit exceeded"}]}), :twitter)
      %{type: :rate_limited, message: "Rate limit exceeded", details: %{provider: :twitter, status_code: 429, error_code: 88}}
  """
  def normalize_error(status_code, body, provider) when is_binary(body) do
    # Parse the body if it's a JSON string
    case Jason.decode(body) do
      {:ok, parsed_body} ->
        normalize_error(status_code, parsed_body, provider)

      {:error, _} ->
        # If it's not valid JSON, create a generic error
        %{
          type: status_code_to_type(status_code),
          message: "API error with status code #{status_code}",
          details: %{
            provider: provider,
            status_code: status_code,
            body: body
          }
        }
    end
  end

  def normalize_error(status_code, body, provider) when is_map(body) do
    # Extract error information based on the provider
    {error_type, message, details} = case provider do
      :twitter -> extract_twitter_error(status_code, body)
      :tiktok -> extract_tiktok_error(status_code, body)
      :instagram -> extract_instagram_error(status_code, body)
      :youtube -> extract_youtube_error(status_code, body)
      _ -> extract_generic_error(status_code, body)
    end

    # Create the standardized error
    %{
      type: error_type,
      message: message,
      details: Map.merge(details, %{provider: provider, status_code: status_code})
    }
  end

  # Private functions

  defp parse_success_response(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, parsed_body} -> {:ok, parsed_body}
      {:error, _} -> {:ok, body}  # Not JSON, return as is
    end
  end

  defp parse_success_response(body), do: {:ok, body}  # Already parsed or not JSON

  defp handle_unauthorized(body, provider, context) do
    error = body
            |> normalize_error(401, provider)
            |> Map.merge(%{type: :unauthorized})
            |> Map.update!(:details, &Map.merge(&1, context))

    {:error, Myapp.Shared.ErrorHandler.error(
      error.type,
      error.message,
      error.details,
      __MODULE__
    )}
  end

  defp handle_forbidden(body, provider, context) do
    error = body
            |> normalize_error(403, provider)
            |> Map.merge(%{type: :forbidden})
            |> Map.update!(:details, &Map.merge(&1, context))

    {:error, Myapp.Shared.ErrorHandler.error(
      error.type,
      error.message,
      error.details,
      __MODULE__
    )}
  end

  defp handle_not_found(body, provider, context) do
    error = body
            |> normalize_error(404, provider)
            |> Map.merge(%{type: :not_found})
            |> Map.update!(:details, &Map.merge(&1, context))

    {:error, Myapp.Shared.ErrorHandler.error(
      error.type,
      error.message,
      error.details,
      __MODULE__
    )}
  end

  defp handle_validation_error(body, provider, context) do
    error = body
            |> normalize_error(422, provider)
            |> Map.merge(%{type: :validation_error})
            |> Map.update!(:details, &Map.merge(&1, context))

    {:error, Myapp.Shared.ErrorHandler.error(
      error.type,
      error.message,
      error.details,
      __MODULE__
    )}
  end

  defp handle_rate_limit(body, provider, context) do
    error = body
            |> normalize_error(429, provider)
            |> Map.merge(%{type: :rate_limited})
            |> Map.update!(:details, &Map.merge(&1, context))

    {:error, Myapp.Shared.ErrorHandler.error(
      error.type,
      error.message,
      error.details,
      __MODULE__
    )}
  end

  defp handle_server_error(body, provider, context, status_code) do
    error = body
            |> normalize_error(status_code, provider)
            |> Map.merge(%{type: :service_unavailable})
            |> Map.update!(:details, &Map.merge(&1, context))

    {:error, Myapp.Shared.ErrorHandler.error(
      error.type,
      error.message,
      error.details,
      __MODULE__
    )}
  end

  defp handle_unknown_error(body, provider, context, status_code) do
    error = body
            |> normalize_error(status_code, provider)
            |> Map.update!(:details, &Map.merge(&1, context))

    {:error, Myapp.Shared.ErrorHandler.error(
      error.type,
      error.message,
      error.details,
      __MODULE__
    )}
  end

  defp status_code_to_type(status_code) do
    case status_code do
      400 -> :bad_request
      401 -> :unauthorized
      403 -> :forbidden
      404 -> :not_found
      422 -> :validation_error
      429 -> :rate_limited
      s when s >= 500 -> :service_unavailable
      _ -> :api_error
    end
  end

  # Provider-specific error extractors

  defp extract_twitter_error(status_code, body) do
    # Twitter error format: {"errors": [{"code": 88, "message": "Rate limit exceeded"}]}
    error_type = status_code_to_type(status_code)

    errors = get_in(body, ["errors"]) || []
    error = List.first(errors) || %{}

    message = error["message"] || "Twitter API error"
    error_code = error["code"]

    details = if error_code, do: %{error_code: error_code}, else: %{}
    details = Map.merge(details, %{response: body})

    # Refine error type based on Twitter-specific error codes
    error_type = case error_code do
      88 -> :rate_limited
      32 -> :unauthorized  # Could not authenticate you
      64 -> :account_suspended
      89 -> :token_expired  # Invalid or expired token
      _ -> error_type
    end

    {error_type, message, details}
  end

  defp extract_tiktok_error(status_code, body) do
    # TikTok error format: {"error_code": 10000, "error_message": "Error message"}
    error_type = status_code_to_type(status_code)

    error_code = body["error_code"]
    message = body["error_message"] || "TikTok API error"

    details = if error_code, do: %{error_code: error_code}, else: %{}
    details = Map.merge(details, %{response: body})

    # Refine error type based on TikTok-specific error codes
    error_type = case error_code do
      10000 -> :internal_error  # Internal error
      10002 -> :rate_limited  # Rate limit reached
      10004 -> :unauthorized  # Invalid access token
      _ -> error_type
    end

    {error_type, message, details}
  end

  defp extract_instagram_error(status_code, body) do
    # Instagram/Facebook error format: {"error": {"type": "OAuthException", "message": "Error message", "code": 190}}
    error_type = status_code_to_type(status_code)

    error = body["error"] || %{}
    message = error["message"] || "Instagram API error"
    error_code = error["code"]
    error_subcode = error["error_subcode"]

    details = %{response: body}
    details = if error_code, do: Map.put(details, :error_code, error_code), else: details
    details = if error_subcode, do: Map.put(details, :error_subcode, error_subcode), else: details

    # Refine error type based on Instagram/Facebook-specific error codes
    error_type = case error_code do
      4 -> :rate_limited  # Application request limit reached
      190 -> :token_expired  # Invalid OAuth access token
      10 -> :api_error  # Application does not have permission
      _ -> error_type
    end

    {error_type, message, details}
  end

  defp extract_youtube_error(status_code, body) do
    # YouTube/Google error format: {"error": {"errors": [{"reason": "rateLimitExceeded", "message": "Rate limit exceeded"}], "code": 429}}
    error_type = status_code_to_type(status_code)

    error = body["error"] || %{}
    errors = error["errors"] || []
    first_error = List.first(errors) || %{}

    message = first_error["message"] || error["message"] || "YouTube API error"
    reason = first_error["reason"]
    error_code = error["code"]

    details = %{response: body}
    details = if reason, do: Map.put(details, :reason, reason), else: details
    details = if error_code, do: Map.put(details, :error_code, error_code), else: details

    # Refine error type based on YouTube/Google-specific error reasons
    error_type = case reason do
      "rateLimitExceeded" -> :rate_limited
      "authError" -> :unauthorized
      "forbidden" -> :forbidden
      "notFound" -> :not_found
      _ -> error_type
    end

    {error_type, message, details}
  end

  defp extract_generic_error(status_code, body) do
    # Generic error handling for unknown API formats
    error_type = status_code_to_type(status_code)

    # Try to find an error message in common locations
    message = body["message"] ||
              body["error"] ||
              body["error_message"] ||
              get_in(body, ["error", "message"]) ||
              "API error with status code #{status_code}"

    # If message is a map or list, convert to string
    message = if is_binary(message), do: message, else: inspect(message)

    {error_type, message, %{response: body}}
  end
end
