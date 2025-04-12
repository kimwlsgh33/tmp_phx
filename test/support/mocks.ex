# The ThreadsBehaviour has been moved to lib/myapp/threads/behaviour.ex
# This is just an alias for backward compatibility
defmodule Myapp.ThreadsBehaviour do
  @moduledoc """
  Alias for Myapp.Threads.Behaviour for backward compatibility.
  """
  defmacro __using__(_) do
    quote do
      @behaviour Myapp.Threads.Behaviour
    end
  end

  # Re-export types and callbacks from the new module
  @type thread_id :: Myapp.Threads.Behaviour.thread_id()
  @type user_id :: Myapp.Threads.Behaviour.user_id()
  @type thread :: Myapp.Threads.Behaviour.thread()
  @type thread_params :: Myapp.Threads.Behaviour.thread_params()
  @type update_params :: Myapp.Threads.Behaviour.update_params()

  @callback create_thread(String.t()) :: {:ok, map()} | {:error, String.t()}
  @callback create_thread(user_id(), thread_params()) :: {:ok, thread()} | {:error, String.t()}
  @callback list_threads(user_id()) :: {:ok, [thread()]} | {:error, String.t()}
  @callback update_thread(thread_id(), thread_params()) :: {:ok, thread()} | {:error, String.t()}
  @callback delete_thread(thread_id()) :: {:ok, thread()} | {:error, String.t()}
  @callback get_thread(thread_id()) :: {:ok, thread()} | {:error, String.t()}
  @callback reply_to_thread(thread_id(), String.t()) :: {:ok, map()} | {:error, String.t()}
end

defmodule Myapp.Mocks do
  @moduledoc """
  This module contains mock definitions for external APIs and services
  used in testing.

  It uses Mox for defining mock implementations of behavior modules.

  ## Usage

  Call `setup_mocks/0` at the start of your test setup to ensure all mocks
  are properly configured in the application environment.
  """

  # Import Mox for defining mocks
  import Mox

  @doc """
  Defines all mocks used in the application.
  """
  # Define mock for Threads module
  defmock(Myapp.MockThreads, for: Myapp.ThreadsBehaviour)

  # Define mock for Instagram API
  defmock(Myapp.MockInstagram, for: Myapp.InstagramBehaviour)

  # Define mock for Tokens module
  defmock(Myapp.MockTokens, for: Myapp.TokensBehaviour)

  @doc """
  Sets up the application environment to use mock modules in tests.

  This function should be called during test setup to ensure all
  application components use the mock implementations rather than
  real implementations.

  ## Example

      setup do
        Myapp.Mocks.setup_mocks()
        :ok
      end
  """
  def setup_mocks do
    # Configure application to use thread mock implementation
    Application.put_env(:myapp, :threads_module, Myapp.MockThreads)

    # Configure application to use Instagram mock implementation
    Application.put_env(:myapp, :instagram_api, Myapp.MockInstagram)

    # Configure application to use tokens mock implementation
    Application.put_env(:myapp, :tokens_module, Myapp.MockTokens)

    :ok
  end
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

# Documentation on adding mocks to test configuration
# Instructions for manual configuration:
#
# Add the following to your test.exs config file if not using setup_mocks/0:
#
# ```elixir
# config :myapp, :threads_module, Myapp.MockThreads
# config :myapp, :instagram_api, Myapp.MockInstagram
# ```
