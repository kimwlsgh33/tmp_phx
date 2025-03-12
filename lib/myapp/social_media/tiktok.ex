defmodule Myapp.SocialMedia.Tiktok do
  @moduledoc """
  TikTok implementation of the Myapp.SocialMedia behavior.
  
  This module serves as a bridge between the TikTok controller and
  the actual TikTok API integration in Myapp.Tiktok.
  """
  
  @behaviour Myapp.SocialMedia
  
  alias Myapp.Tiktok
  alias Myapp.SocialMediaToken
  alias Myapp.TiktokOauth
  
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
         {:ok, token} <- get_token(parsed_user_id) do
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
  def upload_media(_user_id, _media_path, _mime_type, _options \\ []) do
    {:error, "TikTok upload not implemented in this version"}
  end
  
  @doc """
  Creates a post on TikTok.
  """
  @impl Myapp.SocialMedia
  def create_post(_user_id, _media_id, _text, _options \\ []) do
    {:error, "TikTok post creation not implemented in this version"}
  end
  
  @doc """
  Lists videos from TikTok.
  """
  def list_videos(_user_id) do
    {:error, "TikTok video listing not implemented in this version"}
  end
  
  @doc """
  Deletes a post from TikTok.
  """
  @impl Myapp.SocialMedia
  def delete_post(_user_id, _post_id) do
    {:error, "TikTok post deletion not implemented in this version"}
  end
  
  @doc """
  Gets the user's TikTok profile.
  """
  @impl Myapp.SocialMedia
  def get_profile(_user_id) do
    {:error, "TikTok profile retrieval not implemented in this version"}
  end
  
  @doc """
  Gets the user's TikTok timeline.
  """
  @impl Myapp.SocialMedia
  def get_timeline(_user_id, _options \\ []) do
    {:error, "TikTok timeline retrieval not implemented in this version"}
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

  @doc """
  Retrieves the TikTok token for a user from the database.
  """
  def get_token(user_id) do
    case SocialMediaToken.get_token_by_user_id_and_provider(user_id, "tiktok") do
      nil -> {:error, :token_not_found}
      token -> {:ok, token}
    end
  end

  @doc """
  Gets a TikTok API connection for a user.
  """
  def get_conn_from_user_id(user_id) do
    with {:ok, parsed_user_id} <- parse_user_id(user_id),
         {:ok, token} <- get_token(parsed_user_id) do
      # Check if token is expired or about to expire
      if SocialMediaToken.is_token_expired?(token) do
        case refresh_tokens(parsed_user_id) do
          {:ok, refreshed_token} ->
            {:ok, Tiktok.client(refreshed_token.access_token)}
          {:error, reason} ->
            {:error, reason}
        end
      else
        # Mark token as used
        SocialMediaToken.update_token(token, %{last_used_at: DateTime.utc_now()})
        {:ok, Tiktok.client(token.access_token)}
      end
    end
  end
end
