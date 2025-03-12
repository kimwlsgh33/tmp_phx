defmodule Myapp.SocialMedia.Youtube do
  @moduledoc """
  YouTube implementation of the Myapp.SocialMedia behavior.
  
  This module serves as a bridge between the YouTube controller and
  the actual YouTube API integration in Myapp.Youtube.
  """
  
  @behaviour Myapp.SocialMedia
  
  alias Myapp.SocialMediaToken
  alias Myapp.YoutubeOauth
  require Logger
  
  @doc """
  Checks if the user is authenticated with YouTube.
  
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
    case SocialMediaToken.valid_token?(user_id, :youtube) do
      {:ok, true} -> 
        # Get profile info to return in details
        case get_profile(user_id) do
          {:ok, profile} ->
            {:ok, %{authenticated: true, details: profile}}
          _error ->
            {:ok, %{authenticated: true}}
        end
      {:ok, false} ->
        {:ok, %{authenticated: false}}
      {:error, reason} ->
        Logger.error("Error checking YouTube authentication: #{inspect(reason)}")
        {:ok, %{authenticated: false}}
    end
  end
  
  @doc """
  Uploads media to YouTube.
  
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
  def upload_media(_user_id, _media_path, _mime_type, _options \\ []) do
    {:error, "YouTube video upload not implemented in this version"}
  end
  
  @doc """
  Creates a post on YouTube.
  """
  @impl Myapp.SocialMedia
  def create_post(_user_id, _media_id, _text, _options \\ []) do
    {:error, "YouTube post creation not implemented in this version"}
  end
  
  @doc """
  Deletes a post from YouTube.
  """
  @impl Myapp.SocialMedia
  def delete_post(_user_id, _post_id) do
    {:error, "YouTube post deletion not implemented in this version"}
  end
  
  @doc """
  Gets the user's YouTube profile.
  """
  @impl Myapp.SocialMedia
  def get_profile(user_id) do
    with {:ok, conn} <- get_conn_from_user_id(user_id),
         {:ok, profile} <- YoutubeOauth.get_profile(conn) do
      {:ok, profile}
    else
      {:error, :token_not_found} ->
        {:error, "No YouTube authorization found"}
      {:error, reason} ->
        Logger.error("Failed to get YouTube profile: #{inspect(reason)}")
        {:error, "Failed to retrieve YouTube profile: #{inspect(reason)}"}
    end
  end
  
  @doc """
  Gets the user's YouTube timeline.
  """
  @impl Myapp.SocialMedia
  def get_timeline(_user_id, _options \\ []) do
    {:error, "YouTube timeline retrieval not implemented in this version"}
  end
  
  @doc """
  Refreshes YouTube OAuth tokens.
  """
  @impl Myapp.SocialMedia
  def refresh_tokens(user_id) do
    case SocialMediaToken.refresh_token(user_id, :youtube) do
      {:ok, _token_info} -> 
        {:ok, "YouTube tokens refreshed successfully"}
      {:error, reason} ->
        Logger.error("Failed to refresh YouTube tokens: #{inspect(reason)}")
        {:error, "Failed to refresh YouTube tokens: #{inspect(reason)}"}
    end
  end

  @doc """
  Gets an authenticated YouTube connection for a user.

  ## Parameters
    * user_id - The ID of the user.

  ## Returns
    * {:ok, conn} - If successful.
    * {:error, reason} - If an error occurs.
  """
  def get_conn_from_user_id(user_id) do
    case SocialMediaToken.get_token(user_id, :youtube, :access) do
      {:ok, access_token} ->
        # Create a connection with the access token
        {:ok, YoutubeOauth.client_with_token(access_token)}

      {:error, :token_not_found} = error ->
        error

      {:error, reason} ->
        Logger.error("Error getting YouTube token: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
