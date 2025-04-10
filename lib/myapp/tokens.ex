defmodule Myapp.Tokens do
  @moduledoc """
  Unified token management system for the application.

  This module serves as the primary entry point for all token operations,
  providing a consistent interface for:

  - User authentication tokens (sessions, API)
  - Social media platform tokens
  - Email verification and password reset tokens

  ## Usage

  ### User Authentication

  ```elixir
  # Create a new session token
  {:ok, token, _metadata} = Myapp.Tokens.create_session_token(user)

  # Verify a session token
  {:ok, user} = Myapp.Tokens.verify_session_token(token)

  # Revoke a session token
  :ok = Myapp.Tokens.revoke_session_token(token)
  ```

  ### Social Media Tokens

  ```elixir
  # Store tokens for a social media platform
  {:ok, token_data} = Myapp.Tokens.store_social_token(user_id, :twitter, token_data)

  # Get tokens for a social media platform
  {:ok, token_data} = Myapp.Tokens.get_social_token(user_id, :twitter)

  # Refresh tokens for a social media platform
  {:ok, new_token_data} = Myapp.Tokens.refresh_social_token(user_id, :twitter)

  # Revoke tokens for a social media platform
  :ok = Myapp.Tokens.revoke_social_token(user_id, :twitter)
  ```

  ### Email and Password Tokens

  ```elixir
  # Create an email confirmation token
  {:ok, token} = Myapp.Tokens.create_email_token(user, "confirm")

  # Verify an email token
  {:ok, user} = Myapp.Tokens.verify_email_token(token, "confirm")
  ```
  """

  alias Myapp.Repo
  alias Myapp.Accounts.{User, UserToken, SocialMediaToken}
  alias Myapp.Tokens.{Cache, Encryption, Metrics}

  import Ecto.Query

  @doc """
  Creates a session token for a user.

  Returns `{:ok, token, metadata}` where:
  - `token` is the session token string
  - `metadata` contains additional information about the token

  ## Examples

      iex> {:ok, token, _metadata} = Myapp.Tokens.create_session_token(user)
      {:ok, "g3QAAAACZAAEZGF0YW0AAAAkNDI4M...", %{context: "session"}}
  """
  def create_session_token(%User{} = user) do
    {token, user_token} = UserToken.build_session_token(user)

    result = with {:ok, %UserToken{} = saved_token} <- Repo.insert(user_token) do
      metadata = %{
        context: saved_token.context,
        created_at: saved_token.inserted_at
      }

      # Cache the token for faster lookups
      Cache.put_session_token(token, user.id)

      {:ok, token, metadata}
    end

    # Record metrics
    Metrics.record_session_token_create(result)
  end

  @doc """
  Verifies a session token and returns the associated user.

  Returns `{:ok, user}` if the token is valid, or `{:error, reason}` if invalid.

  ## Examples

      iex> {:ok, %User{}} = Myapp.Tokens.verify_session_token(token)
      {:ok, %User{email: "user@example.com", ...}}

      iex> Myapp.Tokens.verify_session_token("invalid")
      {:error, :invalid_token}
  """
  def verify_session_token(token) do
    # First try to get from cache for performance
    result = case Cache.get_session_token(token) do
      {:ok, user_id} ->
        # Token found in cache, get the user
        Metrics.record_cache_hit(:session_token)
        case Repo.get(User, user_id) do
          %User{} = user -> {:ok, user}
          nil -> {:error, :user_not_found}
        end

      {:error, :not_found} ->
        # Not in cache, check the database
        Metrics.record_cache_miss(:session_token)
        with {:ok, query} <- UserToken.verify_session_token_query(token),
             %User{} = user <- Repo.one(query) do
          # Cache the result for future lookups
          Cache.put_session_token(token, user.id)
          {:ok, user}
        else
          nil -> {:error, :invalid_token}
          {:error, reason} -> {:error, reason}
        end
    end

    # Record metrics
    Metrics.record_session_token_verify(result)
  end

  @doc """
  Revokes a session token.

  Returns `:ok` if the token was revoked, or `{:error, reason}` if there was an error.

  ## Examples

      iex> Myapp.Tokens.revoke_session_token(token)
      :ok
  """
  def revoke_session_token(token) do
    # Remove from cache first
    Cache.delete_session_token(token)

    # Then delete from database
    result = case Repo.delete_all(UserToken.by_token_and_context_query(token, "session")) do
      {count, _} when count > 0 -> :ok
      {0, _} -> {:error, :token_not_found}
    end

    # Record metrics
    Metrics.record_session_token_revoke(result)
  end

  @doc """
  Revokes all session tokens for a user except the given token.

  This is useful when a user logs in and you want to revoke all other sessions.

  ## Examples

      iex> Myapp.Tokens.revoke_other_session_tokens(user, current_token)
      :ok
  """
  def revoke_other_session_tokens(%User{id: user_id}, current_token) do
    query =
      from t in UserToken,
        where: t.user_id == ^user_id,
        where: t.context == "session",
        where: t.token != ^current_token

    # Clear cache for these tokens (would need to implement this)
    Cache.delete_user_session_tokens(user_id, except: current_token)

    {_count, _} = Repo.delete_all(query)
    :ok
  end

  @doc """
  Creates an email token for the given user and context.

  Contexts include:
  - "confirm" - For email confirmation
  - "reset_password" - For password reset
  - "change:current@email.com" - For changing email

  ## Examples

      iex> {:ok, token} = Myapp.Tokens.create_email_token(user, "confirm")
      {:ok, "g3QAAAACZAAEZGF0YW0AAAAkNDI4M..."}
  """
  def create_email_token(%User{} = user, context) do
    {encoded_token, user_token} = UserToken.build_email_token(user, context)

    result = with {:ok, %UserToken{}} <- Repo.insert(user_token) do
      {:ok, encoded_token}
    end

    # Record metrics
    Metrics.record_email_token_create(result)
  end

  @doc """
  Verifies an email token for the given context.

  Returns `{:ok, user}` if the token is valid, or `{:error, reason}` if invalid.

  ## Examples

      iex> {:ok, user} = Myapp.Tokens.verify_email_token(token, "confirm")
      {:ok, %User{}}
  """
  def verify_email_token(token, context) do
    result = with {:ok, query} <- UserToken.verify_email_token_query(token, context),
         %User{} = user <- Repo.one(query) do
      {:ok, user}
    else
      nil -> {:error, :invalid_token}
      {:error, reason} -> {:error, reason}
    end

    # Record metrics
    Metrics.record_email_token_verify(result)
  end

  @doc """
  Stores social media tokens for a user and platform.

  Returns `{:ok, token_data}` if successful, or `{:error, reason}` if there was an error.

  ## Examples

      iex> token_data = %{
      ...>   "access_token" => "ACCESS_TOKEN",
      ...>   "refresh_token" => "REFRESH_TOKEN",
      ...>   "expires_in" => 3600
      ...> }
      iex> {:ok, stored_data} = Myapp.Tokens.store_social_token(user_id, :twitter, token_data)
      {:ok, %{...}}
  """
  def store_social_token(user_id, provider, token_data) when is_atom(provider) do
    # Store in database with encryption
    result = case SocialMediaToken.store_tokens(user_id, provider, token_data) do
      {:ok, token} ->
        # Cache the access token for faster lookups
        Cache.put_social_token(user_id, provider, %{
          access_token: token.access_token_text,
          refresh_token: token.refresh_token_text,
          expires_at: token.expires_at
        })

        {:ok, %{
          access_token: token.access_token_text,
          refresh_token: token.refresh_token_text,
          expires_at: token.expires_at,
          provider_user_id: token.provider_user_id,
          scope: token.scope
        }}

      {:error, changeset} ->
        {:error, {:storage_error, changeset}}
    end

    # Record metrics
    Metrics.record_social_token_store(result)
  end

  @doc """
  Gets social media tokens for a user and platform.

  Returns `{:ok, token_data}` if found, or `{:error, reason}` if not found or expired.
  If the token is expired but can be refreshed, it will attempt to refresh it.

  ## Examples

      iex> {:ok, token_data} = Myapp.Tokens.get_social_token(user_id, :twitter)
      {:ok, %{access_token: "ACCESS_TOKEN", ...}}
  """
  def get_social_token(user_id, provider) when is_atom(provider) do
    # First try to get from cache
    result = case Cache.get_social_token(user_id, provider) do
      {:ok, token_data} ->
        # Cache hit
        Metrics.record_cache_hit(:social_token)
        # Check if token is expired
        if token_expired?(token_data) do
          # Try to refresh if possible
          refresh_social_token(user_id, provider)
        else
          {:ok, token_data}
        end

      {:error, :not_found} ->
        # Cache miss
        Metrics.record_cache_miss(:social_token)
        # Not in cache, get from database
        case SocialMediaToken.get_active_tokens(user_id, provider) do
          {:ok, token} ->
            token_data = %{
              access_token: token.access_token_text,
              refresh_token: token.refresh_token_text,
              expires_at: token.expires_at,
              provider_user_id: token.provider_user_id,
              scope: token.scope
            }

            # Cache for future lookups
            Cache.put_social_token(user_id, provider, token_data)

            # Check if token needs refresh
            if SocialMediaToken.needs_refresh?(token) do
              refresh_social_token(user_id, provider)
            else
              {:ok, token_data}
            end

          {:error, reason} ->
            {:error, reason}
        end
    end

    # Record metrics
    Metrics.record_social_token_get(result)
  end

  @doc """
  Refreshes social media tokens for a user and platform.

  Returns `{:ok, new_token_data}` if successful, or `{:error, reason}` if there was an error.

  ## Examples

      iex> {:ok, new_token_data} = Myapp.Tokens.refresh_social_token(user_id, :twitter)
      {:ok, %{access_token: "NEW_ACCESS_TOKEN", ...}}
  """
  def refresh_social_token(user_id, provider) when is_atom(provider) do
    # This would call the appropriate auth module to refresh the token
    # For now, we'll just return an error
    result = {:error, :not_implemented}

    # Record metrics
    Metrics.record_social_token_refresh(result)

    # In a real implementation, you would:
    # 1. Get the current token from the database
    # 2. Call the appropriate auth module to refresh it
    # 3. Update the token in the database
    # 4. Update the cache
    # 5. Return the new token data
  end

  @doc """
  Revokes social media tokens for a user and platform.

  Returns `:ok` if successful, or `{:error, reason}` if there was an error.

  ## Examples

      iex> Myapp.Tokens.revoke_social_token(user_id, :twitter)
      :ok
  """
  def revoke_social_token(user_id, provider) when is_atom(provider) do
    # Remove from cache
    Cache.delete_social_token(user_id, provider)

    # Mark as revoked in database
    result = case SocialMediaToken.revoke_active_tokens(user_id, provider) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end

    # Record metrics
    Metrics.record_social_token_revoke(result)
  end

  # Private helpers

  defp token_expired?(%{expires_at: nil}), do: false
  defp token_expired?(%{expires_at: expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :lt
  end
end
