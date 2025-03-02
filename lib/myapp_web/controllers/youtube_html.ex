defmodule MyappWeb.YoutubeHTML do
  use MyappWeb, :html

  embed_templates "youtube_html/*"

  @doc """
  Renders an error message component for YouTube API errors.
  """
  attr :flash, :map, required: true
  def error_message(assigns) do
    ~H"""
    <%= if @flash[:error] do %>
      <div class="bg-red-50 border-l-4 border-red-500 p-4 mb-6 dark:bg-red-900/20 dark:border-red-800">
        <div class="flex">
          <div class="ml-3">
            <p class="text-red-700 font-medium dark:text-red-400"><%= @flash[:error] %></p>
            <p class="text-red-600 mt-1 dark:text-red-300"><%= @flash[:error_detail] %></p>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end
