defmodule Myapp.SocialMedia.Twitter do
  @moduledoc """
  Twitter implementation of the SocialMedia behaviour.
  
  This module provides standardized functions for Twitter integration
  following the SocialMedia behaviour interface.
  """
  
  @behaviour Myapp.SocialMedia
  
  require Logger
  alias Myapp.Twitter
  alias Myapp.TwitterOauth
  alias Myapp.SocialMediaToken
  
  @doc """
  Checks if the user is authenticated with Twitter.
  
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
        case Twitter.validate_token(conn) do
          {:ok, true} ->
            # Get additional profile details if needed
            case Twitter.get_authenticated_user_id(conn) do
              {:ok, twitter_user_id} ->
                {:ok, %{authenticated: true, details: %{twitter_user_id: twitter_user_id}}}
              {:error, _} ->
                # Token validated but couldn't get user ID, still consider authenticated
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
  Creates a post (tweet) on Twitter.
  
  ## Parameters
  
    * `user_id` - The ID of the user creating the post.
    * `content` - The content of the post (tweet text).
    * `media_ids` - Optional list of media IDs to attach to the post.
    * `options` - Additional Twitter-specific options.
    
  ## Returns
  
    * `{:ok, post}` - If the post was created successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def create_post(user_id, content, media_ids, _options \\ []) do
    with {:ok, conn} <- get_conn_from_user_id(user_id) do
      if media_ids && length(media_ids) > 0 do
        Twitter.post_tweet_with_media(conn, content, media_ids)
      else
        Twitter.post_tweet(conn, content)
      end
    end
  end
  
  @doc """
  Uploads media to Twitter.
  
  ## Parameters
  
    * `user_id` - The ID of the user uploading the media.
    * `media_path` - The path to the media file.
    * `mime_type` - The MIME type of the media file.
    * `options` - Additional Twitter-specific options.
    
  ## Returns
  
    * `{:ok, media_id}` - If the media was uploaded successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def upload_media(user_id, media_path, mime_type, _options \\ []) do
    with {:ok, conn} <- get_conn_from_user_id(user_id),
         {:ok, media_binary} <- File.read(media_path) do
      Twitter.upload_media(conn, media_binary, mime_type)
    else
      {:error, :enoent} -> {:error, "File not found: #{media_path}"}
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Deletes a post (tweet) from Twitter.
  
  ## Parameters
  
    * `user_id` - The ID of the user who owns the post.
    * `post_id` - The ID of the post (tweet) to delete.
    
  ## Returns
  
    * `{:ok, result}` - If the post was deleted successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def delete_post(user_id, post_id) do
    with {:ok, conn} <- get_conn_from_user_id(user_id) do
      Twitter.delete_tweet(conn, post_id)
    end
  end
  
  @doc """
  Retrieves the user's timeline from Twitter.
  
  ## Parameters
  
    * `user_id` - The ID of the user whose timeline to retrieve.
    * `options` - Additional options such as limit, max_id, etc.
    
  ## Returns
  
    * `{:ok, posts}` - If the timeline was retrieved successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def get_timeline(user_id, options \\ []) do
    # Convert keyword list to map for Twitter API
    opts = Enum.into(options, %{})
    
    with {:ok, conn} <- get_conn_from_user_id(user_id) do
      Twitter.get_user_timeline(conn, opts)
    end
  end
  
  @doc """
  Retrieves the user's profile from Twitter.
  
  ## Parameters
  
    * `user_id` - The ID of the user whose profile to retrieve.
    
  ## Returns
  
    * `{:ok, profile}` - If the profile was retrieved successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def get_profile(user_id) do
    with {:ok, conn} <- get_conn_from_user_id(user_id),
         {:ok, token} <- TwitterOauth.get_access_token(conn),
         {:ok, twitter_user_id} <- Twitter.get_authenticated_user_id(token),
         {:ok, response} <- Twitter.make_api_call(:get, "/users/#{twitter_user_id}", token, %{
           "user.fields" => "name,username,profile_image_url,description,created_at,public_metrics"
         }) do
      
      profile_data = response["data"]
      
      if profile_data do
        {:ok, %{
          id: profile_data["id"],
          username: profile_data["username"],
          name: profile_data["name"],
          description: profile_data["description"],
          profile_image_url: profile_data["profile_image_url"],
          created_at: profile_data["created_at"],
          metrics: profile_data["public_metrics"]
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
    # Twitter OAuth 2.0 implementation may not support token refresh
    # without involving the user. This is a placeholder implementation.
    with {:ok, conn} <- get_conn_from_user_id(user_id),
         {:ok, true} <- Twitter.validate_token(conn) do
      # Token is still valid, no refresh needed
      {:ok, :not_needed}
    else
      {:ok, false} ->
        # Token is invalid, but we can't refresh it automatically in most OAuth 2.0 flows
        # without redirect. The application may need to initiate a new OAuth flow.
        {:error, :token_expired_needs_reauthorization}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Helper function to get conn from user_id
  # In a real application, this would likely retrieve tokens from a database
  # and construct a conn-like structure for the Twitter module to use
  defp get_conn_from_user_id(user_id) do
    # Get the access token from the database
    with {:ok, access_token} <- SocialMediaToken.get_token(user_id, :twitter, :access),
         {:ok, refresh_token} <- get_refresh_token(user_id) do
      # Create a mock conn with session data that TwitterOauth can use
      {:ok, %{
        private: %{
          plug_session: %{
            "twitter_access_token" => access_token,
            "twitter_refresh_token" => refresh_token
          }
        }
      }}
    else
      {:error, :token_not_found} ->
        {:error, :authentication_required}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Helper function to safely get refresh token (might not exist)
  defp get_refresh_token(user_id) do
    case SocialMediaToken.get_token(user_id, :twitter, :refresh) do
      {:ok, refresh_token} -> {:ok, refresh_token}
      {:error, :refresh_token_not_available} -> {:ok, nil} # Make it non-fatal if refresh token is missing
      {:error, reason} -> {:error, reason}
    end
    
    # For testing during implementation, you might return a mock:
    # {:ok, %{private: %{plug_session: %{"twitter_access_token" => "test_token"}}}}
  end
end

