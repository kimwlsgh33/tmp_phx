defmodule Myapp.Content do
  @moduledoc """
  The Content context handles creation and management of all content types:
  posts, short videos, and long videos.
  """

  import Ecto.Query
  alias Myapp.Repo
  alias Myapp.Content.{Post, ShortVideo, LongVideo, PlatformUpload}
  alias Myapp.ErrorHandler

  # Helper functions for error handling

  # Handles the result of a Repo operation, standardizing error handling.
  defp handle_repo_result({:ok, _result} = success, _message, _details), do: success

  defp handle_repo_result({:error, %Ecto.Changeset{} = changeset}, message, details) do
    ErrorHandler.handle(
      ErrorHandler.error(
        :validation_error,
        message,
        Map.merge(details, %{changeset: changeset}),
        __MODULE__
      ),
      __MODULE__
    )
  end

  defp handle_repo_result({:error, reason}, message, details) do
    ErrorHandler.handle(
      ErrorHandler.error(
        :database_error,
        message,
        Map.merge(details, %{reason: reason}),
        __MODULE__
      ),
      __MODULE__
    )
  end

  # Post Functions

  @doc """
  Creates a new post with the given attributes.
  """
  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
    |> handle_repo_result("Failed to create post", %{attrs: attrs})
  end

  @doc """
  Updates a post with the given attributes.
  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
    |> handle_repo_result("Failed to update post", %{post_id: post.id, attrs: attrs})
  end

  @doc """
  Gets a post by ID.
  """
  def get_post!(id) do
    try do
      Repo.get!(Post, id)
    rescue
      e in Ecto.NoResultsError ->
        # Log the error with our error handler
        ErrorHandler.handle(
          ErrorHandler.error(
            :not_found,
            "Post not found",
            %{post_id: id},
            __MODULE__
          ),
          __MODULE__
        )
        # Re-raise the original exception
        reraise e, __STACKTRACE__
    end
  end

  @doc """
  Gets a post by ID, returning {:ok, post} or {:error, reason}.
  """
  def get_post(id) do
    case Repo.get(Post, id) do
      %Post{} = post -> {:ok, post}
      nil ->
        ErrorHandler.handle(
          ErrorHandler.error(
            :not_found,
            "Post not found",
            %{post_id: id},
            __MODULE__
          ),
          __MODULE__
        )
    end
  end

  @doc """
  Lists all posts for a user.
  """
  def list_user_posts(user_id) do
    try do
      posts = Post
      |> where(user_id: ^user_id)
      |> order_by(desc: :inserted_at)
      |> Repo.all()

      {:ok, posts}
    rescue
      e in [Ecto.QueryError] ->
        ErrorHandler.handle(
          ErrorHandler.error(
            :database_error,
            "Error querying posts",
            %{user_id: user_id, error: e},
            __MODULE__
          ),
          __MODULE__
        )
    end
  end

  # Short Video Functions

  @doc """
  Creates a new short video with the given attributes.
  """
  def create_short_video(attrs \\ %{}) do
    %ShortVideo{}
    |> ShortVideo.changeset(attrs)
    |> Repo.insert()
    |> handle_repo_result("Failed to create short video", %{attrs: attrs})
  end

  @doc """
  Updates a short video with the given attributes.
  """
  def update_short_video(%ShortVideo{} = video, attrs) do
    video
    |> ShortVideo.changeset(attrs)
    |> Repo.update()
    |> handle_repo_result("Failed to update short video", %{video_id: video.id, attrs: attrs})
  end

  @doc """
  Gets a short video by ID.
  """
  def get_short_video!(id) do
    try do
      Repo.get!(ShortVideo, id)
    rescue
      e in Ecto.NoResultsError ->
        # Log the error with our error handler
        ErrorHandler.handle(
          ErrorHandler.error(
            :not_found,
            "Short video not found",
            %{video_id: id},
            __MODULE__
          ),
          __MODULE__
        )
        # Re-raise the original exception
        reraise e, __STACKTRACE__
    end
  end

  @doc """
  Gets a short video by ID, returning {:ok, video} or {:error, reason}.
  """
  def get_short_video(id) do
    case Repo.get(ShortVideo, id) do
      %ShortVideo{} = video -> {:ok, video}
      nil ->
        ErrorHandler.handle(
          ErrorHandler.error(
            :not_found,
            "Short video not found",
            %{video_id: id},
            __MODULE__
          ),
          __MODULE__
        )
    end
  end

  @doc """
  Lists all short videos for a user.
  """
  def list_user_short_videos(user_id) do
    try do
      videos = ShortVideo
      |> where(user_id: ^user_id)
      |> order_by(desc: :inserted_at)
      |> Repo.all()

      {:ok, videos}
    rescue
      e in [Ecto.QueryError] ->
        ErrorHandler.handle(
          ErrorHandler.error(
            :database_error,
            "Error querying short videos",
            %{user_id: user_id, error: e},
            __MODULE__
          ),
          __MODULE__
        )
    end
  end

  # Long Video Functions

  @doc """
  Creates a new long video with the given attributes.
  """
  def create_long_video(attrs \\ %{}) do
    %LongVideo{}
    |> LongVideo.changeset(attrs)
    |> Repo.insert()
    |> handle_repo_result("Failed to create long video", %{attrs: attrs})
  end

  @doc """
  Updates a long video with the given attributes.
  """
  def update_long_video(%LongVideo{} = video, attrs) do
    video
    |> LongVideo.changeset(attrs)
    |> Repo.update()
    |> handle_repo_result("Failed to update long video", %{video_id: video.id, attrs: attrs})
  end

  @doc """
  Gets a long video by ID.
  """
  def get_long_video!(id) do
    try do
      Repo.get!(LongVideo, id)
    rescue
      e in Ecto.NoResultsError ->
        # Log the error with our error handler
        ErrorHandler.handle(
          ErrorHandler.error(
            :not_found,
            "Long video not found",
            %{video_id: id},
            __MODULE__
          ),
          __MODULE__
        )
        # Re-raise the original exception
        reraise e, __STACKTRACE__
    end
  end

  @doc """
  Gets a long video by ID, returning {:ok, video} or {:error, reason}.
  """
  def get_long_video(id) do
    case Repo.get(LongVideo, id) do
      %LongVideo{} = video -> {:ok, video}
      nil ->
        ErrorHandler.handle(
          ErrorHandler.error(
            :not_found,
            "Long video not found",
            %{video_id: id},
            __MODULE__
          ),
          __MODULE__
        )
    end
  end

  @doc """
  Lists all long videos for a user.
  """
  def list_user_long_videos(user_id) do
    try do
      videos = LongVideo
      |> where(user_id: ^user_id)
      |> order_by(desc: :inserted_at)
      |> Repo.all()

      {:ok, videos}
    rescue
      e in [Ecto.QueryError] ->
        ErrorHandler.handle(
          ErrorHandler.error(
            :database_error,
            "Error querying long videos",
            %{user_id: user_id, error: e},
            __MODULE__
          ),
          __MODULE__
        )
    end
  end

  # Common Functions

  @doc """
  Returns the list of all content for a user, sorted by creation date.
  """
  def list_user_content(user_id) do
    try do
      with {:ok, posts} <- list_user_posts(user_id),
           {:ok, short_videos} <- list_user_short_videos(user_id),
           {:ok, long_videos} <- list_user_long_videos(user_id) do
        content = posts ++ short_videos ++ long_videos
                  |> Enum.sort_by(&(&1.inserted_at), {:desc, DateTime})
        {:ok, content}
      else
        {:error, _} = error -> error
      end
    rescue
      e ->
        ErrorHandler.handle(
          ErrorHandler.error(
            :internal_error,
            "Error retrieving user content",
            %{user_id: user_id, error: e},
            __MODULE__
          ),
          __MODULE__
        )
    end
  end

  @doc """
  Deletes a content item of any type.
  """
  def delete_content(%_{} = content) do
    content_type = content.__struct__ |> Module.split() |> List.last()
    content_id = content.id

    Repo.delete(content)
    |> handle_repo_result(
      "Failed to delete #{content_type}",
      %{content_type: content_type, content_id: content_id}
    )
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
    try do
      status = PlatformUpload
      |> where(content_id: ^content_id, platform: ^platform)
      |> Repo.one()

      {:ok, status}
    rescue
      e in [Ecto.QueryError] ->
        ErrorHandler.handle(
          ErrorHandler.error(
            :database_error,
            "Error querying platform status",
            %{content_id: content_id, platform: platform, error: e},
            __MODULE__
          ),
          __MODULE__
        )
    end
  end

  @doc """
  Updates platform upload status for a content item.
  """
  def update_platform_status(content_id, platform, status, platform_content_id \\ nil) do
    attrs = %{
      content_id: content_id,
      platform: platform,
      status: status,
      platform_content_id: platform_content_id
    }

    %PlatformUpload{}
    |> PlatformUpload.changeset(attrs)
    |> Repo.insert_or_update()
    |> handle_repo_result(
      "Failed to update platform status",
      %{content_id: content_id, platform: platform, status: status}
    )
  end
end
