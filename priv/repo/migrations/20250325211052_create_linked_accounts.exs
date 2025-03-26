defmodule Myapp.Repo.Migrations.CreateLinkedAccounts do
  use Ecto.Migration

  def change do
    create table(:linked_accounts) do
      add :primary_user_id, references(:users, on_delete: :delete_all), null: false
      add :linked_user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string

      timestamps(type: :utc_datetime)
    end

    create index(:linked_accounts, [:primary_user_id])
    create index(:linked_accounts, [:linked_user_id])
    create unique_index(:linked_accounts, [:primary_user_id, :linked_user_id], name: :primary_linked_user_index)
  end
end

