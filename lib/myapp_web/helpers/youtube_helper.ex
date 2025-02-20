defmodule MyappWeb.Helpers.YoutubeHelper do
  def embed_url(video_id) do
    "https://www.youtube.com/embed/#{video_id}"
  end
end
