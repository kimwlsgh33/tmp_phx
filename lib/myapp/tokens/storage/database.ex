defmodule Myapp.Tokens.Storage.Database do
  @moduledoc """
  Database storage adapter for tokens.

  This module implements the `Myapp.Tokens.Storage.Adapter` behaviour
  using Ecto and the database for persistent token storage.
  """

  @behaviour Myapp.Tokens.Storage.Adapter

  alias Myapp.Repo
  alias Myapp.Accounts.{User, UserToken, SocialMediaToken}
  import Ecto.Query

  @impl true
  def store_session_token(token, user_id, _metadata) do
    user = Repo.get(User, user_id)

    if user do
      {_token, user_token} = UserToken.build_session_token(user)

      # Override the token with the one provided
      user_token = %{user_token | token: token}

      case Repo.insert(user_token) do
        {:ok, stored_token} -> {:ok, stored_token}
        {:error, changeset} -> {:error, {:storage_error, changeset}}
      end
    else
      {:error, :user_not_found}
    end
  end

  @impl true
  def get_session_token(token) do
    with {:ok, query} <- UserToken.verify_session_token_query(token),
         %User{id: user_id} <- Repo.one(query) do
      {:ok, user_id}
    else
      nil -> {:error, :token_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def delete_session_token(token) do
    case Repo.delete_all(UserToken.by_token_and_context_query(token, "session")) do
      {count, _} when count > 0 -> :ok
      {0, _} -> {:error, :token_not_found}
    end
  end

  @impl true
  def delete_user_session_tokens(user_id, except_token) do
    query =
      from t in UserToken,
        where: t.user_id == ^user_id,
        where: t.context == "session",
        where: t.token != ^except_token

    {_count, _} = Repo.delete_all(query)
    :ok
  end

  @impl true
  def store_email_token(token, user_id, context, _metadata) do
    user = Repo.get(User, user_id)

    if user do
      {_encoded_token, user_token} = UserToken.build_email_token(user, context)

      # Override the token with the one provided
      user_token = %{user_token | token: token}

      case Repo.insert(user_token) do
        {:ok, stored_token} -> {:ok, stored_token}
        {:error, changeset} -> {:error, {:storage_error, changeset}}
      end
    else
      {:error, :user_not_found}
    end
  end

  @impl true
  def get_email_token(token, context) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, context),
         %User{id: user_id} <- Repo.one(query) do
      {:ok, user_id}
    else
      nil -> {:error, :token_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def store_social_token(user_id, provider, token_data) do
    # Extract token data
    access_token = Map.get(token_data, :access_token)
    refresh_token = Map.get(token_data, :refresh_token)
    expires_at = Map.get(token_data, :expires_at)
    provider_user_id = Map.get(token_data, :provider_user_id)
    scope = Map.get(token_data, :scope)

    # Create a changeset for the social media token
    changeset = %SocialMediaToken{}
      |> Ecto.Changeset.cast(%{
        user_id: user_id,
        provider: provider,
        access_token: access_token,
        refresh_token: refresh_token,
        expires_at: expires_at,
        provider_user_id: provider_user_id,
        scope: scope,
        token_type: "Bearer",
        # Store metadata as a map
        metadata: %{
          last_used_at: DateTime.utc_now()
        }
      }, [:user_id, :provider, :access_token, :refresh_token, :expires_at, :provider_user_id, :scope, :token_type, :metadata])
      |> Ecto.Changeset.validate_required([:user_id, :provider, :access_token])

    # Insert the token
    case Repo.insert(changeset) do
      {:ok, token} ->
        {:ok, %{
          access_token: token.access_token,
          refresh_token: token.refresh_token,
          expires_at: token.expires_at,
          provider_user_id: token.provider_user_id,
          scope: token.scope
        }}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @impl true
  def get_social_token(user_id, provider) do
    case SocialMediaToken.get_active_tokens(user_id, provider) do
      {:ok, token} ->
        {:ok, %{
          access_token: token.access_token_text,
          refresh_token: token.refresh_token_text,
          expires_at: token.expires_at,
          provider_user_id: token.provider_user_id,
          scope: token.scope
        }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def update_social_token(user_id, provider, token_data) do
    # First get the existing token
    with {:ok, token} <- SocialMediaToken.get_active_tokens(user_id, provider) do
      # Update the token with new data
      token
      |> SocialMediaToken.update_changeset(token_data)
      |> Repo.update()
    end
  end

  @impl true
  def delete_social_token(user_id, provider) do
    SocialMediaToken.revoke_active_tokens(user_id, provider)
  end
end
