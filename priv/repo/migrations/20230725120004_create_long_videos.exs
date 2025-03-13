defmodule Myapp.Repo.Migrations.CreateLongVideos do
  use Ecto.Migration

  def change do
    create table(:long_videos) do
      add :title, :string, null: false
      add :description, :text, null: false
      add :video_path, :string
      add :thumbnail_path, :string
      add :duration, :integer
      add :status, :string, default: "draft"
      add :published_at, :utc_datetime
      add :category, :string, null: false
      add :tags, {:array, :string}, default: []
      add :visibility, :string, default: "private"
      add :metadata, :map, default: %{}

      # Video dimensions and quality
      add :width, :integer
      add :height, :integer
      add :quality, :string
      add :fps, :integer

      # SEO and discoverability
      add :seo_title, :string
      add :seo_description, :text
      add :allow_comments, :boolean, default: true
      add :age_restricted, :boolean, default: false

      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    # Basic indexes
    create index(:long_videos, [:user_id])
    create index(:long_videos, [:status])
    create index(:long_videos, [:published_at])
    create index(:long_videos, [:category])
    create index(:long_videos, [:visibility])

    # Create a gin index on tags array for efficient tag searching
    execute "CREATE INDEX long_videos_tags_idx ON long_videos USING gin (tags array_ops)",
           "DROP INDEX long_videos_tags_idx"

    # Create an index on metadata for efficient JSON querying
    execute "CREATE INDEX long_videos_metadata_idx ON long_videos USING gin (metadata jsonb_path_ops)",
           "DROP INDEX long_videos_metadata_idx"

    # Create partial indexes for common filters
    create index(:long_videos, [:published_at],
      where: "status = 'published' AND visibility = 'public'",
      name: :long_videos_public_published_index
    )

    create index(:long_videos, [:age_restricted, :published_at],
      where: "status = 'published'",
      name: :long_videos_age_restricted_index
    )

    # Create composite indexes for common query patterns
    create index(:long_videos, [:category, :published_at])
    create index(:long_videos, [:quality, :duration])
    create index(:long_videos, [:width, :height, :fps])

    # Create indexes for text search
    execute "CREATE INDEX long_videos_title_trgm_idx ON long_videos USING gin (title gin_trgm_ops)",
           "DROP INDEX long_videos_title_trgm_idx"

    execute "CREATE INDEX long_videos_description_trgm_idx ON long_videos USING gin (description gin_trgm_ops)",
           "DROP INDEX long_videos_description_trgm_idx"
  end

  def up do
    # Enable the pg_trgm extension for text search
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"
  end

  def down do
    execute "DROP EXTENSION IF EXISTS pg_trgm"
  end
end

