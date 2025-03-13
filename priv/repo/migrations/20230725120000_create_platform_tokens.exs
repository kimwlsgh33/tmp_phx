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

    # Create a unique index to ensure one token per platform per user
    create unique_index(:platform_tokens, [:user_id, :platform])

    # Create an index on expires_at for efficient token expiration queries
    create index(:platform_tokens, [:expires_at])

    # Create an index on platform for efficient platform-specific queries
    create index(:platform_tokens, [:platform])
  end
end

