defmodule Myapp.Repo.Migrations.AddOauthFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :provider, :string
      add :provider_id, :string
      add :avatar_url, :string
    end

    create index(:users, [:provider, :provider_id], unique: true)
  end
end
