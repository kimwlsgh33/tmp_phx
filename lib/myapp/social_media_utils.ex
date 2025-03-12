defmodule Myapp.SocialMediaUtils do
  @moduledoc """
  Provides common utility functions for social media operations across different platforms.
  Contains shared functionality for file handling, HTTP requests, rate limiting, and error normalization.
  """

  require Logger
  alias Myapp.SocialMediaConfig

  @doc """
  Validates file types for social media uploads.
  Returns `{:ok, mimetype}` if the file is valid, or `{:error, reason}` if not.

  ## Examples

      iex> validate_file_type(%{"content_type" => "image/jpeg"})
      {:ok, "image/jpeg"}

      iex> validate_file_type(%{"content_type" => "application/exe"})
      {:error, :invalid_file_type}
  """
  def validate_file_type(%{"content_type" => content_type}) do
    valid_types = [
      # Images
      "image/jpeg",
      "image/png",
      "image/gif",
      # Videos
      "video/mp4",
      "video/quicktime",
      "video/x-msvideo",
      # Audio
      "audio/mpeg",
      "audio/mp4",
      "audio/wav"
    ]

    if content_type in valid_types do
      {:ok, content_type}
    else
      {:error, :invalid_file_type}
    end
  end
  def validate_file_type(_), do: {:error, :invalid_file}

  @doc """
  Validates file size for social media uploads.
  Returns `:ok` if the file size is valid, or `{:error, reason}` if not.

  ## Examples

      iex> validate_file_size(%{size: 1_000_000}, :image)
      :ok

      iex> validate_file_size(%{size: 100_000_000}, :image)
      {:error, :file_too_large}
  """
  def validate_file_size(%{size: size}, media_type) do
    max_size = case media_type do
      :image -> 10 * 1024 * 1024  # 10MB for images
      :video -> 500 * 1024 * 1024 # 500MB for videos
      :audio -> 50 * 1024 * 1024  # 50MB for audio
      _ -> 5 * 1024 * 1024        # 5MB default
    end

    if size <= max_size do
      :ok
    else
      {:error, :file_too_large}
    end
  end
  def validate_file_size(_, _), do: {:error, :invalid_file}

  @doc """
  Processes a file from a Phoenix upload and prepares it for social media posting.
  Returns `{:ok, binary, filename}` or `{:error, reason}`.
  """
  def process_upload_file(upload, opts \\ []) do
    with {:ok, content_type} <- validate_file_type(upload),
         media_type = determine_media_type(content_type),
         :ok <- validate_file_size(upload, media_type),
         {:ok, binary} <- File.read(upload.path) do
      filename = opts[:filename] || Path.basename(upload.filename)
      {:ok, binary, filename}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Determines the media type (image, video, audio) from a content type.
  """
  def determine_media_type(content_type) do
    cond do
      String.starts_with?(content_type, "image/") -> :image
      String.starts_with?(content_type, "video/") -> :video
      String.starts_with?(content_type, "audio/") -> :audio
      true -> :other
    end
  end

  @doc """
  Makes an HTTP request with retry logic and rate limiting awareness.
  """
  def make_request(method, url, body \\ "", headers \\ [], opts \\ []) do
    max_retries = opts[:max_retries] || 3
    retry_delay = opts[:retry_delay] || 1000

    do_request(method, url, body, headers, max_retries, retry_delay)
  end

  defp do_request(_method, _url, _body, _headers, 0, _retry_delay) do
    {:error, :max_retries_reached}
  end

  defp do_request(method, url, body, headers, retries, retry_delay) do
    response = HTTPoison.request(method, url, body, headers)

    case response do
      {:ok, %{status_code: status_code, body: body}} when status_code in 200..299 ->
        {:ok, body}

      {:ok, %{status_code: 429}} ->
        # Rate limited - wait and retry
        Logger.warning(fn -> "Rate limited by API. Retrying after delay..." end)
        :timer.sleep(retry_delay)
        do_request(method, url, body, headers, retries - 1, retry_delay * 2)

      {:ok, %{status_code: status_code, body: body}} ->
        {:error, normalize_error(status_code, body)}

      {:error, %{reason: reason}} ->
        if retries > 1 do
          Logger.warning(fn -> "HTTP request failed: #{inspect(reason)}. Retrying..." end)
          :timer.sleep(retry_delay)
          do_request(method, url, body, headers, retries - 1, retry_delay)
        else
          {:error, reason}
        end
    end
  end

  @doc """
  Normalizes errors from different social media APIs into a consistent format.
  """
  def normalize_error(status_code, body) do
    # Attempt to parse the body as JSON
    case Jason.decode(body) do
      {:ok, parsed_body} ->
        %{
          status_code: status_code,
          error_type: extract_error_type(parsed_body),
          message: extract_error_message(parsed_body),
          raw: parsed_body
        }

      _ ->
        %{
          status_code: status_code,
          error_type: :unknown_error,
          message: "Unknown error occurred",
          raw: body
        }
    end
  end

  defp extract_error_type(parsed_body) do
    cond do
      # Twitter style
      Map.has_key?(parsed_body, "errors") -> 
        get_in(parsed_body, ["errors", Access.at(0), "code"]) || :api_error
      
      # Facebook/Instagram style
      Map.has_key?(parsed_body, "error") -> 
        get_in(parsed_body, ["error", "type"]) || :api_error
      
      # TikTok style
      Map.has_key?(parsed_body, "error_code") ->
        parsed_body["error_code"] || :api_error
      
      true -> :unknown_error
    end
  end

  defp extract_error_message(parsed_body) do
    cond do
      # Twitter style
      Map.has_key?(parsed_body, "errors") -> 
        get_in(parsed_body, ["errors", Access.at(0), "message"]) || "Unknown error"
      
      # Facebook/Instagram style
      Map.has_key?(parsed_body, "error") -> 
        get_in(parsed_body, ["error", "message"]) || "Unknown error"
      
      # TikTok style
      Map.has_key?(parsed_body, "error_message") ->
        parsed_body["error_message"] || "Unknown error"
      
      true -> "Unknown error"
    end
  end

  @doc """
  Implements a token bucket rate limiter for API calls.
  """
  def check_rate_limit(bucket, tokens_per_interval, interval_ms) do
    now = :os.system_time(:milli_seconds)
    
    case :ets.lookup(:social_media_rate_limits, bucket) do
      [] ->
        # First request, initialize the bucket
        :ets.insert(:social_media_rate_limits, {bucket, now, tokens_per_interval - 1})
        :ok

      [{^bucket, last_updated, tokens}] ->
        time_passed = now - last_updated
        periods_passed = div(time_passed, interval_ms)
        
        new_tokens = min(tokens_per_interval, tokens + periods_passed * tokens_per_interval)
        
        if new_tokens > 0 do
          :ets.insert(:social_media_rate_limits, {bucket, now, new_tokens - 1})
          :ok
        else
          # Calculate time until next token is available
          wait_time = interval_ms - rem(time_passed, interval_ms)
          {:rate_limited, wait_time}
        end
    end
  end

  @doc """
  Initializes the rate limiting ETS table.
  Should be called when the application starts.
  """
  def init_rate_limiting do
    :ets.new(:social_media_rate_limits, [:set, :public, :named_table])
    :ok
  end

  @doc """
  Generates a random string for use in OAuth state parameters or other security needs.
  """
  def random_string(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64()
    |> binary_part(0, length)
  end
  
  @doc """
  Builds a query string from a map of parameters.
  """
  def build_query_string(params) when is_map(params) do
    params
    |> Enum.map(fn {k, v} -> "#{URI.encode_www_form(to_string(k))}=#{URI.encode_www_form(to_string(v))}" end)
    |> Enum.join("&")
  end
  
  @doc """
  Handles common social media API errors and translates them to user-friendly messages.
  """
  def user_friendly_error_message(error) do
    case error do
      {:error, :invalid_file_type} ->
        "The file type you've selected isn't supported. Please use JPEG, PNG, GIF, MP4, or other common media formats."
        
      {:error, :file_too_large} ->
        "The file you've selected is too large. Images should be under 10MB, videos under 500MB."
        
      {:error, :max_retries_reached} ->
        "We're having trouble connecting to the social media service. Please try again later."
        
      {:error, %{error_type: :rate_limit_exceeded}} ->
        "You've reached the rate limit for this social media platform. Please try again later."
        
      {:error, %{error_type: :invalid_token}} ->
        "Your connection to this social media account has expired. Please reconnect your account."
        
      {:error, %{error_type: :permission_denied}} ->
        "You don't have permission to perform this action. You may need to reconnect your account with additional permissions."
        
      {:error, _} ->
        "An unexpected error occurred. Please try again later."
        
      _ ->
        "An unknown error occurred. Please try again later."
    end
  end
end

