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
