defmodule MyappWeb.DashboardLive.Components.UploadTabs.DescriptionComponent do
  use MyappWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

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

  # Validation logic that takes selected platforms into account
  defp valid_form?(form) do
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
    <div>
      <h2 class="text-xl font-semibold mb-4">Post Description</h2>
      <p class="text-gray-600 mb-6">Add details about your content to improve discovery and engagement.</p>

      <form phx-change="validate-form" phx-target={@myself}>
        <div class="space-y-4 max-w-2xl">
          <% youtube_selected = :youtube in @selected_platforms || "youtube" in @selected_platforms %>
          
          <!-- Title field - only shown when YouTube is selected -->
          <%= if youtube_selected do %>
          <div>
            <label for="title" class="block text-sm font-medium text-gray-700">
              Title <span class="text-red-500">*</span>
              <span class="text-xs text-indigo-600 ml-1">(Required for YouTube)</span>
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
            <label for="description" class="block text-sm font-medium text-gray-700">
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
            <label for="tags" class="block text-sm font-medium text-gray-700">Tags</label>
            <input
              type="text"
              id="tags"
              name="upload_form[tags]"
              value={@upload_form["tags"]}
              class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              placeholder="Enter tags separated by commas"
            />
            <p class="mt-1 text-xs text-gray-500">
              Add relevant tags to help people discover your content
            </p>
          </div>
        </div>

        <!-- Navigation buttons -->
        <div class="flex justify-between mt-8">
          <button
            type="button"
            phx-click="goto-photo-selection"
            phx-target={@myself}
            class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="mr-2 h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M7.707 14.707a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 1.414L5.414 9H17a1 1 0 110 2H5.414l2.293 2.293a1 1 0 010 1.414z" clip-rule="evenodd" />
            </svg>
            Back to Photos
          </button>
          <button
            type="button"
            phx-click="goto-preview"
            phx-target={@myself}
            class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Continue to Preview
            <svg xmlns="http://www.w3.org/2000/svg" class="ml-2 h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M12.293 5.293a1 1 0 011.414 0l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414-1.414L14.586 11H3a1 1 0 110-2h11.586l-2.293-2.293a1 1 0 010-1.414z" clip-rule="evenodd" />
            </svg>
          </button>
        </div>
      </form>
    </div>
    """
  end
end
