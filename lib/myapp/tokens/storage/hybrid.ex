defmodule Myapp.Tokens.Storage.Hybrid do
  @moduledoc """
  Hybrid storage adapter for tokens.

  This module implements the `Myapp.Tokens.Storage.Adapter` behaviour
  using both database and cache storage for optimal performance.

  It stores tokens in both the database (for persistence) and the cache
  (for fast access), and handles synchronization between the two.
  """

  @behaviour Myapp.Tokens.Storage.Adapter

  alias Myapp.Tokens.Storage.{Database, Cache}
  alias Myapp.Tokens.Metrics

  @impl true
  def store_session_token(token, user_id, metadata) do
    # First store in the database for persistence
    result = Database.store_session_token(token, user_id, metadata)

    # If successful, also store in the cache for fast access
    case result do
      {:ok, _stored_token} ->
        Cache.store_session_token(token, user_id, metadata)
        result

      error ->
        error
    end
  end

  @impl true
  def get_session_token(token) do
    # First try to get from cache for performance
    case Cache.get_session_token(token) do
      {:ok, user_id} ->
        # Cache hit
        Metrics.record_cache_hit(:session_token)
        {:ok, user_id}

      {:error, :not_found} ->
        # Cache miss, try database
        Metrics.record_cache_miss(:session_token)
        case Database.get_session_token(token) do
          {:ok, user_id} = result ->
            # Found in database, cache for future lookups
            Cache.store_session_token(token, user_id, %{})
            result

          error ->
            error
        end
    end
  end

  @impl true
  def delete_session_token(token) do
    # Delete from both cache and database
    Cache.delete_session_token(token)
    Database.delete_session_token(token)
  end

  @impl true
  def delete_user_session_tokens(user_id, except_token) do
    # Delete from both cache and database
    Cache.delete_user_session_tokens(user_id, except_token)
    Database.delete_user_session_tokens(user_id, except_token)
  end

  @impl true
  def store_email_token(token, user_id, context, metadata) do
    # First store in the database for persistence
    result = Database.store_email_token(token, user_id, context, metadata)

    # If successful, also store in the cache for fast access
    case result do
      {:ok, _stored_token} ->
        Cache.store_email_token(token, user_id, context, metadata)
        result

      error ->
        error
    end
  end

  @impl true
  def get_email_token(token, context) do
    # First try to get from cache for performance
    case Cache.get_email_token(token, context) do
      {:ok, user_id} ->
        # Cache hit
        Metrics.record_cache_hit(:email_token)
        {:ok, user_id}

      {:error, :not_found} ->
        # Cache miss, try database
        Metrics.record_cache_miss(:email_token)
        case Database.get_email_token(token, context) do
          {:ok, user_id} = result ->
            # Found in database, cache for future lookups
            Cache.store_email_token(token, user_id, context, %{})
            result

          error ->
            error
        end
    end
  end

  @impl true
  def store_social_token(user_id, provider, token_data) do
    # First store in the database for persistence
    result = Database.store_social_token(user_id, provider, token_data)

    # If successful, also store in the cache for fast access
    case result do
      {:ok, stored_token} ->
        # Extract the token data from the stored token
        token_data_for_cache = %{
          access_token: stored_token.access_token,
          refresh_token: stored_token.refresh_token,
          expires_at: stored_token.expires_at,
          provider_user_id: stored_token.provider_user_id,
          scope: stored_token.scope
        }

        Cache.store_social_token(user_id, provider, token_data_for_cache)
        {:ok, token_data_for_cache}

      error ->
        error
    end
  end

  @impl true
  def get_social_token(user_id, provider) do
    # First try to get from cache for performance
    case Cache.get_social_token(user_id, provider) do
      {:ok, token_data} ->
        # Cache hit
        Metrics.record_cache_hit(:social_token)

        # Check if token is expired
        if token_expired?(token_data) do
          # Token is expired, remove from cache and try database
          Cache.delete_social_token(user_id, provider)
          get_from_database(user_id, provider)
        else
          {:ok, token_data}
        end

      {:error, :not_found} ->
        # Cache miss, try database
        Metrics.record_cache_miss(:social_token)
        get_from_database(user_id, provider)
    end
  end

  defp get_from_database(user_id, provider) do
    case Database.get_social_token(user_id, provider) do
      {:ok, token_data} = result ->
        # Found in database, cache for future lookups
        Cache.store_social_token(user_id, provider, token_data)
        result

      error ->
        error
    end
  end

  @impl true
  def update_social_token(user_id, provider, token_data) do
    # Update in both database and cache
    result = Database.update_social_token(user_id, provider, token_data)

    case result do
      {:ok, updated_token} ->
        # Extract the token data from the updated token
        token_data_for_cache = %{
          access_token: updated_token.access_token_text,
          refresh_token: updated_token.refresh_token_text,
          expires_at: updated_token.expires_at,
          provider_user_id: updated_token.provider_user_id,
          scope: updated_token.scope
        }

        Cache.update_social_token(user_id, provider, token_data_for_cache)
        {:ok, token_data_for_cache}

      error ->
        error
    end
  end

  @impl true
  def delete_social_token(user_id, provider) do
    # Delete from both cache and database
    Cache.delete_social_token(user_id, provider)
    Database.delete_social_token(user_id, provider)
  end

  # Private helpers

  defp token_expired?(%{expires_at: nil}), do: false
  defp token_expired?(%{expires_at: expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :lt
  end
end
