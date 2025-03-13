defmodule Myapp.Repo.Migrations.CreatePlatformUploads do
  use Ecto.Migration

  def change do
    create table(:platform_uploads) do
      add :platform, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :platform_content_id, :string
      add :content_type, :string, null: false
      add :content_id, :integer, null: false
      add :error_message, :text
      add :metadata, :map, default: %{}
      add :uploaded_at, :utc_datetime
      add :last_sync_at, :utc_datetime

      timestamps()
    end

    # Ensure unique platform uploads per content
    create unique_index(:platform_uploads, [:platform, :content_type, :content_id],
      name: :platform_uploads_platform_content_index
    )

    # Indexes for common queries
    create index(:platform_uploads, [:status])
    create index(:platform_uploads, [:content_type, :content_id])
    create index(:platform_uploads, [:platform, :status])
    create index(:platform_uploads, [:uploaded_at])
    create index(:platform_uploads, [:last_sync_at])

    # Create an index on metadata for efficient JSON querying
    execute "CREATE INDEX platform_uploads_metadata_idx ON platform_uploads USING gin (metadata jsonb_path_ops)",
           "DROP INDEX platform_uploads_metadata_idx"

    # Create partial indexes for common status queries
    create index(:platform_uploads, [:platform, :last_sync_at],
      where: "status = 'completed'",
      name: :platform_uploads_completed_sync_index
    )

    create index(:platform_uploads, [:platform, :content_type, :last_sync_at],
      where: "status = 'failed'",
      name: :platform_uploads_failed_index
    )

    # Create index for platform content ID lookups
    create index(:platform_uploads, [:platform_content_id])

    # Create composite index for status reporting
    create index(:platform_uploads, [:content_type, :platform, :status])
  end
end

