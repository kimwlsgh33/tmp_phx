defmodule MyappWeb.DashboardLive.Components.UploadTabs.SnsPreview.FacebookComponent do
  use MyappWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:preview_url, fn -> nil end)
      |> assign_new(:upload_form, fn -> %{} end)
      |> assign_new(:advanced_settings, fn -> %{
        "privacy" => "public",
        "allow_comments" => true,
        "location" => "",
        "feeling" => ""
      } end)

    {:ok, socket}
  end

  # Helper function to parse hashtags in description
  defp highlight_hashtags(description) do
    String.replace(description, ~r/#(\w+)/, "<span class=\"text-blue-500 font-semibold\">#\\1</span>")
  end

  # Helper function to generate a username for the platform
  defp generate_username do
    "Facebook User"
  end

  # Helper to show appropriate privacy icon
  defp privacy_icon("public") do
    """
    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM4.332 8.027a6.012 6.012 0 011.912-2.706C6.512 5.73 6.974 6 7.5 6A1.5 1.5 0 019 7.5V8a2 2 0 004 0 2 2 0 011.523-1.943A5.977 5.977 0 0116 10c0 .34-.028.675-.083 1H15a2 2 0 00-2 2v2.197A5.973 5.973 0 0110 16v-2a2 2 0 00-2-2 2 2 0 01-2-2 2 2 0 00-1.668-1.973z" clip-rule="evenodd" />
    </svg>
    """
  end

  defp privacy_icon("friends") do
    """
    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
      <path d="M13 6a3 3 0 11-6 0 3 3 0 016 0zM18 8a2 2 0 11-4 0 2 2 0 014 0zM14 15a4 4 0 00-8 0v3h8v-3zM6 8a2 2 0 11-4 0 2 2 0 014 0zM16 18v-3a5.972 5.972 0 00-.75-2.906A3.005 3.005 0 0119 15v3h-3zM4.75 12.094A5.973 5.973 0 004 15v3H1v-3a3 3 0 013.75-2.906z" />
    </svg>
    """
  end

  defp privacy_icon("private") do
    """
    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
      <path fill-rule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clip-rule="evenodd" />
    </svg>
    """
  end

  defp privacy_icon(_), do: nil

  @impl true
  def render(assigns) do
    ~H"""
    <div class="border border-gray-200 rounded-lg overflow-hidden bg-white shadow-lg" style="width: 320px;">
      <!-- Facebook header -->
      <div class="p-4 flex">
        <div class="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center text-white mr-2">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"></path>
            <circle cx="12" cy="7" r="4"></circle>
          </svg>
        </div>
        <div>
          <p class="font-semibold text-sm"><%= generate_username() %></p>
          <div class="flex items-center text-xs text-gray-500">
            <span><%= DateTime.utc_now |> Calendar.strftime("%b %d at %I:%M %p") %></span>

            <%= if privacy_icon(@advanced_settings["privacy"]) do %>
              <span class="mx-1">&bull;</span>
              <%= privacy_icon(@advanced_settings["privacy"]) %>
            <% end %>

            <%= if @advanced_settings["location"] && @advanced_settings["location"] != "" do %>
              <span class="mx-1">&bull;</span>
              <span class="flex items-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 mr-0.5" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd" />
                </svg>
                <%= @advanced_settings["location"] %>
              </span>
            <% end %>
          </div>
        </div>
        <div class="ml-auto">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-gray-500" viewBox="0 0 20 20" fill="currentColor">
            <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM16 12a2 2 0 100-4 2 2 0 000 4z" />
          </svg>
        </div>
      </div>

      <!-- Post content -->
      <div class="px-4 pb-2">
        <%= if @advanced_settings["feeling"] && @advanced_settings["feeling"] != "" do %>
          <p class="text-sm mb-2">
            <span class="font-medium"><%= generate_username() %></span> is feeling
            <span class="font-medium"><%= @advanced_settings["feeling"] %></span>
          </p>
        <% end %>
        <p class="text-sm mb-3"><%= raw highlight_hashtags(@upload_form["description"] || "") %></p>
      </div>

      <!-- Media -->
      <div class="border-t border-b border-gray-100">
        <%= if @preview_url do %>
          <video src={@preview_url} controls class="w-full h-auto" />
        <% else %>
          <div class="w-full h-56 bg-gray-100 flex items-center justify-center">
            <p class="text-gray-400">No media available</p>
          </div>
        <% end %>
      </div>

      <!-- Reaction counts -->
      <div class="p-2 flex justify-between items-center text-gray-500 text-xs">
        <div class="flex items-center">
          <!-- Like icon -->
          <div class="bg-blue-500 rounded-full w-5 h-5 flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 text-white" viewBox="0 0 20 20" fill="currentColor">
              <path d="M2 10.5a1.5 1.5 0 113 0v6a1.5 1.5 0 01-3 0v-6zM6 10.333v5.43a2 2 0 001.106 1.79l.05.025A4 4 0 008.943 18h5.416a2 2 0 001.962-1.608l1.2-6A2 2 0 0015.56 8H12V4a2 2 0 00-2-2 1 1 0 00-1 1v.667a4 4 0 01-.8 2.4L6.8 7.933a4 4 0 00-.8 2.4z" />
            </svg>
          </div>
          <!-- Love icon -->
          <div class="bg-red-500 rounded-full w-5 h-5 flex items-center justify-center -ml-1">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 text-white" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" clip-rule="evenodd" />
            </svg>
          </div>
          <span class="ml-1">1.5K</span>
        </div>
        <div>
          <%= if @advanced_settings["allow_comments"] do %>
            <span>234 comments • 45 shares</span>
          <% else %>
            <span>Comments disabled • 45 shares</span>
          <% end %>
        </div>
      </div>

      <!-- Action buttons -->
      <div class="flex justify-around py-2 border-t border-gray-200">
        <!-- Like -->
        <button class="flex items-center justify-center text-gray-600 font-medium text-sm">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" viewBox="0 0 20 20" fill="currentColor">
            <path d="M2 10.5a1.5 1.5 0 113 0v6a1.5 1.5 0 01-3 0v-6zM6 10.333v5.43a2 2 0 001.106 1.79l.05.025A4 4 0 008.943 18h5.416a2 2 0 001.962-1.608l1.2-6A2 2 0 0015.56 8H12V4a2 2 0 00-2-2 1 1 0 00-1 1v.667a4 4 0 01-.8 2.4L6.8 7.933a4 4 0 00-.8 2.4z" />
          </svg>
          Like
        </button>
        <!-- Comment -->
        <button class={"flex items-center justify-center font-medium text-sm #{if @advanced_settings["allow_comments"], do: "text-gray-600", else: "text-gray-400 cursor-not-allowed"}"} disabled={!@advanced_settings["allow_comments"]}>
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M18 13V5a2 2 0 00-2-2H4a2 2 0 00-2 2v8a2 2 0 002 2h3l3 3 3-3h3a2 2 0 002-2zM5 7a1 1 0 011-1h8a1 1 0 110 2H6a1 1 0 01-1-1zm1 3a1 1 0 100 2h3a1 1 0 100-2H6z" clip-rule="evenodd" />
          </svg>
          <%= if @advanced_settings["allow_comments"], do: "Comment", else: "Comments off" %>
        </button>
        <!-- Share -->
        <button class="flex items-center justify-center text-gray-600 font-medium text-sm">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" viewBox="0 0 20 20" fill="currentColor">
            <path d="M15 8a3 3 0 10-2.977-2.63l-4.94 2.47a3 3 0 100 4.319l4.94 2.47a3 3 0 10.895-1.789l-4.94-2.47a3.027 3.027 0 000-.74l4.94-2.47C13.456 7.68 14.19 8 15 8z" />
          </svg>
          Share
        </button>
      </div>
    </div>
    """
  end
end
