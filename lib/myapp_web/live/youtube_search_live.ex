defmodule MyappWeb.YoutubeSearchLive do
  use MyappWeb, :live_view
  alias Myapp.Youtube

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:api_key, "")
      |> assign(:query, "")
      |> assign(:videos, [])
      |> assign(:video_details, nil)
      |> assign(:loading, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"api_key" => api_key, "query" => query}, socket) do
    socket =
      case {api_key, query} do
        {"", ""} ->
          socket
          |> put_flash(:error, "Input Required")
          |> put_flash(:error_detail, "Please enter both API key and query.")

        {"", _} ->
          socket
          |> put_flash(:error, "API Key Required")
          |> put_flash(:error_detail, "Please enter your YouTube API key.")

        {_, ""} ->
          socket
          |> put_flash(:error, "Query Required")
          |> put_flash(:error_detail, "Please enter a search query.")

        {api_key, query} ->
          Task.async(fn -> Youtube.search_videos(query, api_key: api_key) end)

          socket
          |> assign(:api_key, api_key)
          |> assign(:query, query)
          |> assign(:videos, [])
          |> assign(:loading, true)
          |> clear_flash()
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_api_key", _params, socket) do
    {:noreply, assign(socket, :api_key, "")}
  end

  @impl true
  def handle_info({ref, result}, socket) when is_reference(ref) do
    case result do
      {:ok, videos} when is_list(videos) ->
        socket =
          socket
          |> assign(:videos, videos)
          |> assign(:video_details, get_first_video_details(videos, socket.assigns.api_key))
          |> assign(:loading, false)
          |> clear_flash()

        {:noreply, socket}

      {:error, message} ->
        socket =
          socket
          |> assign(:loading, false)
          |> put_flash(:error, "YouTube API Error")
          |> put_flash(:error_detail, message)

        {:noreply, socket}

      unexpected ->
        IO.inspect(unexpected, label: "Unexpected Result")
        {:noreply, assign(socket, :loading, false)}
    end
  end

  # 태스크 종료 메시지 처리
  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    # 태스크가 끝났으니 추가 작업 없음
    {:noreply, socket}
  end

  # 디버깅용 캐치올 조항
  @impl true
  def handle_info(msg, socket) do
    IO.inspect(msg, label: "Unhandled Message in handle_info")
    {:noreply, socket}
  end

  defp get_first_video_details([], _api_key), do: nil

  defp get_first_video_details([%{id: video_id} | _], api_key) do
    case Youtube.get_video_details(video_id, api_key: api_key) do
      {:ok, details} -> details
      {:error, _message} -> nil
    end
  end
end

