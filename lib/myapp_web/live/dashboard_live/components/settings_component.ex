defmodule MyappWeb.DashboardLive.Components.SettingsComponent do
  use MyappWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("disconnect-platform", %{"platform" => platform}, socket) do
    # Forward this event to the parent LiveView
    send(socket.assigns.parent_pid, {:disconnect_platform, platform})
    {:noreply, socket}
  end

  defp platform_color(platform) do
    case platform do
      :twitter -> "bg-blue-500"
      :instagram -> "bg-pink-600"
      :facebook -> "bg-blue-700"
      :youtube -> "bg-red-600"
      :tiktok -> "bg-black"
      _ -> "bg-gray-600" # Default color
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-xl font-semibold mb-4">Social Media Connections</h2>
      <p class="text-gray-600 mb-6">Connect your social media accounts to enable seamless posting across platforms.</p>
      
      <div class="space-y-6">
        <%= for {platform, status} <- @social_accounts do %>
          <div class="bg-gray-50 p-4 rounded-lg border border-gray-200">
            <div class="flex justify-between items-center">
              <div class="flex items-center">
                <!-- Platform icon would go here -->
                <div class={"w-10 h-10 rounded-full flex items-center justify-center #{platform_color(platform)}"}>
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-8.707l-3-3a1 1 0 00-1.414 0l-3 3a1 1 0 001.414 1.414L9 9.414V13a1 1 0 102 0V9.414l1.293 1.293a1 1 0 001.414-1.414z" clip-rule="evenodd" />
                  </svg>
                </div>
                <div class="ml-3">
                  <h3 class="text-lg font-medium text-gray-900">
                    <%= platform |> Atom.to_string() |> String.capitalize() %>
                  </h3>
                  <p class="text-sm text-gray-500">
                    <%= if status.connected do %>
                      Connected and ready for posting
                    <% else %>
                      Not connected
                    <% end %>
                  </p>
                </div>
              </div>
              
              <%= if status.connected do %>
                <button 
                  type="button"
                  phx-click="disconnect-platform"
                  phx-value-platform={platform}
                  phx-target={@myself}
                  class="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded text-red-700 bg-red-100 hover:bg-red-200">
                  Disconnect
                </button>
              <% else %>
                <.link
                  href="#"
                  class="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded text-indigo-700 bg-indigo-100 hover:bg-indigo-200">
                  Connect Account
                </.link>
              <% end %>
            </div>
            
            <%= if status.connected do %>
              <div class="mt-4 pt-4 border-t border-gray-200">
                <h4 class="text-sm font-medium text-gray-700 mb-2">Account Settings</h4>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label class="block text-xs font-medium text-gray-500 mb-1">Profile</label>
                    <div class="flex items-center">
                      <div class="h-8 w-8 rounded-full bg-gray-300 mr-2"></div>
                      <span class="text-sm">User123</span>
                    </div>
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-gray-500 mb-1">Last used</label>
                    <span class="text-sm">April 1, 2025</span>
                  </div>
                </div>
                <div class="mt-4">
                  <label class="block text-xs font-medium text-gray-500 mb-1">Permissions</label>
                  <div class="flex flex-wrap gap-2">
                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">Post</span>
                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">Upload Media</span>
                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">Read Timeline</span>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end

