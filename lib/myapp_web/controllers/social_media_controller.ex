defmodule MyappWeb.SocialMediaController do
  @moduledoc """
  Base controller module for social media integrations.
  
  Provides common controller logic and functions that can be used by
  platform-specific controllers (Twitter, TikTok, Instagram, YouTube, etc.).
  
  This module standardizes:
  - OAuth authentication flows
  - Media upload validations
  - Error handling
  - Token storage/retrieval
  - Common social media operations
  """
  use MyappWeb, :controller

  alias Myapp.SocialMediaConfig
  
  @doc """
  Validates the requested provider and returns the corresponding modules
  for social auth and social media API interactions.
  """
  def validate_provider(provider) when is_binary(provider) do
    case SocialMediaConfig.get_provider_modules(provider) do
      {:ok, %{auth_module: auth_module, api_module: api_module}} -> 
        {:ok, auth_module, api_module}
      {:error, reason} -> 
        {:error, reason}
    end
  end
  
  def validate_provider(_), do: {:error, :invalid_provider}

  @doc """
  Common function to handle OAuth connection initiation.
  Generates an authorization URL and redirects the user to it.
  
  ## Parameters
    * `conn` - The connection struct
    * `provider` - The social media provider (string)
    * `params` - Optional parameters for the authorization URL
  """
  def handle_connect(conn, provider, params \\ %{}) do
    with {:ok, auth_module, _} <- validate_provider(provider),
         {:ok, auth_url} <- auth_module.authorization_url(params) do
      redirect(conn, external: auth_url)
    else
      {:error, :invalid_provider} ->
        conn
        |> put_flash(:error, "Invalid social media provider")
        |> redirect(to: ~p"/")
      
      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to connect to #{provider}: #{inspect(reason)}")
        |> redirect(to: ~p"/#{provider}")
    end
  end

  @doc """
  Common function to handle OAuth callback.
  Exchanges the authorization code for access tokens and stores them.
  
  ## Parameters
    * `conn` - The connection struct
    * `provider` - The social media provider (string)
    * `params` - Callback parameters including the authorization code
  """
  def handle_auth_callback(conn, provider, params) do
    with {:ok, auth_module, _api_module} <- validate_provider(provider),
         {:ok, tokens} <- auth_module.exchange_token(params),
         {:ok, conn} <- store_tokens(conn, provider, tokens) do
      conn
      |> put_flash(:info, "Successfully connected to #{provider}")
      |> redirect(to: ~p"/#{provider}")
    else
      {:error, :invalid_provider} ->
        conn
        |> put_flash(:error, "Invalid social media provider")
        |> redirect(to: ~p"/")
      
      {:error, reason} ->
        conn
        |> put_flash(:error, "Authentication failed with #{provider}: #{inspect(reason)}")
        |> redirect(to: ~p"/#{provider}")
    end
  end

  @doc """
  Common function to check if a user is authenticated with a provider.
  
  ## Parameters
    * `conn` - The connection struct
    * `provider` - The social media provider (string)
    * `user_id` - Optional user ID for multi-user systems
  """
  def check_auth(conn, provider, user_id \\ nil) do
    with {:ok, _auth_module, api_module} <- validate_provider(provider),
         {:ok, tokens} <- get_tokens(conn, provider, user_id),
         {:ok, status} <- api_module.verify_auth(tokens) do
      {:ok, status}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Common function to handle post creation across social media platforms.
  
  ## Parameters
    * `conn` - The connection struct
    * `provider` - The social media provider (string)
    * `content` - The post content
    * `params` - Additional parameters for the post
    * `user_id` - Optional user ID for multi-user systems
  """
  def handle_post(conn, provider, content, params, user_id \\ nil) do
    with {:ok, _auth_module, api_module} <- validate_provider(provider),
         {:ok, tokens} <- get_tokens(conn, provider, user_id),
         {:ok, post_result} <- api_module.create_post(tokens, content, params) do
      {:ok, post_result}
    else
      {:error, :not_authenticated} ->
        conn
        |> put_flash(:error, "You need to connect your #{provider} account first")
        |> redirect(to: ~p"/#{provider}")
        |> halt()
      
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Common function to handle media uploads across social media platforms.
  
  ## Parameters
    * `conn` - The connection struct
    * `provider` - The social media provider (string)
    * `media_path` - Path to the media file
    * `options` - Additional options for the upload
    * `user_id` - Optional user ID for multi-user systems
  """
  def handle_media_upload(conn, provider, media_path, options \\ [], user_id \\ nil) do
    with {:ok, _auth_module, api_module} <- validate_provider(provider),
         {:ok, tokens} <- get_tokens(conn, provider, user_id),
         {:ok, media_result} <- api_module.upload_media(tokens, media_path, options) do
      {:ok, media_result}
    else
      {:error, :not_authenticated} ->
        conn
        |> put_flash(:error, "You need to connect your #{provider} account first")
        |> redirect(to: ~p"/#{provider}")
        |> halt()
      
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Validates media upload by checking file existence and format.
  Returns the file path and media type if valid.
  
  ## Parameters
    * `params` - The upload parameters containing media file
  """
  def validate_media_upload(params) do
    case extract_media_upload(params) do
      {:ok, %Plug.Upload{path: path, content_type: content_type}} ->
        validate_media_format(path, content_type)
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Parse hashtags from a comma-separated string into a list.
  Returns an empty list if input is not a string.
  """
  def parse_hashtags(hashtags_string) when is_binary(hashtags_string) do
    hashtags_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(String.length(&1) > 0))
  end
  def parse_hashtags(_), do: []
  
  @doc """
  Gets the current user ID from the connection.
  Implementations may override this to use their own user identification system.
  """
  def get_current_user_id(conn) do
    # Default implementation - override in specific controllers if needed
    conn.assigns[:current_user_id] || "default_user"
  end
  
  @doc """
  Calculates token expiry datetime from seconds.
  """
  def get_expiry_datetime(expires_in) when is_integer(expires_in) do
    DateTime.add(DateTime.utc_now(), expires_in, :second)
  end
  def get_expiry_datetime(expires_in) when is_binary(expires_in) do
    case Integer.parse(expires_in) do
      {seconds, _} -> get_expiry_datetime(seconds)
      :error -> DateTime.add(DateTime.utc_now(), 30 * 24 * 60 * 60, :second) # Default to 30 days
    end
  end
  def get_expiry_datetime(_), do: DateTime.add(DateTime.utc_now(), 30 * 24 * 60 * 60, :second)

  # Private functions

  @doc false
  defp store_tokens(conn, provider, tokens) do
    # This implementation can be adapted based on whether you're using
    # sessions or database storage for tokens
    conn = put_session(conn, "#{provider}_tokens", tokens)
    {:ok, conn}
  end

  @doc false
  defp get_tokens(conn, provider, _user_id \\ nil) do
    case get_session(conn, "#{provider}_tokens") do
      nil -> {:error, :not_authenticated}
      tokens -> {:ok, tokens}
    end
  end
  
  @doc false
  defp extract_media_upload(%{"media" => %Plug.Upload{} = upload}), do: {:ok, upload}
  defp extract_media_upload(%{media: %Plug.Upload{} = upload}), do: {:ok, upload}
  defp extract_media_upload(%{"media" => nil}), do: {:error, "No media file uploaded"}
  defp extract_media_upload(%{media: nil}), do: {:error, "No media file uploaded"}
  defp extract_media_upload(_), do: {:error, "No media file uploaded or invalid format"}
  
  @doc false
  defp validate_media_format(path, content_type) do
    cond do
      content_type in ["image/jpeg", "image/png", "image/jpg"] ->
        {:ok, path, "image"}
      content_type in ["video/mp4", "video/quicktime", "video/mov"] ->
        {:ok, path, "video"}
      true ->
        {:error, "Invalid file format. Only JPEG, PNG images and MP4, MOV videos are supported."}
    end
  end
end
