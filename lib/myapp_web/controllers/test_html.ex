defmodule MyappWeb.TestHTML do
  use MyappWeb, :html

  embed_templates "test_html/*"

  attr :flash, :map, default: %{}
  def error_message(assigns) do
    ~H"""
    <%= if error = @flash[:error] do %>
      <div class="mb-4 p-4 bg-red-100 border border-red-400 text-red-700 rounded" role="alert">
        <p class="font-medium"><%= error %></p>
        <%= if @flash[:error_detail] do %>
          <p class="mt-2 text-sm"><%= @flash[:error_detail] %></p>
        <% end %>
      </div>
    <% end %>
    """
  end
end

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
          flash: %{error: "API Key Required", error_detail: "Please enter your YouTube API key to search videos."}, 
          videos: [], 
          video_details: nil, 
          api_key: ""
        )
      query == "" ->
        # Missing search query
        render(conn, :test, 
          flash: %{error: "Search Query Required", error_detail: "Please enter what you'd like to search for."}, 
          videos: [], 
          video_details: nil, 
          api_key: api_key
        )
      true ->
        # Both API key and query are present
        case Youtube.search_videos(query, [api_key: api_key]) do
          {:ok, videos} ->
            # Get details for the first video if we have results
            video_details = case List.first(videos) do
              nil -> nil
              video -> 
                case Youtube.get_video_details(video.id, [api_key: api_key]) do
                  {:ok, details} -> details
                  {:error, _} -> nil # Silently handle video details error
                end
            end
            render(conn, :test, flash: %{}, videos: videos, video_details: video_details, api_key: api_key)
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
end
