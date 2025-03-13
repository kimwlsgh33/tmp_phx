defmodule Myapp.Content do
  @moduledoc """
  The Content context handles creation and management of all content types:
  posts, short videos, and long videos.
  """

  import Ecto.Query
  alias Myapp.Repo
  alias Myapp.Content.{Post, ShortVideo, LongVideo, PlatformUpload}

  # Post Functions

  @doc """
  Creates a new post with the given attributes.
  """
  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a post with the given attributes.
  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets a post by ID.
  """
  def get_post!(id), do: Repo.get!(Post, id)

  @doc """
  Lists all posts for a user.
  """
  def list_user_posts(user_id) do
    Post
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  # Short Video Functions

  @doc """
  Creates a new short video with the given attributes.
  """
  def create_short_video(attrs \\ %{}) do
    %ShortVideo{}
    |> ShortVideo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a short video with the given attributes.
  """
  def update_short_video(%ShortVideo{} = video, attrs) do
    video
    |> ShortVideo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets a short video by ID.
  """
  def get_short_video!(id), do: Repo.get!(ShortVideo, id)

  @doc """
  Lists all short videos for a user.
  """
  def list_user_short_videos(user_id) do
    ShortVideo
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  # Long Video Functions

  @doc """
  Creates a new long video with the given attributes.
  """
  def create_long_video(attrs \\ %{}) do
    %LongVideo{}
    |> LongVideo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a long video with the given attributes.
  """
  def update_long_video(%LongVideo{} = video, attrs) do
    video
    |> LongVideo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets a long video by ID.
  """
  def get_long_video!(id), do: Repo.get!(LongVideo, id)

  @doc """
  Lists all long videos for a user.
  """
  def list_user_long_videos(user_id) do
    LongVideo
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  # Common Functions

  @doc """
  Returns the list of all content for a user, sorted by creation date.
  """
  def list_user_content(user_id) do
    posts = list_user_posts(user_id)
    short_videos = list_user_short_videos(user_id)
    long_videos = list_user_long_videos(user_id)

    posts ++ short_videos ++ long_videos
    |> Enum.sort_by(&(&1.inserted_at), {:desc, DateTime})
  end

  @doc """
  Deletes a content item of any type.
  """
  def delete_content(%_{} = content) do
    Repo.delete(content)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking content changes.
  """
  def change_content(%_{} = content, attrs \\ %{}) do
    case content do
      %Post{} -> Post.changeset(content, attrs)
      %ShortVideo{} -> ShortVideo.changeset(content, attrs)
      %LongVideo{} -> LongVideo.changeset(content, attrs)
    end
  end

  @doc """
  Gets platform upload status for a content item.
  """
  def get_platform_status(content_id, platform) do
    PlatformUpload
    |> where(content_id: ^content_id, platform: ^platform)
    |> Repo.one()
  end

  @doc """
  Updates platform upload status for a content item.
  """
  def update_platform_status(content_id, platform, status, platform_content_id \\ nil) do
    %PlatformUpload{}
    |> PlatformUpload.changeset(%{
      content_id: content_id,
      platform: platform,
      status: status,
      platform_content_id: platform_content_id
    })
    |> Repo.insert_or_update()
  end
end

