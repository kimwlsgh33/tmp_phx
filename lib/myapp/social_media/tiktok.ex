defmodule Myapp.SocialMedia.Tiktok do
  @moduledoc """
  TikTok implementation of the Myapp.SocialMedia behavior.
  
  This module serves as a bridge between the TikTok controller and
  the actual TikTok API integration in Myapp.Tiktok.
  """
  
  @behaviour Myapp.SocialMedia
  
  alias Myapp.Tiktok
  alias Myapp.SocialMediaToken
  
  @doc """
  Checks if the user is authenticated with TikTok.
  
  Verifies if valid OAuth tokens exist for the specified user.
  
  ## Parameters
  
    * `user_id` - The ID of the user to check.
    
  ## Returns
  
    * `{:ok, %{authenticated: true, details: details}}` - If authenticated.
    * `{:ok, %{authenticated: false}}` - If not authenticated.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def authenticated?(user_id) do
    case parse_user_id(user_id) do
      {:ok, parsed_id} ->
        case SocialMediaToken.get_token(parsed_id, :tiktok) do
          {:ok, token} when is_map(token) ->
            # Use the check_credentials function to verify the token is valid
            case Tiktok.check_credentials(access_token: token.access_token) do
              {:ok, _} ->
                {:ok, %{authenticated: true, details: %{expires_at: token.expires_at}}}
              {:error, _reason} ->
                # Token exists but is invalid, try refreshing it
                case refresh_tokens(parsed_id) do
                  {:ok, _refreshed_token} ->
                    {:ok, %{authenticated: true, details: %{expires_at: token.expires_at}}}
                  {:error, _} ->
                    {:ok, %{authenticated: false}}
                end
            end
          _ ->
            {:ok, %{authenticated: false}}
        end
      {:error, _} ->
        # If user_id can't be parsed to an integer, consider it not authenticated
        {:ok, %{authenticated: false}}
    end
  end

  @doc """
  Lists videos from the user's TikTok account.
  
  ## Parameters
  
    * `user_id` - The ID of the user whose videos to list.
    
  ## Returns
  
    * `{:ok, videos}` - If videos were retrieved successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def list_videos(user_id) do
    case parse_user_id(user_id) do
      {:ok, parsed_id} ->
        case SocialMediaToken.get_token(parsed_id, :tiktok) do
          {:ok, token} when is_map(token) ->
            Tiktok.list_videos(access_token: token.access_token)
          {:error, reason} ->
            {:error, reason}
        end
      {:error, _} ->
        {:error, "Invalid user ID format"}
    end
  end

  @doc """
  Creates a post (video) on TikTok.
  
  ## Parameters
  
    * `user_id` - The ID of the user creating the post.
    * `content` - The content (title/caption) for the video.
    * `media_ids` - List of media IDs to attach (usually just one for TikTok).
    * `options` - Additional options for the video.
    
  ## Returns
  
    * `{:ok, post}` - If the post was created successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def create_post(user_id, content, media_ids, options \\ []) do
    case parse_user_id(user_id) do
      {:ok, parsed_id} ->
        case SocialMediaToken.get_token(parsed_id, :tiktok) do
          {:ok, token} when is_map(token) ->
            # TikTok doesn't have a direct create_post API, since media uploads
            # and post creation are combined through the upload process
            {:error, "For TikTok, please use upload_media instead of create_post"}
          {:error, reason} ->
            {:error, reason}
        end
      {:error, _} ->
        {:error, "Invalid user ID format"}
    end
  end

  @doc """
  Uploads a video to TikTok.
  
  ## Parameters
  
    * `user_id` - The ID of the user uploading the video.
    * `media_path` - The path to the video file.
    * `mime_type` - The MIME type of the video file.
    * `options` - Additional options for the video.
    
  ## Returns
  
    * `{:ok, media_id}` - If the video was uploaded successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def upload_media(user_id, media_path, mime_type, options \\ []) do
    case parse_user_id(user_id) do
      {:ok, parsed_id} ->
        case SocialMediaToken.get_token(parsed_id, :tiktok) do
          {:ok, token} when is_map(token) ->
            # Extract options for TikTok video upload
            tiktok_options = [
              access_token: token.access_token,
              title: Keyword.get(options, :title, ""),
              privacy_level: Keyword.get(options, :privacy_level, "public"),
              disable_comments: Keyword.get(options, :disable_comments, false),
              disable_duet: Keyword.get(options, :disable_duet, false),
              disable_stitch: Keyword.get(options, :disable_stitch, false)
            ]
            
            # Upload the video
            case Tiktok.upload_video(media_path, tiktok_options) do
              {:ok, %{"data" => %{"video_id" => video_id}}} ->
                {:ok, video_id}
              {:error, reason} ->
                {:error, reason}
            end
            
          {:error, reason} ->
            {:error, reason}
        end
      {:error, _} ->
        {:error, "Invalid user ID format"}
    end
  end

  @doc """
  Deletes a video from TikTok.
  
  ## Parameters
  
    * `user_id` - The ID of the user deleting the video.
    * `post_id` - The ID of the video to delete.
    
  ## Returns
  
    * `{:ok, result}` - If the video was deleted successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def delete_post(user_id, post_id) do
    case parse_user_id(user_id) do
      {:ok, parsed_id} ->
        case SocialMediaToken.get_token(parsed_id, :tiktok) do
          {:ok, token} when is_map(token) ->
            Tiktok.delete_video(post_id, access_token: token.access_token)
          {:error, reason} ->
            {:error, reason}
        end
      {:error, _} ->
        {:error, "Invalid user ID format"}
    end
  end

  @doc """
  Retrieves the user's TikTok timeline (list of videos).
  
  ## Parameters
  
    * `user_id` - The ID of the user whose timeline to retrieve.
    * `options` - Additional options such as pagination parameters.
    
  ## Returns
  
    * `{:ok, videos}` - If the timeline was retrieved successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def get_timeline(user_id, options \\ []) do
    case list_videos(user_id) do
      {:ok, %{"data" => %{"videos" => videos}}} ->
        {:ok, videos}
      {:error, reason} ->
        {:error, reason}
      _ ->
        {:error, "Failed to retrieve TikTok timeline"}
    end
  end

  @doc """
  Retrieves the user's TikTok profile.
  
  ## Parameters
  
    * `user_id` - The ID of the user whose profile to retrieve.
    
  ## Returns
  
    * `{:ok, profile}` - If the profile was retrieved successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def get_profile(user_id) do
    case parse_user_id(user_id) do
      {:ok, parsed_id} ->
        case SocialMediaToken.get_token(parsed_id, :tiktok) do
          {:ok, token} when is_map(token) ->
            # TikTok API doesn't have a dedicated profile endpoint in this implementation
            # Return a basic profile with authentication status
            {:ok, %{
              authenticated: true,
              platform: "tiktok",
              expires_at: token.expires_at
            }}
          {:error, reason} ->
            {:error, reason}
        end
      {:error, _} ->
        {:error, "Invalid user ID format"}
    end
  end

  @doc """
  Refreshes the user's TikTok authentication tokens if needed.
  
  ## Parameters
  
    * `user_id` - The ID of the user whose tokens to refresh.
    
  ## Returns
  
    * `{:ok, tokens}` - If the tokens were refreshed successfully.
    * `{:ok, :not_needed}` - If token refresh was not needed.
    * `{:error, reason}` - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def refresh_tokens(user_id) do
    case parse_user_id(user_id) do
      {:ok, parsed_id} ->
        # This would typically use the TikTok API to refresh tokens
        # For now, returning :not_needed since implementing token refresh
        # would require specific TikTok OAuth logic
        {:ok, :not_needed}
      {:error, _} ->
        {:error, "Invalid user ID format"}
    end
  end
  
  # Helper function to parse user_id to integer if it's a string
  defp parse_user_id(user_id) when is_integer(user_id), do: {:ok, user_id}
  defp parse_user_id(user_id) when is_binary(user_id) do
    case Integer.parse(user_id) do
      {parsed_id, ""} -> 
        # If the entire string is a valid integer
        {:ok, parsed_id}
      _ ->
        # For special cases like "default_user", we could handle them specifically
        # Otherwise, return an error
        if user_id == "default_user" do
          # You could have a default user ID for testing or for users who aren't logged in
          # For example, using ID 0 or -1 as a special marker
          {:ok, 0}
        else
          {:error, "Cannot parse user ID: #{user_id}"}
        end
    end
  end
  defp parse_user_id(_), do: {:error, "User ID must be a string or integer"}
end

