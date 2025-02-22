defmodule MyappWeb.TestHTML do
  use MyappWeb, :html

  embed_templates "test_html/*"
end

defmodule MyappWeb.TestController do
  use MyappWeb, :controller
  alias Myapp.Youtube

  def page(conn, _params) do
    # Get details for a sample video
    {:ok, video_details} = Youtube.get_video_details("dQw4w9WgXcQ")

    # Initial search for some videos
    {:ok, videos} = Youtube.search_videos("music")

    render(conn, :test, videos: videos, video_details: video_details)
  end

  def search(conn, %{"query" => query}) do
    {:ok, videos} = Youtube.search_videos(query)
    json(conn, %{videos: videos})
  end
end
