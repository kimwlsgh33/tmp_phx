defmodule Myapp.SocialMedia.Instagram do
  @moduledoc """
  Instagram implementation of the Myapp.SocialMedia behavior.
  
  This module provides standardized functions for Instagram integration
  following the SocialMedia behaviour interface.
  """
  
  @behaviour Myapp.SocialMedia
  
  require Logger
  alias Myapp.InstagramOauth
  alias Myapp.SocialMediaToken
  
  @doc """
  Checks if the user is authenticated with Instagram.
  
  ## Parameters
  
    * `user_id` - The ID of the user to check authentication for.
    
  ## Returns
  
    * `{:ok, %{authenticated: true, details: details}}` - If the user is authenticated.
    * `{:ok, %{authenticated: false}}` - If the user is not authenticated.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def authenticated?(user_id) do
    case get_conn_from_user_id(user_id) do
      {:ok, conn} ->
        case InstagramOauth.validate_token(conn) do
          {:ok, true} ->
            # Get additional profile details if needed
            case get_profile(user_id) do
              {:ok, profile} ->
                {:ok, %{authenticated: true, details: profile}}
              {:error, _} ->
                # Token validated but couldn't get profile, still consider authenticated
                {:ok, %{authenticated: true, details: %{}}}
            end
          {:ok, false} ->
            {:ok, %{authenticated: false}}
          {:error, reason} ->
            {:error, reason}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Creates a post on Instagram.
  
  ## Parameters
  
    * `user_id` - The ID of the user creating the post.
    * `content` - The content of the post (caption).
    * `media_ids` - List of media IDs to attach to the post (required for Instagram).
    * `options` - Additional Instagram-specific options.
    
  ## Returns
  
    * `{:ok, post}` - If the post was created successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def create_post(user_id, content, media_ids, options \\ []) do
    with {:ok, conn} <- get_conn_from_user_id(user_id) do
      if media_ids && length(media_ids) > 0 do
        InstagramOauth.create_media_post(conn, content, media_ids, options)
      else
        {:error, "Instagram requires media to create a post"}
      end
    end
  end
  
  @doc """
  Uploads media to Instagram.
  
  ## Parameters
  
    * `user_id` - The ID of the user uploading the media.
    * `media_path` - The path to the media file.
    * `mime_type` - The MIME type of the media file.
    * `options` - Additional Instagram-specific options.
    
  ## Returns
  
    * `{:ok, media_id}` - If the media was uploaded successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def upload_media(user_id, media_path, mime_type, options \\ []) do
    with {:ok, conn} <- get_conn_from_user_id(user_id),
         {:ok, media_binary} <- File.read(media_path) do
      InstagramOauth.upload_media(conn, media_binary, mime_type, options)
    else
      {:error, :enoent} -> {:error, "File not found: #{media_path}"}
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Deletes a post from Instagram.
  
  ## Parameters
  
    * `user_id` - The ID of the user who owns the post.
    * `post_id` - The ID of the post to delete.
    
  ## Returns
  
    * `{:ok, result}` - If the post was deleted successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def delete_post(user_id, post_id) do
    with {:ok, conn} <- get_conn_from_user_id(user_id) do
      InstagramOauth.delete_media(conn, post_id)
    end
  end
  
  @doc """
  Retrieves the user's timeline (media feed) from Instagram.
  
  ## Parameters
  
    * `user_id` - The ID of the user whose timeline to retrieve.
    * `options` - Additional options such as limit, pagination token, etc.
    
  ## Returns
  
    * `{:ok, posts}` - If the timeline was retrieved successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def get_timeline(user_id, options \\ []) do
    # Convert keyword list to map for Instagram API
    opts = Enum.into(options, %{})
    
    with {:ok, conn} <- get_conn_from_user_id(user_id) do
      InstagramOauth.get_user_media(conn, opts)
    end
  end
  
  @doc """
  Retrieves the user's profile from Instagram.
  
  ## Parameters
  
    * `user_id` - The ID of the user whose profile to retrieve.
    
  ## Returns
  
    * `{:ok, profile}` - If the profile was retrieved successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def get_profile(user_id) do
    with {:ok, conn} <- get_conn_from_user_id(user_id),
         {:ok, profile} <- InstagramOauth.get_user_profile(conn) do
      
      if profile do
        {:ok, %{
          id: profile["id"],
          username: profile["username"],
          name: profile["name"] || profile["username"],
          biography: profile["biography"],
          profile_picture_url: profile["profile_picture_url"],
          followers_count: get_in(profile, ["followers_count"]),
          follows_count: get_in(profile, ["follows_count"]),
          media_count: get_in(profile, ["media_count"])
        }}
      else
        {:error, "Could not retrieve profile data"}
      end
    end
  end
  
  @doc """
  Refreshes the user's authentication tokens if needed.
  
  ## Parameters
  
    * `user_id` - The ID of the user whose tokens to refresh.
    
  ## Returns
  
    * `{:ok, tokens}` - If the tokens were refreshed successfully.
    * `{:ok, :not_needed}` - If token refresh was not needed.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def refresh_tokens(user_id) do
    with {:ok, token} <- SocialMediaToken.get_token_by_user_id_and_provider(user_id, "instagram") do
      # Check if token is expired or about to expire
      if SocialMediaToken.is_token_expired?(token) do
        case do_refresh_token(token) do
          {:ok, refreshed_token} -> {:ok, refreshed_token}
          {:error, reason} -> {:error, reason}
        end
      else
        # Token is still valid, no refresh needed
        SocialMediaToken.update_token(token, %{last_used_at: DateTime.utc_now()})
        {:ok, :not_needed}
      end
    else
      nil -> {:error, :token_not_found}
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Refreshes the Instagram OAuth token.
  
  Instagram typically uses long-lived tokens that need to be refreshed
  before they expire (typically 60 days).
  """
  def do_refresh_token(token) do
    case InstagramOauth.refresh_long_lived_token(token.refresh_token || token.access_token) do
      {:ok, %{access_token: access_token, expires_in: expires_in}} ->
        expires_at = DateTime.add(DateTime.utc_now(), expires_in, :second)
        
        token_params = %{
          access_token: access_token,
          expires_at: expires_at,
          last_used_at: DateTime.utc_now()
        }
        
        SocialMediaToken.update_token(token, token_params)
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Helper function to get conn from user_id
  defp get_conn_from_user_id(user_id) do
    # Get the access token from the database
    case SocialMediaToken.get_token(user_id, :instagram, :access) do
      {:ok, access_token} ->
        # Create a connection object that InstagramOauth can use
        {:ok, InstagramOauth.client_with_token(access_token)}
        
      {:error, :token_not_found} ->
        {:error, :authentication_required}
        
      {:error, reason} ->
        {:error, reason}
    end
  end
end

