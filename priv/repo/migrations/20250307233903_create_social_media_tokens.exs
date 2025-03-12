defmodule Myapp.Repo.Migrations.CreateSocialMediaTokens do
  use Ecto.Migration

  def change do
    create table(:social_media_tokens) do
      add :access_token, :binary, null: false
      add :refresh_token, :binary
      add :expires_at, :utc_datetime
      add :platform, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :metadata, :map
      add :last_used_at, :utc_datetime

      timestamps()
    end

    # Index for faster lookups based on user_id
    create index(:social_media_tokens, [:user_id])
    
    # Ensure a user can only have one token per platform
    create unique_index(:social_media_tokens, [:user_id, :platform])
  end
end

