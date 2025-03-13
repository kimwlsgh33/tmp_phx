defmodule Myapp.Content.LongVideo do
  @moduledoc """
  Schema for long-form videos suitable for platforms like YouTube and Vimeo.
  Includes enhanced metadata and categorization.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @categories ~w(education entertainment gaming music tech other)

  schema "long_videos" do
    field :title, :string
    field :description, :string
    field :video_path, :string
    field :thumbnail_path, :string
    field :duration, :integer  # Duration in seconds
    field :status, :string, default: "draft"
    field :published_at, :utc_datetime
    field :category, :string
    field :tags, {:array, :string}, default: []
    field :visibility, :string, default: "private"
    field :metadata, :map, default: %{}

    # Video dimensions and quality
    field :width, :integer
    field :height, :integer
    field :quality, :string  # HD, 4K, etc.
    field :fps, :integer  # Frames per second

    # SEO and discoverability
    field :seo_title, :string
    field :seo_description, :string
    field :allow_comments, :boolean, default: true
    field :age_restricted, :boolean, default: false

    # Virtual fields for upload handling
    field :video_file, :map, virtual: true
    field :thumbnail_file, :map, virtual: true

    belongs_to :user, Myapp.Accounts.User
    has_many :platform_uploads, Myapp.Content.PlatformUpload, foreign_key: :content_id

    timestamps()
  end

  @doc """
  Changeset for long videos.
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
      :category,
      :tags,
      :visibility,
      :metadata,
      :width,
      :height,
      :quality,
      :fps,
      :seo_title,
      :seo_description,
      :allow_comments,
      :age_restricted,
      :user_id
    ])
    |> validate_required([:title, :description, :category, :user_id])
    |> validate_length(:title, min: 1, max: 255)
    |> validate_length(:description, min: 1, max: 5000)
    |> validate_inclusion(:status, ~w(draft processing published archived failed))
    |> validate_inclusion(:category, @categories)
    |> validate_inclusion(:visibility, ~w(private unlisted public))
    |> validate_inclusion(:quality, ~w(SD HD FHD 2K 4K 8K))
    |> validate_tags()
    |> validate_dimension(:width)
    |> validate_dimension(:height)
    |> validate_fps()
    |> validate_video()
    |> validate_seo_fields()
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

  defp validate_fps(changeset) do
    case get_field(changeset, :fps) do
      nil -> changeset
      fps when is_integer(fps) and fps > 0 and fps <= 240 -> changeset
      _ -> add_error(changeset, :fps, "must be between 1 and 240")
    end
  end

  defp validate_tags(changeset) do
    case get_field(changeset, :tags) do
      nil -> changeset
      tags when is_list(tags) ->
        if Enum.all?(tags, &(is_binary(&1) and String.length(&1) <= 50)) do
          changeset
        else
          add_error(changeset, :tags, "each tag must be a string of max 50 characters")
        end
      _ -> add_error(changeset, :tags, "must be a list of strings")
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

  defp validate_seo_fields(changeset) do
    seo_title = get_field(changeset, :seo_title)
    seo_desc = get_field(changeset, :seo_description)

    changeset
    |> validate_seo_title(seo_title)
    |> validate_seo_description(seo_desc)
  end

  defp validate_seo_title(changeset, nil), do: changeset
  defp validate_seo_title(changeset, title) do
    if String.length(title) in 1..100 do
      changeset
    else
      add_error(changeset, :seo_title, "must be between 1 and 100 characters")
    end
  end

  defp validate_seo_description(changeset, nil), do: changeset
  defp validate_seo_description(changeset, description) do
    if String.length(description) in 1..5000 do
      changeset
    else
      add_error(changeset, :seo_description, "must be between 1 and 5000 characters")
    end
  end

  @doc """
  Creates a migration for the long_videos table.
  """
  def create_migration do
    """
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
          add :width, :integer
          add :height, :integer
          add :quality, :string
          add :fps, :integer
          add :seo_title, :string
          add :seo_description, :text
          add :allow_comments, :boolean, default: true
          add :age_restricted, :boolean, default: false
          add :user_id, references(:users, on_delete: :delete_all), null: false

          timestamps()
        end

        create index(:long_videos, [:user_id])
        create index(:long_videos, [:status])
        create index(:long_videos, [:published_at])
        create index(:long_videos, [:category])
        create index(:long_videos, [:visibility])
        create index(:long_videos, [:tags], using: "gin")
      end
    end
    """
  end
end

