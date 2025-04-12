defmodule Myapp.Tokens do
  # Implementing both behaviors causes conflicts, so we'll just use one
  # @behaviour Myapp.TokensBehaviour
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

  @behaviour Myapp.Tokens.API

  alias Myapp.Repo
  alias Myapp.Accounts.User
  alias Myapp.Tokens.{Metrics, Common}
  alias Myapp.Tokens.Storage.Factory

  # Get the configured storage adapter
  @storage Factory.create_from_config()

  # Import Ecto.Query when needed
  # import Ecto.Query

  @doc """
  Creates a session token for a user.

  Returns `{:ok, token, metadata}` where:
  - `token` is the session token string
  - `metadata` contains additional information about the token

  ## Examples

      iex> {:ok, token, _metadata} = Myapp.Tokens.create_session_token(user)
      {:ok, "g3QAAAACZAAEZGF0YW0AAAAkNDI4M...", %{context: "session"}}
  """
  @impl Myapp.Tokens.API
  def create_session_token(%User{} = user, _opts \\ []) do
    # Generate a secure token
    token = Common.generate_url_safe_token()

    # Create metadata
    metadata = %{
      context: "session",
      created_at: DateTime.utc_now()
    }

    # Store the token using the configured storage adapter
    result = case @storage.store_session_token(token, user.id, metadata) do
      {:ok, _stored_token} -> {:ok, token, metadata}
      {:error, reason} -> {:error, reason}
    end

    # Record metrics
    Metrics.record_session_token_create(result)

    result
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
  @impl Myapp.Tokens.API
  def verify_session_token(token, _opts \\ []) do
    do_verify_session_token(token)
  end

  defp do_verify_session_token(token) do
    # Get the user ID from the storage adapter
    result = case @storage.get_session_token(token) do
      {:ok, user_id} ->
        # Token found, get the user
        case Repo.get(User, user_id) do
          %User{} = user -> {:ok, user}
          nil -> {:error, :user_not_found}
        end

      {:error, reason} ->
        {:error, reason}
    end

    # Record metrics
    Metrics.record_session_token_verify(result)

    result
  end

  @doc """
  Revokes a session token.

  Returns `:ok` if the token was revoked, or `{:error, reason}` if there was an error.

  ## Examples

      iex> Myapp.Tokens.revoke_session_token(token)
      :ok
  """
  @impl Myapp.Tokens.API
  def revoke_session_token(token, _opts \\ []) do
    # Delete the token using the storage adapter
    result = @storage.delete_session_token(token)

    # Record metrics
    Metrics.record_session_token_revoke(result)

    result
  end

  @doc """
  Revokes all session tokens for a user except the given token.

  This is useful when a user logs in and you want to revoke all other sessions.

  ## Examples

      iex> Myapp.Tokens.revoke_other_session_tokens(user, current_token)
      :ok
  """
  @impl Myapp.Tokens.API
  def revoke_other_session_tokens(%User{id: user_id}, current_token, _opts \\ []) do
    # Delete all tokens for the user except the current one
    @storage.delete_user_session_tokens(user_id, current_token)
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
  @impl Myapp.Tokens.API
  def create_email_token(%User{} = user, context, _opts \\ []) do
    # Generate a secure token
    token = Common.generate_url_safe_token()

    # Create metadata
    metadata = %{
      context: context,
      created_at: DateTime.utc_now()
    }

    # Store the token using the configured storage adapter
    result = case @storage.store_email_token(token, user.id, context, metadata) do
      {:ok, _stored_token} -> {:ok, token}
      {:error, reason} -> {:error, reason}
    end

    # Record metrics
    Metrics.record_email_token_create(result)

    result
  end

  @doc """
  Verifies an email token for the given context.

  Returns `{:ok, user}` if the token is valid, or `{:error, reason}` if invalid.

  ## Examples

      iex> {:ok, user} = Myapp.Tokens.verify_email_token(token, "confirm")
      {:ok, %User{}}
  """
  @impl Myapp.Tokens.API
  def verify_email_token(token, context, _opts \\ []) do
    # Get the user ID from the storage adapter
    result = case @storage.get_email_token(token, context) do
      {:ok, user_id} ->
        # Token found, get the user
        case Repo.get(User, user_id) do
          %User{} = user -> {:ok, user}
          nil -> {:error, :user_not_found}
        end

      {:error, reason} ->
        {:error, reason}
    end

    # Record metrics
    Metrics.record_email_token_verify(result)

    result
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
  @impl Myapp.Tokens.API
  def store_social_token(user_id, provider, token_data, _opts \\ []) when is_atom(provider) do
    # Normalize the token data
    normalized_data = Common.normalize_oauth_response(token_data)

    # Store the token using the configured storage adapter
    result = @storage.store_social_token(user_id, provider, normalized_data)

    # Record metrics
    Metrics.record_social_token_store(result)

    result
  end

  @doc """
  Gets social media tokens for a user and platform.

  Returns `{:ok, token_data}` if found, or `{:error, reason}` if not found or expired.
  If the token is expired but can be refreshed, it will attempt to refresh it.

  ## Examples

      iex> {:ok, token_data} = Myapp.Tokens.get_social_token(user_id, :twitter)
      {:ok, %{access_token: "ACCESS_TOKEN", ...}}
  """
  @impl Myapp.Tokens.API
  def get_social_token(user_id, provider, _opts \\ []) when is_atom(provider) do
    # Get the token using the configured storage adapter
    result = case @storage.get_social_token(user_id, provider) do
      {:ok, token_data} ->
        # Check if token is expired
        if token_expired?(token_data) do
          # Try to refresh if possible
          refresh_social_token(user_id, provider)
        else
          {:ok, token_data}
        end

      {:error, reason} ->
        {:error, reason}
    end

    # Record metrics
    Metrics.record_social_token_get(result)

    result
  end

  @doc """
  Refreshes social media tokens for a user and platform.

  Returns `{:ok, new_token_data}` if successful, or `{:error, reason}` if there was an error.

  ## Examples

      iex> {:ok, new_token_data} = Myapp.Tokens.refresh_social_token(user_id, :twitter)
      {:ok, %{access_token: "NEW_ACCESS_TOKEN", ...}}
  """
  @impl Myapp.Tokens.API
  def refresh_social_token(_user_id, provider, _opts \\ []) when is_atom(provider) do
    # This would call the appropriate auth module to refresh the token
    # For now, we'll just return an error
    result = {:error, :not_implemented}

    # Record metrics
    Metrics.record_social_token_refresh(result)

    # In a real implementation, you would:
    # 1. Get the current token from the storage adapter
    # 2. Call the appropriate auth module to refresh it
    # 3. Update the token using the storage adapter
    # 4. Return the new token data

    result
  end

  @doc """
  Revokes social media tokens for a user and platform.

  Returns `:ok` if successful, or `{:error, reason}` if there was an error.

  ## Examples

      iex> Myapp.Tokens.revoke_social_token(user_id, :twitter)
      :ok
  """
  @impl Myapp.Tokens.API
  def revoke_social_token(user_id, provider, _opts \\ []) when is_atom(provider) do
    # Delete the token using the storage adapter
    result = @storage.delete_social_token(user_id, provider)

    # Record metrics
    Metrics.record_social_token_revoke(result)

    result
  end

  # Private helpers

  defp token_expired?(token_data) do
    case token_data do
      %{expires_at: expires_at} -> Myapp.Tokens.Common.expired?(expires_at)
      _ -> false
    end
  end
end
