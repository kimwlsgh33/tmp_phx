defmodule Myapp.Accounts.PlatformToken do
  @moduledoc """
  A schema and utilities for managing social media platform access tokens.

  ## Purpose
  This module handles the storage, validation, and lifecycle management of access tokens 
  used for authenticating with various social media platforms (Twitter, Facebook, etc.).
  It provides a centralized way to store OAuth tokens securely in the database and 
  perform common operations on them.

  ## Structure
  Each platform token contains:
  * `platform` - The name of the social platform (twitter, facebook, etc.)
  * `access_token` - The OAuth access token used for API requests
  * `refresh_token` - Optional token used to refresh expired access tokens
  * `expires_at` - UTC datetime when the token expires
  * `token_type` - The type of token (usually "Bearer")
  * `scope` - The permissions granted to the token
  * `user_id` - The user who owns this token

  ## Usage
  PlatformTokens are typically created during OAuth flows when a user connects their
  social media account. They are then used for making authenticated API requests to
  the respective platforms. The module provides utility functions like:
  * `expired?/1` - Check if a token has expired
  * `authorization_header/1` - Format the token for use in API requests

  ## Supported Platforms
  Currently supported platforms include:
  * Twitter
  * Facebook
  * Instagram
  * TikTok
  * YouTube
  * Vimeo

  ## Related Modules
  This module is part of the token ecosystem in the application:
  * `Myapp.Accounts.UserToken` - For authentication and session management
  * `Myapp.Accounts.SocialMediaToken` - An alternative implementation with similar purpose
  * `Myapp.TokenStore` - For in-memory token storage

  Each user can have at most one token per platform, enforced by a unique constraint.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "platform_tokens" do
    field :platform, :string
    field :access_token, :string
    field :refresh_token, :string
    field :expires_at, :utc_datetime
    field :token_type, :string, default: "Bearer"
    field :scope, :string

    belongs_to :user, Myapp.Accounts.User

    timestamps()
  end

  @doc """
  Changeset for platform tokens.
  Validates required fields and ensures tokens are stored securely.
  """
  def changeset(platform_token, attrs) do
    platform_token
    |> cast(attrs, [:platform, :access_token, :refresh_token, :expires_at, :token_type, :scope, :user_id])
    |> validate_required([:platform, :access_token, :user_id])
    |> validate_inclusion(:platform, ~w(twitter facebook instagram tiktok youtube vimeo))
    |> unique_constraint([:user_id, :platform], name: :platform_tokens_user_id_platform_index)
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Checks if the token is expired.
  """
  def expired?(%__MODULE__{expires_at: nil}), do: false
  def expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :lt
  end

  @doc """
  Returns the token with type for API requests.
  """
  def authorization_header(%__MODULE__{access_token: token, token_type: type}) do
    "#{type} #{token}"
  end

  @doc """
  Creates a migration for the platform_tokens table.
  """
  def create_migration do
    """
    defmodule Myapp.Repo.Migrations.CreatePlatformTokens do
      use Ecto.Migration

      def change do
        create table(:platform_tokens) do
          add :platform, :string, null: false
          add :access_token, :string, null: false
          add :refresh_token, :string
          add :expires_at, :utc_datetime
          add :token_type, :string
          add :scope, :string
          add :user_id, references(:users, on_delete: :delete_all), null: false

          timestamps()
        end

        create unique_index(:platform_tokens, [:user_id, :platform])
      end
    end
    """
  end
end

