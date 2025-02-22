defmodule MyappWeb.YoutubeChannel do
  use Phoenix.Channel

  def join("youtube:" <> video_id, _params, socket) do
    send(self(), :refresh_stats)
    {:ok, socket}
  end

  def handle_info(:refresh_stats, socket) do
    {:ok, stats} = Youtube.get_video_details(socket.assigns.video_id)

    push(socket, "stats_update", stats)
    Process.send_after(self(), :refresh_stats, 30_000)

    {:noreply, socket}
  end
end
