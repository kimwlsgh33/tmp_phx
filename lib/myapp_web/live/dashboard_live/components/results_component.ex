defmodule MyappWeb.DashboardLive.Components.ResultsComponent do
  use MyappWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("retry-upload", %{"id" => id}, socket) do
    # Send message to parent to handle retry
    send(socket.assigns.parent_pid, {:retry_upload, id})
    
    {:noreply, socket}
  end

  @impl true
  def handle_event("goto-upload", _params, socket) do
    send(socket.assigns.parent_pid, :switch_to_upload_tab)
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
      <h2 class="text-xl font-semibold mb-4">Upload Results</h2>
      <p class="text-gray-600 mb-6">View the status and results of your recent social media uploads.</p>
      
      <%= if Map.get(assigns, :loading_uploads, false) do %>
        <div class="animate-pulse space-y-4">
          <div class="h-20 bg-gray-200 rounded"></div>
          <div class="h-20 bg-gray-200 rounded"></div>
          <div class="h-20 bg-gray-200 rounded"></div>
        </div>
      <% else %>
        <%= if Enum.empty?(@recent_uploads) do %>
          <div class="text-center py-12">
            <svg xmlns="http://www.w3.org/2000/svg" class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2-10v8a2 2 0 01-2 2H7a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2z" />
            </svg>
            <p class="mt-2 text-sm text-gray-500">No uploads found</p>
            <button
              type="button"
              phx-click="goto-upload"
              phx-target={@myself}
              class="mt-3 inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50"
            >
              Create Your First Upload
            </button>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for upload <- @recent_uploads do %>
              <div class="bg-white border rounded-lg shadow-sm overflow-hidden">
                <div class="p-4">
                  <div class="flex justify-between items-start">
                    <div>
                      <div class="flex items-center">
                        <span class="text-lg font-medium text-gray-900">
                          Upload #<%= upload.id %>
                        </span>
                        <%= case upload.status do %>
                          <% :success -> %>
                            <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                              Success
                            </span>
                          <% :processing -> %>
                            <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                              Processing
                            </span>
                          <% :failed -> %>
                            <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                              Failed
                            </span>
                        <% end %>
                      </div>
                      <p class="text-sm text-gray-500 mt-1">
                        <%= Calendar.strftime(upload.timestamp, "%B %d, %Y at %I:%M %p") %>
                      </p>
                    </div>
                    
                    <div class="flex space-x-1">
                      <%= for platform <- upload.platforms do %>
                        <div 
                          class={"w-8 h-8 rounded-full flex items-center justify-center #{platform_color(platform)}"} 
                          title={platform |> Atom.to_string() |> String.capitalize()}
                        >
                          <span class="text-xs text-white font-bold">
                            <%= platform |> Atom.to_string() |> String.first() |> String.upcase() %>
                          </span>
                        </div>
                      <% end %>
                    </div>
                  </div>
                  
                  <!-- Posted Links -->
                  <%= if upload.status == :success && map_size(upload.links) > 0 do %>
                    <div class="mt-4 pt-4 border-t border-gray-200">
                      <h4 class="text-sm font-medium text-gray-700 mb-2">Posted Links</h4>
                      <div class="space-y-2">
                        <%= for {platform, link} <- upload.links, link != nil do %>
                          <a 
                            href={link} 
                            target="_blank" 
                            rel="noopener noreferrer"
                            class="flex items-center text-sm text-indigo-600 hover:text-indigo-900"
                          >
                            <div class={"w-5 h-5 rounded-full flex items-center justify-center mr-2 #{platform_color(platform)}"}>
                              <span class="text-xs text-white font-bold">
                                <%= platform |> Atom.to_string() |> String.first() |> String.upcase() %>
                              </span>
                            </div>
                            View on <%= platform |> Atom.to_string() |> String.capitalize() %>
                            <svg xmlns="http://www.w3.org/2000/svg" class="ml-1 h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                              <path d="M11 3a1 1 0 100 2h2.586l-6.293 6.293a1 1 0 101.414 1.414L15 6.414V9a1 1 0 102 0V4a1 1 0 00-1-1h-5z" />
                              <path d="M5 5a2 2 0 00-2 2v8a2 2 0 002 2h8a2 2 0 002-2v-3a1 1 0 10-2 0v3H5V7h3a1 1 0 000-2H5z" />
                            </svg>
                          </a>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                  
                  <!-- Error Message -->
                  <%= if upload.status == :failed && Map.get(upload, :error) do %>
                    <div class="mt-4 p-3 rounded bg-red-50 border border-red-100">
                      <p class="text-sm text-red-800">
                        <svg xmlns="http://www.w3.org/2000/svg" class="inline-block h-4 w-4 mr-1" viewBox="0 0 20 20" fill="currentColor">
                          <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                        </svg>
                        <%= upload.error %>
                      </p>
                    </div>
                  <% end %>
                  
                  <!-- Retry Button for Failed Uploads -->
                  <%= if upload.status == :failed do %>
                    <div class="mt-4">
                      <button
                        type="button"
                        phx-click="retry-upload"
                        phx-value-id={upload.id}
                        phx-target={@myself}
                        class="inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" class="mr-1.5 h-4 w-4 text-gray-500" viewBox="0 0 20 20" fill="currentColor">
                          <path fill-rule="evenodd" d="M4 2a1 1 0 011 1v2.101a7.002 7.002 0 0111.601 2.566 1 1 0 11-1.885.666A5.002 5.002 0 005.999 7H9a1 1 0 010 2H4a1 1 0 01-1-1V3a1 1 0 011-1zm.008 9.057a1 1 0 011.276.61A5.002 5.002 0 0014.001 13H11a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0v-2.101a7.002 7.002 0 01-11.601-2.566 1 1 0 01.61-1.276z" clip-rule="evenodd" />
                        </svg>
                        Retry Upload
                      </button>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end
end

