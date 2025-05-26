defmodule MyappWeb.DashboardLive.Components.UploadTabs.DescriptionComponent do
  use MyappWeb, :live_component

  alias MyappWeb.DashboardLive.Components.UploadTabs.SnsAdvancedSettings.SnsAdvancedSettingsComponent

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:advanced_settings, fn -> %{} end)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate-form", %{"upload_form" => form_params}, socket) do
    # Update local state
    socket = assign(socket, :upload_form, form_params)

    # Notify parent of the form change
    send(socket.assigns.parent_pid, {:update_form, form_params})

    {:noreply, socket}
  end
  
  @impl true
  def handle_event("update-advanced-settings", %{"platform" => platform, "settings" => settings}, socket) do
    # Update the parent with the advanced settings
    send(socket.assigns.parent_pid, {:update_advanced_settings, %{platform => settings}})
    
    {:noreply, socket}
  end

  @impl true
  def handle_event("goto-photo-selection", _params, socket) do
    # Notify parent to switch back to the first tab
    send(socket.assigns.parent_pid, :switch_to_photo_selection_tab)
    {:noreply, socket}
  end

  @impl true
  def handle_event("goto-preview", _params, socket) do
    # Validate form before proceeding
    if valid_form?(socket.assigns.upload_form) do
      # Notify parent to switch to the preview tab
      send(socket.assigns.parent_pid, :switch_to_preview_tab)
      {:noreply, socket}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Please fill in all required fields")}
    end
  end

  # Validation function used in both the event handler and template
  def valid_form?(form) do
    # Description is always required
    description = Map.get(form, "description", "")
    title = Map.get(form, "title", "")
    selected_platforms = Map.get(form, "_selected_platforms", [])

    # 유튜브가 선택되었을 때만 제목이 필수
    youtube_selected = :youtube in selected_platforms || "youtube" in selected_platforms

    # 기본 필수 필드 검증
    base_valid = String.trim(description) != ""

    # 유튜브가 선택된 경우 제목도 필수
    if youtube_selected do
      base_valid && String.trim(title) != ""
    else
      base_valid
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-[600px]">
      <div class="flex">
        <div class="w-1/2 pr-6">
          <h2 class="text-xl font-semibold mb-4 dark:text-gray-300">Post Description</h2>
          <p class="text-gray-600 dark:text-gray-300 mb-6">Add details about your content to improve discovery and engagement.</p>

          <form phx-change="validate-form" phx-target={@myself}>
            <div class="space-y-4">
          <% youtube_selected = :youtube in @selected_platforms || "youtube" in @selected_platforms %>

          <!-- Title field - only shown when YouTube is selected -->
          <%= if youtube_selected do %>
          <div>
            <label for="title" class="block text-sm font-medium text-gray-700 dark:text-gray-200">
              Title <span class="text-red-500">*</span>
              <span class="text-xs text-indigo-600 dark:text-indigo-400 ml-1">(Required for YouTube)</span>
            </label>
            <input
              type="text"
              id="title"
              name="upload_form[title]"
              value={@upload_form["title"]}
              class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              placeholder="Enter a title for your YouTube video"
              required={youtube_selected}
            />
            <%= if youtube_selected && Map.get(@upload_form, "title", "") == "" do %>
              <p class="mt-1 text-xs text-red-500">Title is required for YouTube</p>
            <% end %>
          </div>
          <% end %>

          <div>
            <label for="description" class="block text-sm font-medium text-gray-700 dark:text-gray-200">
              Description <span class="text-red-500">*</span>
            </label>
            <textarea
              id="description"
              name="upload_form[description]"
              rows="5"
              class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              placeholder="Describe your post to engage your audience"
              required
            ><%= @upload_form["description"] %></textarea>
            <%= if Map.get(@upload_form, "description", "") == "" do %>
              <p class="mt-1 text-xs text-red-500">Description is required</p>
            <% end %>
          </div>

          <div>
            <label for="tags" class="block text-sm font-medium text-gray-700 dark:text-gray-200">Tags</label>
            <input
              type="text"
              id="tags"
              name="upload_form[tags]"
              value={@upload_form["tags"]}
              class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              placeholder="Enter tags separated by commas"
            />
            <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
              Add relevant tags to help people discover your content
            </p>
          </div>
            </div>

            <!-- Hidden state for validation -->
            <div id="form-validation-state" phx-hook="FormValidation" data-valid={valid_form?(@upload_form) && "true" || "false"} class="hidden"></div>
          </form>
        </div>
        
        <!-- Advanced Settings Column -->
        <div class="w-1/2 pl-6 border-l border-gray-200 dark:border-gray-700">
          <.live_component
            module={SnsAdvancedSettingsComponent}
            id="sns-advanced-settings"
            parent_pid={@myself}
            selected_platforms={@selected_platforms}
            advanced_settings={@advanced_settings}
          />
        </div>
      </div>
    </div>
    """
  end
end
