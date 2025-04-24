defmodule Myapp.Repo.Migrations.CreateUploads do
  use Ecto.Migration

  def change do
    create table(:uploads) do
      add :file_name, :string, null: false
      add :file_id, :string, null: false
      add :user_id, references(:users, on_delete: :nothing)
      add :url, :string
      add :status, :string, null: false, default: "in_progress"
      add :bytes_uploaded, :bigint, default: 0
      timestamps()
    end
    create unique_index(:uploads, [:file_id])
    create index(:uploads, [:user_id])
  end
end
