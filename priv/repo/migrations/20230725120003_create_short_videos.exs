defmodule Myapp.Repo.Migrations.CreateShortVideos do
  use Ecto.Migration

  def change do
    create table(:short_videos) do
      add :title, :string, null: false
      add :description, :text, null: false
      add :video_path, :string
      add :thumbnail_path, :string
      add :duration, :integer  # Duration in seconds
      add :status, :string, default: "draft"
      add :published_at, :utc_datetime
      add :metadata, :map, default: %{}

      # Video dimensions
      add :width, :integer
      add :height, :integer

      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    # Indexes for efficient querying
    create index(:short_videos, [:user_id])
    create index(:short_videos, [:status])
    create index(:short_videos, [:published_at])
    create index(:short_videos, [:duration])

    # Create an index on metadata for efficient JSON querying
    execute "CREATE INDEX short_videos_metadata_idx ON short_videos USING gin (metadata jsonb_path_ops)",
           "DROP INDEX short_videos_metadata_idx"

    # Create partial index for published videos for faster listing
    create index(:short_videos, [:published_at],
      where: "status = 'published'",
      name: :short_videos_published_index
    )

    # Create index for video dimensions for efficient filtering
    create index(:short_videos, [:width, :height])
  end
end

