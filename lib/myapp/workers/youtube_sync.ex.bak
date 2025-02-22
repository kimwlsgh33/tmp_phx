defmodule Myapp.Workers.YoutubeSync do
  use Oban.Worker

  @impl Oban.Worker
  def perform(_job) do
    Myapp.YoutubeChannel.sync_all_videos()
  end
end
