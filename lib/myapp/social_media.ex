defmodule Myapp.SocialMedia do
  @moduledoc """
  Defines a behavior for common social media operations across different platforms.
  
  This behavior defines a standard interface for interacting with various social media
  platforms, ensuring consistency in operations such as authentication status checks,
  media uploads, post creation, and profile retrieval.
  
  Provider-specific modules (e.g., Myapp.SocialMedia.Twitter, Myapp.SocialMedia.TikTok) 
  should implement this behavior.
  """

  @doc """
  Verifies if the user is authenticated with the social media platform.
  
  ## Parameters
  
    * `user_id` - The ID of the user to check authentication for.
    
  ## Returns
  
    * `{:ok, %{authenticated: true, details: details}}` - If the user is authenticated.
    * `{:ok, %{authenticated: false}}` - If the user is not authenticated.
    * `{:error, reason}` - If an error occurs.
  """
  @callback authenticated?(user_id :: String.t()) ::
              {:ok, %{authenticated: boolean(), details: map() | nil}} | {:error, any()}

  @doc """
  Creates a post on the social media platform.
  
  ## Parameters
  
    * `user_id` - The ID of the user creating the post.
    * `content` - The content of the post.
    * `media_ids` - Optional list of media IDs to attach to the post.
    * `options` - Additional platform-specific options.
    
  ## Returns
  
    * `{:ok, post}` - If the post was created successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @callback create_post(
              user_id :: String.t(),
              content :: String.t(),
              media_ids :: [String.t()] | nil,
              options :: keyword()
            ) :: {:ok, map()} | {:error, any()}

  @doc """
  Uploads media to the social media platform.
  
  ## Parameters
  
    * `user_id` - The ID of the user uploading the media.
    * `media_path` - The path to the media file.
    * `mime_type` - The MIME type of the media file.
    * `options` - Additional platform-specific options.
    
  ## Returns
  
    * `{:ok, media_id}` - If the media was uploaded successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @callback upload_media(
              user_id :: String.t(),
              media_path :: String.t(),
              mime_type :: String.t(),
              options :: keyword()
            ) :: {:ok, String.t()} | {:error, any()}

  @doc """
  Deletes a post from the social media platform.
  
  ## Parameters
  
    * `user_id` - The ID of the user who owns the post.
    * `post_id` - The ID of the post to delete.
    
  ## Returns
  
    * `{:ok, result}` - If the post was deleted successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @callback delete_post(user_id :: String.t(), post_id :: String.t()) ::
              {:ok, map()} | {:error, any()}

  @doc """
  Retrieves the user's timeline from the social media platform.
  
  ## Parameters
  
    * `user_id` - The ID of the user whose timeline to retrieve.
    * `options` - Additional options such as limit, offset, etc.
    
  ## Returns
  
    * `{:ok, posts}` - If the timeline was retrieved successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @callback get_timeline(user_id :: String.t(), options :: keyword()) ::
              {:ok, [map()]} | {:error, any()}

  @doc """
  Retrieves the user's profile from the social media platform.
  
  ## Parameters
  
    * `user_id` - The ID of the user whose profile to retrieve.
    
  ## Returns
  
    * `{:ok, profile}` - If the profile was retrieved successfully.
    * `{:error, reason}` - If an error occurs.
  """
  @callback get_profile(user_id :: String.t()) :: {:ok, map()} | {:error, any()}

  @doc """
  Refreshes the user's authentication tokens if needed.
  
  ## Parameters
  
    * `user_id` - The ID of the user whose tokens to refresh.
    
  ## Returns
  
    * `{:ok, tokens}` - If the tokens were refreshed successfully.
    * `{:ok, :not_needed}` - If token refresh was not needed.
    * `{:error, reason}` - If an error occurs.
  """
  @callback refresh_tokens(user_id :: String.t()) ::
              {:ok, map() | :not_needed} | {:error, any()}
end

