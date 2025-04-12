defmodule Myapp.Repo.Migrations.AddLastUsedAtToSocialMediaTokens do
  use Ecto.Migration

  def change do
    alter table(:social_media_tokens) do
      add :last_used_at, :utc_datetime
    end
  end
end
