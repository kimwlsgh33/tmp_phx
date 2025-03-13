defmodule Myapp.Content.ShortVideo do
  @moduledoc """
  Schema for short-form videos (up to 60 seconds) suitable for platforms like
  TikTok and Instagram Reels.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @max_duration 60  # Maximum duration in seconds

  schema "short_videos" do
    field :title, :string
    field :description, :string
    field :video_path, :string
    field :thumbnail_path, :string
    field :duration, :integer  # Duration in seconds
    field :status, :string, default: "draft"
    field :published_at, :utc_datetime
    field :metadata, :map, default: %{}

    # Video dimensions
    field :width, :integer
    field :height, :integer

    # Virtual fields for upload handling
    field :video_file, :map, virtual: true
    field :thumbnail_file, :map, virtual: true

    belongs_to :user, Myapp.Accounts.User
    has_many :platform_uploads, Myapp.Content.PlatformUpload, foreign_key: :content_id

    timestamps()
  end

  @doc """
  Changeset for short videos.
  """
  def changeset(video, attrs) do
    video
    |> cast(attrs, [
      :title,
      :description,
      :video_path,
      :thumbnail_path,
      :duration,
      :status,
      :published_at,
      :metadata,
      :width,
      :height,
      :user_id
    ])
    |> validate_required([:title, :description, :user_id])
    |> validate_length(:title, min: 1, max: 255)
    |> validate_length(:description, min: 1, max: 5000)
    |> validate_inclusion(:status, ~w(draft processing published archived failed))
    |> validate_number(:duration, less_than_or_equal_to: @max_duration)
    |> validate_dimension(:width)
    |> validate_dimension(:height)
    |> validate_video()
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Processing changeset for when video upload starts.
  """
  def processing_changeset(video) do
    change(video, %{status: "processing"})
  end

  @doc """
  Publishing changeset for videos.
  """
  def publish_changeset(video) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    video
    |> change(%{
      status: "published",
      published_at: now
    })
  end

  @doc """
  Archives a video.
  """
  def archive_changeset(video) do
    change(video, %{status: "archived"})
  end

  @doc """
  Marks a video as failed during processing.
  """
  def failed_changeset(video, reason) do
    video
    |> change(%{
      status: "failed",
      metadata: Map.put(video.metadata, "failure_reason", reason)
    })
  end

  # Private Functions

  defp validate_dimension(changeset, field) do
    case get_field(changeset, field) do
      nil -> changeset
      dim when is_integer(dim) and dim > 0 -> changeset
      _ -> add_error(changeset, field, "must be a positive integer")
    end
  end

  defp validate_video(changeset) do
    if video_file = get_change(changeset, :video_file) do
      validate_video_type(changeset, video_file)
    else
      changeset
    end
  end

  defp validate_video_type(changeset, video_file) do
    case video_file.content_type do
      "video/mp4" -> changeset
      "video/quicktime" -> changeset  # For .mov files
      _ -> add_error(changeset, :video_file, "must be MP4 or MOV format")
    end
  end

  @doc """
  Creates a migration for the short_videos table.
  """
  def create_migration do
    """
    defmodule Myapp.Repo.Migrations.CreateShortVideos do
      use Ecto.Migration

      def change do
        create table(:short_videos) do
          add :title, :string, null: false
          add :description, :text, null: false
          add :video_path, :string
          add :thumbnail_path, :string
          add :duration, :integer
          add :status, :string, default: "draft"
          add :published_at, :utc_datetime
          add :metadata, :map, default: %{}
          add :width, :integer
          add :height, :integer
          add :user_id, references(:users, on_delete: :delete_all), null: false

          timestamps()
        end

        create index(:short_videos, [:user_id])
        create index(:short_videos, [:status])
        create index(:short_videos, [:published_at])
      end
    end
    """
  end
end

