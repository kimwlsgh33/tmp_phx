defmodule Myapp.Youtube do
  @moduledoc """
  Mock implementation of YouTube API for testing purposes.
  Returns static data without making actual API calls.
  """

  @doc """
  Mock search for YouTube videos.
  Returns sample data based on the query.
  """
  def search_videos(query, _opts \\ []) do
    videos = [
      %{
        id: "dQw4w9WgXcQ",
        title: "Rick Astley - Never Gonna Give You Up (Official Music Video)",
        description: "The official music video for \"Never Gonna Give You Up\"",
        thumbnail: "https://img.youtube.com/vi/dQw4w9WgXcQ/default.jpg",
        published_at: "2009-10-25T06:57:33Z",
        channel_title: "Rick Astley"
      },
      %{
        id: "jNQXAC9IVRw",
        title: "Me at the zoo",
        description: "The first video on YouTube",
        thumbnail: "https://img.youtube.com/vi/jNQXAC9IVRw/default.jpg",
        published_at: "2005-04-23T14:31:52Z",
        channel_title: "jawed"
      },
      %{
        id: "9bZkp7q19f0",
        title: "PSY - GANGNAM STYLE(강남스타일) M/V",
        description: "PSY's global hit song",
        thumbnail: "https://img.youtube.com/vi/9bZkp7q19f0/default.jpg",
        published_at: "2012-07-15T07:46:32Z",
        channel_title: "officialpsy"
      }
    ]

    filtered_videos = Enum.filter(videos, fn video ->
      String.contains?(String.downcase(video.title), String.downcase(query)) ||
      String.contains?(String.downcase(video.description), String.downcase(query))
    end)

    {:ok, filtered_videos}
  end

  @doc """
  Mock get video details.
  Returns sample data for the given video ID.
  """
  def get_video_details(video_id) do
    case video_id do
      "dQw4w9WgXcQ" ->
        {:ok,
         %{
           title: "Rick Astley - Never Gonna Give You Up (Official Music Video)",
           description: "The official music video for \"Never Gonna Give You Up\"",
           duration: 213,
           view_count: 1_325_640_772,
           like_count: 15_800_000,
           comment_count: 1_580_000,
           published_at: "2009-10-25T06:57:33Z",
           channel_title: "Rick Astley",
           tags: ["Rick Astley", "Never Gonna Give You Up", "Music Video"]
         }}

      "jNQXAC9IVRw" ->
        {:ok,
         %{
           title: "Me at the zoo",
           description: "The first video on YouTube",
           duration: 18,
           view_count: 258_000_000,
           like_count: 12_000_000,
           comment_count: 1_200_000,
           published_at: "2005-04-23T14:31:52Z",
           channel_title: "jawed",
           tags: ["first", "youtube", "zoo"]
         }}

      "9bZkp7q19f0" ->
        {:ok,
         %{
           title: "PSY - GANGNAM STYLE(강남스타일) M/V",
           description: "PSY's global hit song",
           duration: 253,
           view_count: 4_800_000_000,
           like_count: 25_000_000,
           comment_count: 6_000_000,
           published_at: "2012-07-15T07:46:32Z",
           channel_title: "officialpsy",
           tags: ["PSY", "Gangnam Style", "K-Pop"]
         }}

      _ ->
        {:error, "Video not found"}
    end
  end
end
