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
    <div class="bg-white p-4 rounded-lg border border-gray-200">
      <h3 class="text-lg font-medium text-gray-900 mb-4">Advanced Platform Settings</h3>

      <%= if Enum.empty?(@selected_platforms) do %>
        <div class="text-center py-8 text-gray-500">
          <svg xmlns="http://www.w3.org/2000/svg" class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
          </svg>
          <p class="mt-2">Select platforms in Step 1 to see advanced settings</p>
        </div>
      <% else %>
        <!-- Platform Tabs -->
        <div class="mb-4 border-b border-gray-200">
          <nav class="flex -mb-px space-x-4" aria-label="Platform settings tabs">
            <%= for platform <- @selected_platforms do %>
              <button
                phx-click="select_platform_tab"
                phx-value-platform={platform}
                phx-target={@myself}
                class={"
                  px-3 py-2 text-sm font-medium rounded-t-md focus:outline-none
                  #{if @active_platform == platform, do: "border-b-2 border-indigo-500 text-indigo-600", else: "text-gray-500 hover:text-gray-700 hover:border-gray-300"}
                "}
              >
                <%= platform_name(platform) %>
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
                <div class="p-4 bg-yellow-50 text-yellow-700 rounded">
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
end
