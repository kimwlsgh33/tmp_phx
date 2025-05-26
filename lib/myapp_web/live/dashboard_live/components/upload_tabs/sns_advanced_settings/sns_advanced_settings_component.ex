defmodule MyappWeb.DashboardLive.Components.UploadTabs.SnsAdvancedSettings.SnsAdvancedSettingsComponent do
  use MyappWeb, :live_component

  alias MyappWeb.DashboardLive.Components.UploadTabs.SnsAdvancedSettings.{
    FacebookSettingsComponent,
    TwitterSettingsComponent,
    InstagramSettingsComponent,
    TiktokSettingsComponent,
    YoutubeSettingsComponent
  }

  @impl true
  def mount(socket) do
    {:ok,
      socket
      |> assign(:active_platform, nil)
      |> assign(:advanced_settings, %{})
    }
  end

  @impl true
  def update(assigns, socket) do
    # Always use parent's advanced_settings if provided, otherwise keep current or initialize
    advanced_settings =
      if Map.has_key?(assigns, :advanced_settings) do
        assigns.advanced_settings
      else
        socket.assigns[:advanced_settings] || %{}
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:advanced_settings, advanced_settings)
      |> assign_active_platform(assigns.selected_platforms)

    {:ok, socket}
  end

  defp assign_active_platform(socket, []) do
    assign(socket, :active_platform, nil)
  end

  defp assign_active_platform(socket, platforms) do
    # If active_platform is nil or not in selected platforms, set to first platform
    if socket.assigns.active_platform == nil || socket.assigns.active_platform not in platforms do
      assign(socket, :active_platform, List.first(platforms))
    else
      socket
    end
  end

  @impl true
  def handle_event("update_advanced_settings", %{"platform" => platform, "settings" => settings}, socket) do
    # Update the advanced settings for this specific platform
    # Support both string and atom keys for backward compatibility
    updated_settings =
      socket.assigns.advanced_settings
      |> Map.put(platform, settings)           # String key ("twitter")
      |> Map.put(String.to_existing_atom(platform), settings)  # Atom key (:twitter)

    # Send the entire updated settings map to the parent
    send(socket.assigns.parent_pid, {:update_advanced_settings, updated_settings})

    {:noreply, assign(socket, :advanced_settings, updated_settings)}
  end

  @impl true
  def handle_event("select_platform_tab", %{"platform" => platform}, socket) do
    platform = String.to_existing_atom(platform)
    {:noreply, assign(socket, :active_platform, platform)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white dark:bg-black p-4 rounded-lg border border-gray-200 dark:border-gray-700">
      <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Advanced Platform Settings</h3>

      <%= if Enum.empty?(@selected_platforms) do %>
        <div class="text-center py-8 text-gray-500 dark:text-gray-400">
          <svg xmlns="http://www.w3.org/2000/svg" class="mx-auto h-12 w-12 text-gray-400 dark:text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
          </svg>
          <p class="mt-2 dark:text-gray-300">Select platforms in Step 1 to see advanced settings</p>
        </div>
      <% else %>
        <!-- Platform Tabs -->
        <div class="mb-4 border-b border-gray-200 dark:border-gray-700">
          <nav class="flex -mb-px space-x-4" aria-label="Platform settings tabs">
            <%= for platform <- @selected_platforms do %>
              <button
                phx-click="select_platform_tab"
                phx-value-platform={platform}
                phx-target={@myself}
                class={"
                  px-3 py-2 text-sm font-medium rounded-t-md focus:outline-none flex items-center
                  #{if @active_platform == platform, do: "border-b-2 border-indigo-500 text-indigo-600", else: "text-gray-500 hover:text-gray-700 hover:border-gray-300"}
                "}
              >
                <.platform_logo platform={platform} />
              </button>
            <% end %>
          </nav>
        </div>

        <!-- Platform Content -->
        <div class="platform-settings">
          <%= if @active_platform do %>
            <%= case @active_platform do %>
              <% :facebook -> %>
                <.live_component
                  module={FacebookSettingsComponent}
                  id={"facebook-settings-#{@id}"}
                  parent_pid={@myself}
                  platform_key="facebook"
                  advanced_settings={@advanced_settings}
                />
              <% :twitter -> %>
                <.live_component
                  module={TwitterSettingsComponent}
                  id={"twitter-settings-#{@id}"}
                  parent_pid={@myself}
                  platform_key="twitter"
                  advanced_settings={@advanced_settings}
                />
              <% :instagram -> %>
                <.live_component
                  module={InstagramSettingsComponent}
                  id={"instagram-settings-#{@id}"}
                  parent_pid={@myself}
                  platform_key="instagram"
                  advanced_settings={@advanced_settings}
                />
              <% :tiktok -> %>
                <.live_component
                  module={TiktokSettingsComponent}
                  id={"tiktok-settings-#{@id}"}
                  parent_pid={@myself}
                  platform_key="tiktok"
                  advanced_settings={@advanced_settings}
                />
              <% :youtube -> %>
                <.live_component
                  module={YoutubeSettingsComponent}
                  id={"youtube-settings-#{@id}"}
                  parent_pid={@myself}
                  platform_key="youtube"
                  advanced_settings={@advanced_settings}
                />
              <% _ -> %>
                <div class="p-4 bg-yellow-50 dark:bg-yellow-900 text-yellow-700 dark:text-yellow-200 rounded">
                  No advanced settings available for this platform.
                </div>
            <% end %>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # Helper to display friendly platform names
  defp platform_name(:facebook), do: "Facebook"
  defp platform_name(:twitter), do: "Twitter"
  defp platform_name(:instagram), do: "Instagram"
  defp platform_name(:tiktok), do: "TikTok"
  defp platform_name(:youtube), do: "YouTube"
  defp platform_name(_), do: "Unknown"

  # Helper to render SVG logo for each platform
  defp platform_logo(assigns) do
    platform = assigns.platform
    ~H"""
    <%= case platform do %>
      <% :twitter -> %>
        <svg class="w-4 h-4 mr-1" viewBox="0 0 24 24" fill="#1DA1F2">
          <path d="M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z"/>
        </svg>
      <% :instagram -> %>
        <svg class="w-4 h-4 mr-1" viewBox="0 0 24 24">
          <linearGradient id="instagram-gradient-{platform}" x1="0%" y1="100%" x2="100%" y2="0%">
            <stop offset="0%" stop-color="#FFDC80" />
            <stop offset="10%" stop-color="#FCAF45" />
            <stop offset="50%" stop-color="#F77737" />
            <stop offset="70%" stop-color="#F56040" />
            <stop offset="80%" stop-color="#FD1D1D" />
            <stop offset="90%" stop-color="#E1306C" />
            <stop offset="100%" stop-color="#C13584" />
          </linearGradient>
          <path fill={"url(#instagram-gradient-" <> Atom.to_string(platform) <> ")"} d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/>
        </svg>
      <% :tiktok -> %>
        <svg class="w-4 h-4 mr-1" viewBox="0 0 24 24">
          <path fill="#000000" d="M19.59 6.69a4.83 4.83 0 01-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 01-5.2 1.74 2.89 2.89 0 012.31-4.64 2.93 2.93 0 01.88.13V9.4a6.84 6.84 0 00-1-.05A6.33 6.33 0 005 20.1a6.34 6.34 0 0010.86-4.43v-7a8.16 8.16 0 004.77 1.52v-3.4a4.85 4.85 0 01-1-.1z"/>
        </svg>
      <% :facebook -> %>
        <svg class="w-4 h-4 mr-1" viewBox="0 0 24 24" fill="#1877F2">
          <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
        </svg>
      <% :youtube -> %>
        <svg class="w-4 h-4 mr-1" viewBox="0 0 24 24" fill="#FF0000">
          <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
        </svg>
      <% _ -> %>
        <svg class="w-4 h-4 mr-1" viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 18c-4.411 0-8-3.589-8-8s3.589-8 8-8 8 3.589 8 8-3.589 8-8 8z"/>
          <path d="M11 11h2v6h-2zm0-4h2v2h-2z"/>
        </svg>
    <% end %>
    """
  end
end
