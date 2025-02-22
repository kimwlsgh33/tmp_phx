defmodule MyappWeb.TestController do
  use MyappWeb, :controller

  def page(conn, params) do
    api_key = Map.get(params, "api_key", "")
    query = Map.get(params, "query", "")

    if byte_size(query) > 0 do
      # Only try to search if there's a query
      if byte_size(api_key) > 0 do
        case Myapp.Youtube.search_videos(query, api_key: api_key) do
          {:ok, %{videos: videos}} ->
            video_details = get_first_video_details(videos, api_key)
            render(conn, :test, videos: videos, video_details: video_details, api_key: api_key)

          {:error, message} ->
            conn
            |> put_flash(:error, "Search failed: #{message}")
            |> render(:test, videos: [], video_details: nil, api_key: api_key)
        end
      else
        conn
        |> put_flash(:error, "Please provide a valid YouTube API key")
        |> render(:test, videos: [], video_details: nil, api_key: api_key)
      end
    else
      # Initial page load or empty query
      render(conn, :test, videos: [], video_details: nil, api_key: api_key)
    end
  end

  defp get_first_video_details([], _api_key), do: nil
  defp get_first_video_details([%{id: video_id} | _], api_key) do
    case Myapp.Youtube.get_video_details(video_id, api_key: api_key) do
      {:ok, details} -> details
      {:error, _message} -> nil
    end
  end
end
