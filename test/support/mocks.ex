Mox.defmock(Myapp.MockThreads, for: Myapp.Threads)

# Set up the application environment to use the mock module in tests
Application.put_env(:myapp, :threads_module, Myapp.MockThreads)

defmodule Myapp.Mocks do
  @moduledoc """
  This module contains mock definitions for external APIs and services
  used in testing.

  It uses Mox for defining mock implementations of behavior modules.
  """

  # Import Mox for defining mocks
  import Mox
  
  # Define mock for Instagram API
  defmock(Myapp.MockInstagram, for: Myapp.InstagramBehaviour)
end

defmodule Myapp.InstagramBehaviour do
  @moduledoc """
  Behaviour module defining the interface for the Instagram API.
  
  This allows mocking the Instagram API for testing without relying on the
  actual external service.
  """
  
  @doc """
  Validates an Instagram access token.
  """
  @callback validate_access_token(opts :: Keyword.t()) :: 
              {:ok, String.t()} | 
              {:error, String.t()}
              
  @doc """
  Lists media from an Instagram account.
  """
  @callback list_media() :: 
              {:ok, map()} | 
              {:error, String.t()}
              
  @doc """
  Posts a photo to Instagram.
  """
  @callback post_photo(image_path :: String.t(), opts :: Keyword.t()) :: 
              {:ok, map()} | 
              {:error, String.t()}
              
  @doc """
  Posts a video to Instagram.
  """
  @callback post_video(video_path :: String.t(), opts :: Keyword.t()) :: 
              {:ok, map()} | 
              {:error, String.t()}
              
  @doc """
  Creates a media container for Instagram media upload.
  """
  @callback create_media_container(
                media_type :: String.t(),
                media_path :: String.t(),
                caption :: String.t(),
                location_id :: String.t() | nil,
                user_tags :: list() | nil,
                access_token :: String.t(),
                cover_image_path :: String.t() | nil
             ) ::
              {:ok, map()} |
              {:error, String.t()}
              
  @doc """
  Publishes a media container to make it visible on Instagram.
  """
  @callback publish_media(creation_id :: String.t(), access_token :: String.t()) ::
              {:ok, map()} |
              {:error, String.t()}
              
  @doc """
  Gets information about a specific media post.
  """
  @callback get_media(media_id :: String.t(), opts :: Keyword.t()) ::
              {:ok, map()} |
              {:error, String.t()}
              
  @doc """
  Generic upload media function that can be used for testing.
  """
  @callback upload_media(media_path :: String.t(), opts :: Keyword.t()) ::
              {:ok, map()} |
              {:error, String.t()}
end

# Application configuration for tests
# This is added to the test config to make the application use the mock instead of the real module
config_update = """
# Add the following to your test.exs config file:

config :myapp, :instagram_api, Myapp.MockInstagram
"""

