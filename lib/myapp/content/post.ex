defmodule Myapp.Content.Post do
  @moduledoc """
  Schema for posts, which can include text content and file attachments.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :content, :string
    field :file_paths, {:array, :string}, default: []
    field :status, :string, default: "draft"
    field :published_at, :utc_datetime
    field :metadata, :map, default: %{}

    # Virtual fields for upload handling
    field :files, {:array, :map}, virtual: true

    belongs_to :user, Myapp.Accounts.User
    has_many :platform_uploads, Myapp.Content.PlatformUpload, foreign_key: :content_id

    timestamps()
  end

  @doc """
  Changeset for posts.
  """
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :content, :file_paths, :status, :published_at, :metadata, :user_id])
    |> validate_required([:title, :content, :user_id])
    |> validate_length(:title, min: 1, max: 255)
    |> validate_length(:content, min: 1, max: 50_000)
    |> validate_inclusion(:status, ~w(draft published archived))
    |> validate_files()
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Publishing changeset for posts.
  """
  def publish_changeset(post) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    post
    |> change(%{
      status: "published",
      published_at: now
    })
  end

  @doc """
  Archives a post.
  """
  def archive_changeset(post) do
    post
    |> change(%{status: "archived"})
  end

  # Private Functions

  defp validate_files(changeset) do
    if files = get_change(changeset, :files) do
      validate_file_types(changeset, files)
    else
      changeset
    end
  end

  defp validate_file_types(changeset, files) do
    files
    |> Enum.all?(fn file ->
      case file.content_type do
        "image/" <> _ -> true
        "application/pdf" -> true
        "application/msword" -> true
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" -> true
        _ -> false
      end
    end)
    |> case do
      true -> changeset
      false -> add_error(changeset, :files, "contains invalid file types")
    end
  end

  @doc """
  Creates a migration for the posts table.
  """
  def create_migration do
    """
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

        create index(:posts, [:user_id])
        create index(:posts, [:status])
        create index(:posts, [:published_at])
      end
    end
    """
  end
end

