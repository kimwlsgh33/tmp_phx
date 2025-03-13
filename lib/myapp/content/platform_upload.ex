defmodule Myapp.Content.PlatformUpload do
  @moduledoc """
  Schema for tracking uploads of content to different social media platforms.
  Maintains status, platform-specific IDs, and metadata for each upload.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @platforms ~w(twitter facebook instagram tiktok youtube vimeo)
  @statuses ~w(pending processing completed failed)

  schema "platform_uploads" do
    field :platform, :string
    field :status, :string, default: "pending"
    field :platform_content_id, :string
    field :content_type, :string  # "Post", "ShortVideo", "LongVideo"
    field :content_id, :integer
    field :error_message, :string
    field :metadata, :map, default: %{}
    field :uploaded_at, :utc_datetime
    field :last_sync_at, :utc_datetime

    timestamps()
  end

  @doc """
  Changeset for platform uploads.
  """
  def changeset(platform_upload, attrs) do
    platform_upload
    |> cast(attrs, [
      :platform,
      :status,
      :platform_content_id,
      :content_type,
      :content_id,
      :error_message,
      :metadata,
      :uploaded_at,
      :last_sync_at
    ])
    |> validate_required([:platform, :status, :content_type, :content_id])
    |> validate_inclusion(:platform, @platforms)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:content_type, ~w(Post ShortVideo LongVideo))
    |> unique_constraint([:platform, :content_type, :content_id],
      name: :platform_uploads_platform_content_index
    )
  end

  @doc """
  Changeset for updating upload status.
  """
  def status_changeset(platform_upload, status, error_message \\ nil) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    attrs = %{
      status: status,
      error_message: error_message,
      uploaded_at: (if status == "completed", do: now, else: platform_upload.uploaded_at),
      last_sync_at: now
    }

    platform_upload
    |> cast(attrs, [:status, :error_message, :uploaded_at, :last_sync_at])
    |> validate_inclusion(:status, @statuses)
  end

  @doc """
  Changeset for updating platform content ID.
  """
  def platform_id_changeset(platform_upload, platform_content_id, metadata \\ %{}) do
    platform_upload
    |> cast(%{
      platform_content_id: platform_content_id,
      metadata: Map.merge(platform_upload.metadata, metadata)
    }, [:platform_content_id, :metadata])
    |> validate_required(:platform_content_id)
  end

  @doc """
  Marks an upload as completed with its platform-specific ID.
  """
  def complete_changeset(platform_upload, platform_content_id, metadata \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    platform_upload
    |> cast(%{
      status: "completed",
      platform_content_id: platform_content_id,
      metadata: Map.merge(platform_upload.metadata, metadata),
      uploaded_at: now,
      last_sync_at: now,
      error_message: nil
    }, [:status, :platform_content_id, :metadata, :uploaded_at, :last_sync_at, :error_message])
    |> validate_required(:platform_content_id)
  end

  @doc """
  Marks an upload as failed with an error message.
  """
  def fail_changeset(platform_upload, error_message, metadata \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    platform_upload
    |> cast(%{
      status: "failed",
      error_message: error_message,
      metadata: Map.merge(platform_upload.metadata, metadata),
      last_sync_at: now
    }, [:status, :error_message, :metadata, :last_sync_at])
    |> validate_required(:error_message)
  end

  @doc """
  Creates a migration for the platform_uploads table.
  """
  def create_migration do
    """
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
      end
    end
    """
  end
end

