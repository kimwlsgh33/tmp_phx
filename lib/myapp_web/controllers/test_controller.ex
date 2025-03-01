defmodule MyappWeb.TestController do
  use MyappWeb, :controller
  alias Myapp.Youtube

  def page(conn, params) do
    api_key = Map.get(params, "api_key", "")
    query = Map.get(params, "query", "")

    cond do
      api_key == "" and query == "" ->
        # Initial page load
        render(conn, :test, flash: %{}, videos: [], video_details: nil, api_key: "")

      api_key == "" ->
        # Missing API key
        render(conn, :test,
          flash: %{
            error: "API Key Required",
            error_detail: "Please enter your YouTube API key to search videos."
          },
          videos: [],
          video_details: nil,
          api_key: ""
        )

      query == "" ->
        # Missing search query
        render(conn, :test,
          flash: %{
            error: "Search Query Required",
            error_detail: "Please enter what you'd like to search for."
          },
          videos: [],
          video_details: nil,
          api_key: api_key
        )

      true ->
        # Both API key and query are present
        case Youtube.search_videos(query, api_key: api_key) do
          {:ok, %{videos: videos}} ->
            video_details = get_first_video_details(videos, api_key)

            render(conn, :test,
              flash: %{},
              videos: videos,
              video_details: video_details,
              api_key: api_key
            )

          {:error, message} ->
            render(conn, :test,
              flash: %{
                error: "YouTube API Error",
                error_detail: message
              },
              videos: [],
              video_details: nil,
              api_key: api_key
            )
        end
    end
  end

  def search(conn, params) do
    # Handle search form submission
    redirect(conn, to: ~p"/test?#{%{api_key: params["api_key"], query: params["query"]}}")
    # redirect 말고 post로 데이터만 받아올것 -- 토요일
  end

  defp get_first_video_details([], _api_key), do: nil

  defp get_first_video_details([%{id: video_id} | _], api_key) do
    case Youtube.get_video_details(video_id, api_key: api_key) do
      {:ok, details} -> details
      {:error, _message} -> nil
    end
  end
end
