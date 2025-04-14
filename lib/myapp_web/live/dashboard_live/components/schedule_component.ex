defmodule MyappWeb.DashboardLive.Components.ScheduleComponent do
  use MyappWeb, :live_component

  alias Myapp.Accounts
  alias Myapp.SocialAuth

  @social_platforms [:twitter, :instagram, :tiktok, :youtube, :facebook]

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:upload_progress, 0)
     |> assign(:preview_url, nil)
     |> assign(:selected_platforms, [])
     |> assign(:social_accounts, %{})
     |> assign(:upload_form, %{
       "title" => "",
       "description" => "",
       "tags" => "",
       "schedule_at" => nil
     })}
  end

  @impl true
  def update(assigns, socket) do
    if connected?(socket) && Map.get(socket.assigns, :social_accounts, %{}) == %{} do
      send(self(), {:load_social_accounts_for_schedule, self()})
    end

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("validate-form", %{"upload_form" => form_params}, socket) do
    {:noreply, assign(socket, :upload_form, form_params)}
  end

  @impl true
  def handle_event("schedule", %{"upload_form" => form_params}, socket) do
    # Handle scheduling for future posting
    scheduled_time = form_params["schedule_at"]

    if socket.assigns.selected_platforms == [] do
      {:noreply,
       socket
       |> put_flash(:error, "Please select at least one social media platform")}
    else
      # In a real implementation, we would save the schedule to the database

      # Send a message to the parent LiveView to update the UI
      send(socket.assigns.parent_pid, {:schedule_complete, socket.assigns.selected_platforms, scheduled_time})

      {:noreply,
       socket
       |> put_flash(:info, "Content scheduled for upload at #{scheduled_time}")}
    end
  end

  @impl true
  def handle_event("toggle-platform", %{"platform" => platform}, socket) do
    platform = String.to_existing_atom(platform)
    selected_platforms = socket.assigns.selected_platforms

    updated_platforms =
      if platform in selected_platforms do
        Enum.reject(selected_platforms, fn p -> p == platform end)
      else
        [platform | selected_platforms]
      end

    {:noreply, assign(socket, :selected_platforms, updated_platforms)}
  end

  @impl true
  def handle_event("goto-upload", _params, socket) do
    send(socket.assigns.parent_pid, :switch_to_upload_tab)
    {:noreply, socket}
  end

  def handle_info({:social_accounts_loaded, social_accounts}, socket) do
    {:noreply, assign(socket, :social_accounts, social_accounts)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-xl font-semibold mb-4">Schedule Your Content</h2>
      <p class="text-gray-600 mb-6">Plan ahead by scheduling your content for optimal posting times.</p>

      <form phx-submit="schedule" phx-change="validate-form" phx-target={@myself}>
        <!-- Content Selection Section -->
        <div class="mb-6">
          <h3 class="text-lg font-medium text-gray-900 mb-3">1. Select Content</h3>
          
          <!-- Content preview card -->
          <div class="bg-gray-50 p-4 rounded-lg border border-gray-200 mb-4">
            <%= if @preview_url do %>
              <div class="flex items-start">
                <div class="flex-shrink-0 mr-4">
                  <img src={@preview_url} alt="Video thumbnail" class="h-24 w-32 object-cover rounded" />
                </div>
                <div>
                  <h4 class="text-base font-medium text-gray-900"><%= @upload_form["title"] || "Untitled Video" %></h4>
                  <p class="text-sm text-gray-500 line-clamp-2 mb-2">
                    <%= @upload_form["description"] || "No description provided" %>
                  </p>
                  <div class="flex flex-wrap gap-1">
                    <%= if @upload_form["tags"] && @upload_form["tags"] != "" do %>
                      <%= for tag <- String.split(@upload_form["tags"], ",") do %>
                        <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800">
                          <%= String.trim(tag) %>
                        </span>
                      <% end %>
                    <% else %>
                      <span class="text-xs text-gray-400">No tags added</span>
                    <% end %>
                  </div>
                </div>
              </div>
            <% else %>
              <div class="flex items-center justify-center py-6">
                <div class="text-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                  </svg>
                  <p class="mt-2 text-sm text-gray-500">No content selected</p>
                  <button
                    type="button"
                    phx-click="goto-upload"
                    phx-target={@myself}
                    class="mt-3 inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50"
                  >
                    Upload New Content
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        </div>
        
        <!-- Platform Selection -->
        <div class="mb-6">
          <h3 class="text-lg font-medium text-gray-900 mb-3">2. Select Platforms</h3>
          
          <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
            <%= for {platform, status} <- @social_accounts do %>
              <button 
                type="button"
                phx-click="toggle-platform"
                phx-value-platform={platform}
                phx-target={@myself}
                disabled={!status.connected}
                class={
                  "flex items-center justify-center py-2 px-4 border rounded-md text-sm font-medium transition-colors " <>
                  if(!status.connected) do
                    "bg-gray-100 text-gray-400 cursor-not-allowed"
                  else
                    if(platform in @selected_platforms) do
                      "bg-indigo-100 text-indigo-700 border-indigo-300 hover:bg-indigo-200"
                    else
                      "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
                    end
                  end
                }
              >
                <%= platform |> Atom.to_string() |> String.capitalize() %>
                <%= if platform in @selected_platforms do %>
                  <svg xmlns="http://www.w3.org/2000/svg" class="ml-2 h-4 w-4 text-indigo-500" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                  </svg>
                <% end %>
              </button>
            <% end %>
          </div>

          <%= if !Enum.empty?(@selected_platforms) do %>
            <p class="mt-2 text-sm text-gray-600">
              Selected: <%= @selected_platforms |> Enum.map(&(Atom.to_string(&1) |> String.capitalize())) |> Enum.join(", ") %>
            </p>
          <% else %>
            <p class="mt-2 text-sm text-red-500">
              Please select at least one platform
            </p>
          <% end %>
        </div>
        
        <!-- Schedule Settings -->
        <div class="mb-6">
          <h3 class="text-lg font-medium text-gray-900 mb-3">3. Set Schedule Time</h3>
          
          <div class="space-y-4">
            <div>
              <label for="schedule_at" class="block text-sm font-medium text-gray-700">Date and Time</label>
              <input 
                type="datetime-local" 
                id="schedule_at" 
                name="upload_form[schedule_at]" 
                value={@upload_form["schedule_at"]} 
                min={DateTime.utc_now() |> DateTime.add(30, :minute) |> DateTime.to_iso8601() |> String.slice(0, 16)}
                class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" 
              />
              <p class="mt-1 text-xs text-gray-500">Schedule at least 30 minutes in the future</p>
            </div>
            
            <div>
              <label class="block text-sm font-medium text-gray-700">Timezone</label>
              <div class="mt-1 relative rounded-md shadow-sm">
                <select 
                  class="block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                  disabled
                >
                  <option>Your local timezone (JST)</option>
                </select>
              </div>
            </div>
          </div>
        </div>
        
        <!-- Action Button -->
        <div>
          <button 
            type="submit"
            class="inline-flex justify-center items-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
            disabled={@preview_url == nil || Enum.empty?(@selected_platforms) || !@upload_form["schedule_at"]}
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="-ml-1 mr-2 h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd" />
            </svg>
            Schedule Upload
          </button>
        </div>
      </form>
    </div>
    """
  end
end
