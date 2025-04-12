defmodule Myapp.SocialAuth.Instagram.Stubs do
  @moduledoc """
  Stub implementations for Instagram API functions.
  
  This module provides stub implementations for Instagram API functions
  that are called in the codebase but not yet implemented.
  """
  
  @doc """
  Creates a media post.
  """
  def create_media_post(_conn, _content, _media_ids, _options) do
    {:ok, %{id: "post_123", caption: "Test post"}}
  end
  
  @doc """
  Uploads media to Instagram.
  """
  def upload_media(_conn, _media_binary, _mime_type, _options) do
    {:ok, %{id: "media_123", url: "https://example.com/media/123.jpg"}}
  end
  
  @doc """
  Deletes media from Instagram.
  """
  def delete_media(_conn, _post_id) do
    {:ok, %{success: true}}
  end
  
  @doc """
  Gets user media from Instagram.
  """
  def get_user_media(_conn, _opts) do
    {:ok, [%{id: "post_123", caption: "Test post"}]}
  end
  
  @doc """
  Gets user profile from Instagram.
  """
  def get_user_profile(_conn) do
    {:ok, %{id: "user_123", username: "testuser"}}
  end
  
  @doc """
  Refreshes a long-lived token.
  """
  def refresh_long_lived_token(_token) do
    {:ok, %{access_token: "new_token", expires_in: 3600}}
  end
  
  @doc """
  Creates a client with a token.
  """
  def client_with_token(_token) do
    %{token: "token_123"}
  end
end
