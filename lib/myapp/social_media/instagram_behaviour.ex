defmodule Myapp.InstagramBehaviour do
  @moduledoc """
  Defines the behaviour for Instagram API interactions.
  
  This module specifies the contract that all Instagram API implementations must follow,
  allowing for easy mocking in tests.
  """
  
  @doc """
  Uploads a photo to Instagram.
  
  ## Parameters
  
  - `user_id` - The ID of the user
  - `media_path` - Path to the media file
  - `caption` - Optional caption for the post
  - `opts` - Additional options
  
  ## Returns
  
  - `{:ok, post_data}` - If the upload was successful
  - `{:error, reason}` - If there was an error
  """
  @callback upload_photo(user_id :: integer(), media_path :: String.t(), caption :: String.t(), opts :: Keyword.t()) ::
              {:ok, map()} | {:error, any()}
  
  @doc """
  Uploads a video to Instagram.
  
  ## Parameters
  
  - `user_id` - The ID of the user
  - `media_path` - Path to the media file
  - `caption` - Optional caption for the post
  - `opts` - Additional options
  
  ## Returns
  
  - `{:ok, post_data}` - If the upload was successful
  - `{:error, reason}` - If there was an error
  """
  @callback upload_video(user_id :: integer(), media_path :: String.t(), caption :: String.t(), opts :: Keyword.t()) ::
              {:ok, map()} | {:error, any()}
  
  @doc """
  Gets the user's Instagram profile.
  
  ## Parameters
  
  - `user_id` - The ID of the user
  
  ## Returns
  
  - `{:ok, profile_data}` - If the profile was retrieved successfully
  - `{:error, reason}` - If there was an error
  """
  @callback get_profile(user_id :: integer()) ::
              {:ok, map()} | {:error, any()}
end
