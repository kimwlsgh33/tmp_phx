defmodule MyappWeb.Helpers.YoutubeHelper do
  @moduledoc """
  Helper functions for working with YouTube data in templates.
  """

  @doc """
  Returns the embed URL for a YouTube video.
  """
  def embed_url(video_id) do
    "https://www.youtube.com/embed/#{video_id}"
  end

  @doc """
  Returns the URL for a video's thumbnail.
  Available quality options: :default, :medium, :high, :standard, :maxres
  """
  def thumbnail_url(video_id, quality \\ :medium) do
    case quality do
      :default -> "https://img.youtube.com/vi/#{video_id}/default.jpg"
      :medium -> "https://img.youtube.com/vi/#{video_id}/mqdefault.jpg"
      :high -> "https://img.youtube.com/vi/#{video_id}/hqdefault.jpg"
      :standard -> "https://img.youtube.com/vi/#{video_id}/sddefault.jpg"
      :maxres -> "https://img.youtube.com/vi/#{video_id}/maxresdefault.jpg"
    end
  end

  @doc """
  Formats a duration in seconds to a human-readable string.
  Example: 125 -> "2:05"
  """
  def format_duration(seconds) when is_integer(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    remaining_seconds = rem(seconds, 60)

    cond do
      hours > 0 ->
        :io_lib.format("~2..0B:~2..0B:~2..0B", [hours, minutes, remaining_seconds])

      true ->
        :io_lib.format("~B:~2..0B", [minutes, remaining_seconds])
    end
    |> to_string()
  end

  def format_duration(_), do: "0:00"

  @doc """
  Formats a view count to a human-readable string.
  Examples: 1234 -> "1.2K", 12345 -> "12.3K", 123456 -> "123.4K", 1234567 -> "1.2M"
  """
  def format_view_count(count) when is_integer(count) do
    cond do
      count >= 1_000_000 ->
        "#{Float.round(count / 1_000_000, 1)}M"

      count >= 1_000 ->
        "#{Float.round(count / 1_000, 1)}K"

      true ->
        to_string(count)
    end
  end

  def format_view_count(_), do: "0"

  @doc """
  Formats a published date to a human-readable string.
  Example: "2024-02-22T12:00:00Z" -> "Feb 22, 2024"
  """
  def format_published_date(datetime) when is_binary(datetime) do
    case DateTime.from_iso8601(datetime) do
      {:ok, dt, _offset} ->
        Calendar.strftime(dt, "%b %d, %Y")

      _ ->
        datetime
    end
  end

  def format_published_date(_), do: ""

  @doc """
  Returns a direct link to a YouTube video.
  """
  def video_url(video_id) do
    "https://www.youtube.com/watch?v=#{video_id}"
  end
end
