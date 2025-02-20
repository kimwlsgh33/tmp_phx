defmodule Myapp.Youtube do
  @moduledoc """
  The Myapp.Youtube context.
  """
  alias GoogleApi.YouTube.V3.Connection
  alias GoogleApi.YouTube.V3.Api.Videos

  def get_videos_details(video_id) do
    {:ok, conn} = Connection.new()

    Videos.youtube_videos_list(conn, part: "snippet, contentDetails, statistics", id: video_id)
    |> handle_response()
  end

  defp handle_response({:ok, %{items: [video | _]}}) do
    {:ok,
     %{
       title: video.snippet.title,
       duration: parse_duration(video.contentDetails.duration),
       view_count: video.statistics.viewCount
     }}
  end

  defp parse_duration(iso8601) do
    Duration.from_iso8601!(iso8601)
    |> Duration.to_seconds()
  end
end
