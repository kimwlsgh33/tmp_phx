defmodule MyappWeb.YoutubeChannel do
  use Phoenix.Channel
  alias Myapp.Youtube

  def join("youtube:" <> video_id, _params, socket) do
    socket = assign(socket, :video_id, video_id)
    send(self(), :refresh_stats)
    {:ok, socket}
  end

  def handle_info(:refresh_stats, socket) do
    case Youtube.get_video_details(socket.assigns.video_id) do
      {:ok, stats} ->
        push(socket, "stats_update", stats)
        Process.send_after(self(), :refresh_stats, 30_000)
        {:noreply, socket}
      {:error, reason} ->
        push(socket, "error", %{reason: reason})
        {:noreply, socket}
    end
  end

  def handle_in("search_videos", %{"query" => query} = params, socket) do
    opts = [
      max_results: Map.get(params, "max_results", 25),
      order: Map.get(params, "order", "relevance")
    ]

    case Youtube.search_videos(query, opts) do
      {:ok, videos} -> {:reply, {:ok, %{videos: videos}}, socket}
      {:error, reason} -> {:reply, {:error, %{reason: reason}}, socket}
    end
  end
end
