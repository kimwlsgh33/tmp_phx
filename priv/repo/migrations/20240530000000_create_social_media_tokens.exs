defmodule Myapp.Repo.Migrations.CreateSocialMediaTokens do
  use Ecto.Migration

  def change do
    create table(:social_media_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :provider, :string, null: false
      add :access_token, :text, null: false
      add :refresh_token, :text
      add :token_type, :string
      add :scope, :string
      add :expires_at, :utc_datetime
      add :refresh_token_expires_at, :utc_datetime
      add :provider_user_id, :string
      add :metadata, :map, default: %{}
      add :revoked_at, :utc_datetime
      
      timestamps()
    end

    create index(:social_media_tokens, [:user_id])
    create index(:social_media_tokens, [:provider])
    create unique_index(:social_media_tokens, [:user_id, :provider, :provider_user_id],
      where: "revoked_at IS NULL",
      name: :active_social_tokens_index
    )
  end
end

