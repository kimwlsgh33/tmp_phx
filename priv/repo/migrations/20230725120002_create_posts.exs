defmodule Myapp.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string, null: false
      add :content, :text, null: false
      add :file_paths, {:array, :string}, default: []
      add :status, :string, default: "draft"
      add :published_at, :utc_datetime
      add :metadata, :map, default: %{}
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    # Indexes for efficient querying
    create index(:posts, [:user_id])
    create index(:posts, [:status])
    create index(:posts, [:published_at])

    # Create a gin index on file_paths array for efficient file querying
    execute "CREATE INDEX posts_file_paths_idx ON posts USING gin (file_paths array_ops)",
           "DROP INDEX posts_file_paths_idx"

    # Create a gin index on metadata for efficient JSON querying
    execute "CREATE INDEX posts_metadata_idx ON posts USING gin (metadata jsonb_path_ops)",
           "DROP INDEX posts_metadata_idx"
  end
end

