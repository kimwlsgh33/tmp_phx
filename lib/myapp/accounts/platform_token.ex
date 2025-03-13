defmodule Myapp.Accounts.PlatformToken do
  @moduledoc """
  Schema for storing social media platform access tokens.
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

