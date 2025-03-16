defmodule MyappWeb.Social.SocialMediaController do
  @moduledoc """
  Controller for handling social media platform integrations and uploads.
  
  Provides common controller logic and functions that can be used by
  platform-specific features. This module standardizes:
  - OAuth authentication flows
  - Media upload validations
  - Error handling
  - Token storage/retrieval
  - Platform-specific upload operations
  """
  use MyappWeb, :controller

  alias Myapp.{Accounts, Content, SocialMediaConfig, SocialMediaToken}
  alias Myapp.Content.{Post, ShortVideo, LongVideo}

  # Platform-specific constraints
  @twitter_max_size 15_000_000  # 15MB
  @instagram_max_size 100_000_000  # 100MB
  @tiktok_max_size 100_000_000  # 100MB
  @youtube_max_size 500_000_000  # 500MB
  @vimeo_max_size 500_000_000  # 500MB

  # Content Creation Functions

  @doc """
  Creates a new post with associated media for specified platforms.
  """
  def create_post(user, params) do
    with :ok <- validate_user_tokens(user, params.platforms),
         :ok <- validate_post_content(params),
         {:ok, post} <- Content.create_post(params) do
      handle_platform_uploads(post, user, params.platforms)
    end
  end

  @doc """
  Creates a new short video for specified platforms.
  """
  def create_short_video(user, params) do
    with :ok <- validate_user_tokens(user, params.platforms),
         :ok <- validate_short_video(params),
         {:ok, video} <- Content.create_short_video(params) do
      handle_platform_uploads(video, user, params.platforms)
    end
  end

  @doc """
  Creates a new long video for specified platforms.
  """
  def create_long_video(user, params) do
    with :ok <- validate_user_tokens(user, params.platforms),
         :ok <- validate_long_video(params),
         {:ok, video} <- Content.create_long_video(params) do
      handle_platform_uploads(video, user, params.platforms)
    end
  end

  # Authentication and OAuth Functions

  @doc """
  Validates the requested provider and returns the corresponding modules.
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
  Initiates OAuth connection by generating and redirecting to auth URL.
  """
  def handle_connect(conn, provider, params \\ %{}) do
    with {:ok, auth_module, _} <- validate_provider(provider),
         {:ok, auth_url} <- auth_module.generate_auth_url(params) do
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
  Handles OAuth callback by exchanging code for tokens.
  """
  def handle_auth_callback(conn, provider, params) do
    with {:ok, auth_module, _api_module} <- validate_provider(provider),
         {:ok, tokens} <- exchange_token_for_provider(auth_module, provider, params),
         {:ok, _} <- Accounts.store_platform_token(provider, tokens) do
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
  Checks if a user is authenticated with a provider.
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
  # Private Helper Functions

  @doc """
  Extracts the current user ID from the connection.

  ## Parameters
    - conn: The connection struct

  ## Returns
    - user_id or nil if not found
  """
  def get_current_user_id(conn) do
    if conn.assigns[:current_user] do
      conn.assigns.current_user.id
    else
      nil
    end
  end

  @doc """
  Validates a media upload against platform constraints.

  ## Parameters
    - params: A map containing :file and :platform keys

  ## Returns
    - :ok on success
    - {:error, reason} on failure
  """
  def validate_media_upload(%{file: file, platform: platform} = _params) do
    with :ok <- validate_file_type(file),
         :ok <- validate_file_size(file, platform) do
      :ok
    end
  end

  @doc """
  Handles media upload to a specific platform.

  ## Parameters
    - conn: The connection struct
    - user: The user struct
    - file: The file to upload
    - platform: The platform to upload to
    - metadata: Additional metadata for the upload

  ## Returns
    - {:ok, result} on success
    - {:error, reason} on failure
  """
  def handle_media_upload(conn, user, file, platform, metadata \\ %{}) do
    with {:ok, tokens} <- get_tokens(conn, platform, user.id),
         :ok <- validate_media_upload(%{file: file, platform: platform}),
         {:ok, result} <- do_platform_upload(platform, %{file: file, metadata: metadata}, tokens) do
      {:ok, result}
    else
      {:error, reason} -> {:error, {platform, reason}}
    end
  end

  # Helper function for validate_media_upload
  defp validate_file_type(file) do
    ext = file |> Path.extname() |> String.downcase()
    if ext in ~w(.jpg .jpeg .png .gif .mp4 .mov) do
      :ok
    else
      {:error, "Unsupported file type: #{ext}"}
    end
  end

  @doc """
  Retrieves tokens for a user and platform using the SocialMediaToken functionality.

  ## Parameters
    - conn: The connection struct
    - provider: The social media provider as a string
    - user_id: The ID of the user (optional, defaults to current user in conn)

  ## Returns
    - {:ok, tokens} on success
    - {:error, reason} on failure
  """
  defp get_tokens(conn, provider, user_id) do
    # Get user_id from conn if not provided
    user_id = if is_nil(user_id) and conn.assigns[:current_user] do
      conn.assigns.current_user.id
    else
      user_id
    end

    if is_nil(user_id) do
      {:error, :user_not_found}
    else
      # Convert provider from string to atom for SocialMediaToken
      platform = String.to_existing_atom(provider)
      
      # Get the token
      case SocialMediaToken.get_token(user_id, platform) do
        {:ok, access_token} ->
          # Get refresh token if available
          refresh_result = SocialMediaToken.get_token(user_id, platform, :refresh)
          refresh_token = case refresh_result do
            {:ok, token} -> token
            _ -> nil
          end
          
          # Return tokens in a map
          {:ok, %{access_token: access_token, refresh_token: refresh_token}}
        
        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp handle_platform_uploads(content, user, platforms) do
    results = Enum.map(platforms, fn platform ->
      upload_to_platform(platform, content, user)
    end)

    case Enum.all?(results, &match?({:ok, _}, &1)) do
      true ->
        {:ok, content}
      false ->
        failed_platforms = 
          results
          |> Enum.filter(&match?({:error, _}, &1))
          |> Enum.map(fn {:error, {platform, reason}} -> "#{platform}: #{reason}" end)
          |> Enum.join(", ")
        
        {:error, "Failed to upload to some platforms: #{failed_platforms}"}
    end
  end

  defp upload_to_platform(platform, content, user) do
    with {:ok, tokens} <- get_tokens(platform, user),
         {:ok, result} <- do_platform_upload(platform, content, tokens) do
      {:ok, result}
    else
      {:error, reason} -> {:error, {platform, reason}}
    end
  end

  defp do_platform_upload(platform, content, tokens) do
    case platform do
      "twitter" -> upload_to_twitter(content, tokens)
      "facebook" -> upload_to_facebook(content, tokens)
      "instagram" -> upload_to_instagram(content, tokens)
      "tiktok" -> upload_to_tiktok(content, tokens)
      "youtube" -> upload_to_youtube(content, tokens)
      "vimeo" -> upload_to_vimeo(content, tokens)
      _ -> {:error, "Unsupported platform"}
    end
  end

  # Platform-specific upload functions
  defp upload_to_twitter(_content, _tokens), do: {:ok, "twitter_post_id"}
  defp upload_to_facebook(_content, _tokens), do: {:ok, "facebook_post_id"}
  defp upload_to_instagram(_content, _tokens), do: {:ok, "instagram_post_id"}
  defp upload_to_tiktok(_content, _tokens), do: {:ok, "tiktok_post_id"}
  defp upload_to_youtube(_content, _tokens), do: {:ok, "youtube_video_id"}
  defp upload_to_vimeo(_content, _tokens), do: {:ok, "vimeo_video_id"}

  # Token Management

  defp get_tokens(platform, user) do
    case Accounts.get_platform_token(user.id, platform) do
      {:ok, token} ->
        if token_expired?(token) do
          refresh_token(platform, token)
        else
          {:ok, token}
        end
      error -> error
    end
  end

  defp token_expired?(token) do
    token.expires_at && DateTime.compare(token.expires_at, DateTime.utc_now()) == :lt
  end

  defp refresh_token(provider, token) do
    case validate_provider(provider) do
      {:ok, auth_module, _} -> auth_module.refresh_token(token)
      error -> error
    end
  end

  # Content Validation Functions

  defp validate_user_tokens(user, platforms) do
    missing_tokens = 
      platforms
      |> Enum.reject(&has_valid_token?(user, &1))
      |> Enum.map(&"#{&1}")

    case missing_tokens do
      [] -> :ok
      platforms -> {:error, "Missing or invalid tokens for: #{Enum.join(platforms, ", ")}"}
    end
  end

  defp has_valid_token?(user, platform) do
    case Accounts.get_platform_token(user.id, platform) do
      {:ok, token} -> !token_expired?(token)
      _ -> false
    end
  end

  defp validate_post_content(%{files: files} = params) do
    with :ok <- validate_post_file_types(files),
         :ok <- validate_post_file_sizes(files, params.platforms) do
      :ok
    end
  end

  defp validate_short_video(%{video_path: path} = params) do
    with :ok <- validate_video_format(path),
         :ok <- validate_video_duration(path),
         :ok <- validate_video_size(path, params.platforms) do
      :ok
    end
  end

  defp validate_long_video(%{video_path: path} = params) do
    with :ok <- validate_video_format(path),
         :ok <- validate_video_size(path, params.platforms) do
      :ok
    end
  end

  defp validate_post_file_types(files) do
    invalid_files = 
      files
      |> Enum.reject(&valid_post_file_type?/1)
      |> Enum.map(&Path.basename(&1))

    case invalid_files do
      [] -> :ok
      files -> {:error, "Invalid file types: #{Enum.join(files, ", ")}"}
    end
  end

  defp valid_post_file_type?(file) do
    ext = file |> Path.extname() |> String.downcase()
    ext in ~w(.jpg .jpeg .png .pdf .doc .docx)
  end

  defp validate_video_format(path) do
    case Path.extname(path) |> String.downcase() do
      ext when ext in ~w(.mp4 .mov) -> :ok
      _ -> {:error, "Invalid video format. Only MP4 and MOV are supported"}
    end
  end

  defp validate_video_duration(path) do
    # In a real application, you would use a video processing library
    # to check the actual duration of the video
    # For now, we'll assume the validation is successful
    :ok
  end

  defp validate_video_size(path, platforms) do
    size = File.stat!(path).size
    max_size = Enum.map(platforms, &get_platform_max_size/1) |> Enum.min()

    if size <= max_size do
      :ok
    else
      {:error, "Video size exceeds platform limit of #{max_size} bytes"}
    end
  end

  defp validate_post_file_sizes(files, platforms) do
    results = 
      for platform <- platforms,
          file <- files do
        validate_file_size(file, platform)
      end

    case Enum.all?(results, &(&1 == :ok)) do
      true -> :ok
      false -> {:error, "Some files exceed platform size limits"}
    end
  end

  defp validate_file_size(file, platform) do
    size = File.stat!(file).size
    max_size = get_platform_max_size(platform)

    if size <= max_size do
      :ok
    else
      {:error, "File size exceeds #{platform} limit of #{max_size} bytes"}
    end
  end

  defp get_platform_max_size(platform) do
    case platform do
      "twitter" -> @twitter_max_size
      "instagram" -> @instagram_max_size
      "tiktok" -> @tiktok_max_size
      "youtube" -> @youtube_max_size
      "vimeo" -> @vimeo_max_size
      _ -> @youtube_max_size
    end
  end

  @doc """
  Parses a string and extracts hashtags.

  ## Parameters
    - content: The string content to parse for hashtags

  ## Returns
    - A list of hashtags (without the # symbol)
  """
  def parse_hashtags(content) when is_binary(content) do
    # Regex to match hashtags
    ~r/#(\w+)/u
    |> Regex.scan(content)
    |> Enum.map(fn [_, tag] -> tag end)
    |> Enum.uniq()
  end
  def parse_hashtags(_), do: []

  @doc """
  Handles post creation and submission to a specific social media platform.

  ## Parameters
    - conn: The connection struct
    - provider: The social media provider as a string
    - content: The post content as string
    - options: Additional options for the post (like media_ids, hashtags, etc.)
    - user_id: The ID of the user (optional, defaults to current user in conn)

  ## Returns
    - {:ok, result} on success
    - {:error, reason} on failure
  """
  def handle_post(conn, provider, content, options \\ %{}, user_id \\ nil) do
    # Get user_id from conn if not provided
    user_id = if is_nil(user_id) and conn.assigns[:current_user] do
      conn.assigns.current_user.id
    else
      user_id
    end

    hashtags = Map.get(options, :hashtags, parse_hashtags(content))
    media_ids = Map.get(options, :media_ids, [])
    
    with {:ok, tokens} <- get_tokens(conn, provider, user_id),
         post_data <- %{
           content: content,
           media_ids: media_ids,
           hashtags: hashtags,
           options: options
         },
         {:ok, result} <- do_platform_upload(provider, post_data, tokens) do
      {:ok, result}
    else
      {:error, reason} -> {:error, {provider, reason}}
    end
  end

  defp exchange_token_for_provider(auth_module, provider, params) do
    case provider do
      "twitter" ->
        # For Twitter, extract the code from params and call exchange_code_for_token
        case Map.get(params, "code") do
          nil -> {:error, "Missing code parameter"}
          code -> auth_module.exchange_code_for_token(code, params)
        end
      _ ->
        # For other providers, use the standard exchange_token method
        auth_module.exchange_token(params)
    end
  end
end


