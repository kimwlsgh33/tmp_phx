defmodule Myapp.SocialMedia.Tiktok do
  @moduledoc """
  TikTok implementation of the Myapp.SocialMedia behavior.
  
  This module serves as a bridge between the TikTok controller and
  the actual TikTok API integration in Myapp.Tiktok.
  """
  
  @behaviour Myapp.SocialMedia
  
  alias Myapp.Tiktok
  alias Myapp.Accounts.SocialMediaToken
  alias Myapp.SocialAuth.TikTok, as: TiktokOauth
  alias HTTPoison
  
  @doc """
  Checks if the user is authenticated with TikTok.
  
  Verifies if valid OAuth tokens exist for the specified user.
  
  ## Parameters
  
    * user_id - The ID of the user to check.
    
  ## Returns
  
    * {:ok, %{authenticated: true, details: details}} - If authenticated.
    * {:ok, %{authenticated: false}} - If not authenticated.
    * {:error, reason} - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def authenticated?(user_id) do
    with {:ok, parsed_user_id} <- parse_user_id(user_id),
         {:ok, _token} <- get_token(parsed_user_id) do
      {:ok, %{authenticated: true, details: %{user_id: parsed_user_id}}}
    else
      {:error, :token_not_found} ->
        {:ok, %{authenticated: false}}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Uploads media to TikTok.
  
  ## Parameters
  
    * user_id - The ID of the user.
    * media_path - Path to the media file.
    * mime_type - MIME type of the media.
    * options - Additional options for the upload.
    
  ## Returns
  
    * {:ok, media_id} - If the video was uploaded successfully.
    * {:error, reason} - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def upload_media(user_id, media_path, mime_type, options \\ []) do
    with {:ok, access_token} <- get_conn_from_user_id(user_id),
         :ok <- validate_video_file(media_path, mime_type),
         {:ok, media_id} <- Myapp.Tiktok.upload_video(media_path, [access_token: access_token] ++ options) do
      {:ok, media_id}
    else
      {:error, :invalid_file} ->
        {:error, "Invalid media file or not a video"}
      {:error, :file_not_found} ->
        {:error, "Media file not found at specified path"}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Validates that the file exists and is a video
  defp validate_video_file(media_path, mime_type) do
    cond do
      not File.exists?(media_path) ->
        {:error, :file_not_found}
      not String.starts_with?(mime_type, "video/") ->
        {:error, :invalid_file}
      true ->
        :ok
    end
  end
  
  @doc """
  Creates a post on TikTok.
  
  Uses the provided media_id to publish a new video on TikTok with the given text.
  
  ## Parameters
  
    * user_id - The ID of the user publishing the post.
    * media_id - The ID of the previously uploaded media to post.
    * text - The caption or description for the TikTok post.
    * options - Additional options for creating the post:
        * `hashtags` - List of hashtags to include
        * `mention_ids` - List of user IDs to mention
        * `visibility` - Privacy setting ("public", "friends", "private")
    
  ## Returns
  
    * {:ok, post_id} - If the post was created successfully.
    * {:error, reason} - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def create_post(user_id, media_id, text, options \\ []) do
    with {:ok, access_token} <- get_conn_from_user_id(user_id) do
      privacy_level = options[:visibility] || "private"
      disable_comments = Keyword.get(options, :disable_comments, false)
      disable_duet = Keyword.get(options, :disable_duet, false)
      disable_stitch = Keyword.get(options, :disable_stitch, false)
      
      case Myapp.Tiktok.finalize_upload(
        media_id, 
        text, 
        privacy_level,
        disable_comments,
        disable_duet,
        disable_stitch,
        [access_token: access_token]
      ) do
        {:ok, response} ->
          case response do
            %{"data" => %{"video_id" => video_id}} -> {:ok, video_id}
            _ -> {:error, "Invalid response from TikTok API"}
          end
        {:error, :media_not_found} ->
          {:error, "Media ID not found or processing incomplete"}
        {:error, :invalid_parameters} ->
          {:error, "Invalid parameters for TikTok post creation"}
        {:error, reason} ->
          {:error, reason}
      end
    end
  end
  
  @doc """
  Lists videos from TikTok.

  Retrieves a paginated list of videos from the user's TikTok account.

  ## Parameters

    * user_id - The ID of the user whose videos should be retrieved.
    * options - Additional options for video listing (optional):
        * `page_size` - Number of videos to return per page (default: 20)
        * `page_token` - Token for retrieving the next page of results
        * `sort_by` - Sort order ('date_desc' or 'date_asc', default: 'date_desc')

  ## Returns

    * {:ok, %{videos: videos, next_page_token: token}} - If videos were retrieved successfully.
    * {:error, reason} - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def list_videos(user_id, options \\ []) do
    with {:ok, access_token} <- get_conn_from_user_id(user_id),
         {:ok, response} <- Myapp.Tiktok.list_videos([access_token: access_token] ++ options) do
      case response do
        %{"data" => %{"videos" => videos, "cursor" => cursor}} ->
          {:ok, %{
            videos: videos,
            next_page_token: cursor
          }}
        _ ->
          {:error, "Invalid response format from TikTok API"}
      end
    else
      {:error, :no_videos_found} ->
        {:ok, %{videos: [], next_page_token: nil}}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Deletes a post from TikTok.
  
  Removes a specific post from the user's TikTok account.
  
  ## Parameters
  
    * user_id - The ID of the user who owns the post.
    * post_id - The ID of the post to delete.
    
  ## Returns
  
    * {:ok, %{id: post_id}} - If the post was deleted successfully.
    * {:error, reason} - If an error occurs (post not found, permission issues, etc.).
  """
  @impl Myapp.SocialMedia
  def delete_post(user_id, post_id) do
    with {:ok, access_token} <- get_conn_from_user_id(user_id),
         {:ok, _result} <- Myapp.Tiktok.delete_video(post_id, [access_token: access_token]) do
      {:ok, %{id: post_id}}
    else
      {:error, :post_not_found} ->
        {:error, "The specified TikTok post could not be found"}
      {:error, :permission_denied} ->
        {:error, "You don't have permission to delete this TikTok post"}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Gets the user's TikTok profile.

  Retrieves profile information including username, bio, follower count, 
  and other public profile data from the user's TikTok account.

  ## Parameters

    * user_id - The ID of the user whose profile should be retrieved.

  ## Returns

    * {:ok, profile} - If the profile was retrieved successfully, with profile details:
        * `username` - The user's TikTok username
        * `display_name` - The user's display name
        * `bio` - User's bio or description
        * `follower_count` - Number of followers
        * `following_count` - Number of accounts the user follows
        * `video_count` - Number of videos published
        * `profile_image_url` - URL to the profile image
    * {:error, reason} - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def get_profile(user_id) do
    with {:ok, access_token} <- get_conn_from_user_id(user_id),
         {:ok, profile_data} <- Myapp.Tiktok.get_profile([access_token: access_token]) do
      # Map the response fields to our expected structure
      # TikTok API returns profile data as a map with string keys
      {:ok, %{
        username: profile_data["display_name"] || "",
        display_name: profile_data["display_name"] || "",
        bio: profile_data["bio_description"] || "",
        follower_count: profile_data["follower_count"] || 0,
        following_count: profile_data["following_count"] || 0,
        video_count: profile_data["video_count"] || 0,
        profile_image_url: profile_data["avatar_url"] || ""
      }}
    else
      {:error, :profile_not_found} ->
        {:error, "TikTok profile could not be found"}
      {:error, :rate_limited} ->
        {:error, "TikTok API rate limit exceeded"}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Gets the user's TikTok timeline.
  
  Retrieves a paginated timeline (feed) from the user's TikTok account, which can
  be configured to return either the "For You" feed or the "Following" feed.
  
  ## Parameters
  
    * user_id - The ID of the user whose timeline should be retrieved.
    * options - Additional options for timeline retrieval (optional):
        * `feed_type` - Type of feed to retrieve ('for_you' or 'following', default: 'for_you')
        * `page_size` - Number of posts to return per page (default: 15)
        * `page_token` - Token for retrieving the next page of results
        * `include_comments` - Whether to include comment previews (boolean, default: false)
        * `include_stats` - Whether to include engagement statistics (boolean, default: true)
  
  ## Returns
  
    * {:ok, %{posts: posts, next_page_token: token}} - If timeline was retrieved successfully.
    * {:error, reason} - If an error occurs.
  """
  @impl Myapp.SocialMedia
  def get_timeline(user_id, options \\ []) do
    with {:ok, access_token} <- get_conn_from_user_id(user_id),
         {:ok, result} <- Myapp.Tiktok.get_timeline([access_token: access_token] ++ options) do
      {:ok, result} # The result is already in the correct format: %{posts: posts, next_page_token: next_page_token}
    else
      {:error, :empty_timeline} ->
        {:ok, %{posts: [], next_page_token: nil}}
      {:error, :rate_limited} ->
        {:error, "TikTok API rate limit exceeded"}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Refreshes TikTok OAuth tokens.
  """
  @impl Myapp.SocialMedia
  def refresh_tokens(user_id) do
    with {:ok, parsed_user_id} <- parse_user_id(user_id),
         {:ok, token} <- get_token(parsed_user_id),
         {:ok, refreshed_token} <- do_refresh_token(token) do
      {:ok, refreshed_token}
    else
      {:error, :token_not_found} ->
        {:error, "No TikTok token found for user"}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Refreshes the TikTok OAuth token.
  """
  def do_refresh_token(token) do
    case TiktokOauth.refresh_access_token(token.refresh_token) do
      {:ok, %{access_token: access_token, refresh_token: refresh_token, expires_in: expires_in}} ->
        expires_at = DateTime.add(DateTime.utc_now(), expires_in, :second)
        
        token_params = %{
          access_token: access_token,
          refresh_token: refresh_token,
          expires_at: expires_at,
          last_used_at: DateTime.utc_now()
        }
        
        SocialMediaToken.update_token(token, token_params)
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Private helper functions
  defp parse_user_id(user_id) when is_binary(user_id) do
    case Integer.parse(user_id) do
      {id, ""} -> {:ok, id}
      _ -> {:error, "Invalid user ID format"}
    end
  end
  
  defp parse_user_id(user_id) when is_integer(user_id), do: {:ok, user_id}
  defp parse_user_id(_), do: {:error, "Invalid user ID format"}

  defp get_token(user_id) do
    case SocialMediaToken.get_active_tokens(user_id, :tiktok) do
      {:ok, token} -> {:ok, token}
      {:error, _} -> {:error, "No active TikTok token found"}
    end
  end

  defp get_conn_from_user_id(user_id) do
    with {:ok, parsed_user_id} <- parse_user_id(user_id),
         {:ok, token} <- get_token(parsed_user_id) do
      if SocialMediaToken.needs_refresh?(token) do
        case refresh_tokens(parsed_user_id) do
          {:ok, refreshed_token} ->
            {:ok, refreshed_token.access_token_text}
          {:error, reason} ->
            {:error, reason}
        end
      else
        # Mark token as used
        SocialMediaToken.update_token(token, %{last_used_at: DateTime.utc_now()})
        {:ok, token.access_token_text}
      end
    end
  end
end
