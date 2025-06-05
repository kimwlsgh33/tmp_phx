defmodule MyappWeb.NewDashboardLive do
  use MyappWeb, :live_view
  import Phoenix.LiveView.JS

  alias MyappWeb.DashboardLive.Components.UploadTabs.{
    PhotoSelectionComponent,
    DescriptionComponent,
    SnsSelectionComponent,
    PreviewComponent
  }

  alias Myapp.Accounts
  alias Myapp.SocialAuth

  # Simplified to only YouTube and TikTok
  @social_platforms [:tiktok, :youtube]

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    if connected?(socket) do
      send(self(), :load_social_accounts)
      send(self(), :load_recent_uploads)
      # Load saved settings from local storage
      send(self(), :load_saved_settings)
    end

    {:ok,
     socket
     |> assign(:page_title, "Simplified Social Media Dashboard")
     |> assign(:active_tab, "sns_selection")
     |> assign(:social_accounts, %{})
     |> assign(:loading_accounts, true)
     |> assign(:loading_uploads, true)
     |> assign(:recent_uploads, [])
     |> assign(:selected_platforms, [])
     |> assign(:preview_url, nil)
     |> assign(:completed_tabs, [])  # Track completed tabs for checkmarks
     |> assign(:social_platforms, @social_platforms)  # Add this line
     |> assign(:upload_form, %{
       "title" => "",
       "description" => "",
       "tags" => ""
       # Removed schedule-related fields
     })
     |> assign(:advanced_settings, %{})
     |> assign(:validation_states, %{
       "sns_selection" => false,
       "photo_selection" => false,
       "description" => false,
       "preview" => true  # Preview is always valid
     })
     |> allow_upload(:video,
       accept: ~w(.mp4 .mov .avi .wmv .flv .webm),
       max_entries: 5,
       max_file_size: 500_000_000
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    tab = params["tab"] || "sns_selection"

    # When changing tabs, update completed_tabs if moving forward
    completed_tabs =
      if socket.assigns[:active_tab] && socket.assigns.active_tab != tab do
        prev_tab = socket.assigns.active_tab
        if valid_tab_transition?(prev_tab, tab) && prev_tab not in socket.assigns.completed_tabs do
          [prev_tab | socket.assigns.completed_tabs]
        else
          socket.assigns.completed_tabs
        end
      else
        socket.assigns.completed_tabs
      end
    
    # When navigating via tabs, ensure we reload settings from localStorage
    # to maintain state persistence across all navigation methods
    socket = 
      if socket.assigns[:current_user] do
        user_id = socket.assigns.current_user.id
        socket
        |> push_event("load_settings", %{key: "user_#{user_id}_advanced_settings"})
        |> push_event("load_settings", %{key: "user_#{user_id}_selected_platforms"})
      else
        socket
      end

    {:noreply, socket
      |> assign(:active_tab, tab)
      |> assign(:completed_tabs, completed_tabs)}
  end

  # Check if the tab transition is moving forward in the workflow
  defp valid_tab_transition?("sns_selection", "photo_selection"), do: true
  defp valid_tab_transition?("photo_selection", "description"), do: true
  defp valid_tab_transition?("description", "preview"), do: true
  defp valid_tab_transition?(_, _), do: false

  @impl true
  def handle_info(:load_social_accounts, socket) do
    # In a real implementation, we would load from the database
    # For now, we'll use dummy data
    accounts = %{
      youtube: %{connected: true, username: "YourYouTubeChannel"},
      instagram: %{connected: true, username: "your_instagram_handle"},
      tiktok: %{connected: true, username: "your_tiktok_account"}
    }

    # Filter to only include the simplified set of platforms
    filtered_accounts = Map.take(accounts, @social_platforms)

    {:noreply,
     socket
     |> assign(:social_accounts, filtered_accounts)
     |> assign(:loading_accounts, false)}
  end

  @impl true
  def handle_info(:load_recent_uploads, socket) do
    # In a real implementation, we would load from the database
    # For now, we'll use dummy data
    recent_uploads = [
      %{
        id: 1,
        title: "Sample upload 1",
        platforms: [:youtube],
        status: :completed,
        uploaded_at: ~U[2025-01-01 12:00:00Z]
      },
      %{
        id: 2,
        title: "Sample upload 2",
        platforms: [:instagram],
        status: :completed,
        uploaded_at: ~U[2025-01-02 14:30:00Z]
      }
    ]

    {:noreply,
     socket
     |> assign(:recent_uploads, recent_uploads)
     |> assign(:loading_uploads, false)}
  end

  @impl true
  def handle_info(:load_saved_settings, socket) do
    if socket.assigns.current_user do
      user_id = socket.assigns.current_user.id

      # Push JS events to read from localStorage
      socket = socket
      |> push_event("load_settings", %{key: "user_#{user_id}_advanced_settings"})
      |> push_event("load_settings", %{key: "user_#{user_id}_selected_platforms"})
      
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:update_selected_platforms, platforms}, socket) do
    # Update selected platforms and track validation state for sns_selection tab
    validation_states = Map.put(socket.assigns.validation_states, "sns_selection", length(platforms) > 0)
    
    # Save to local storage
    if socket.assigns.current_user do
      user_id = socket.assigns.current_user.id
      platform_atoms = Enum.map(platforms, &Atom.to_string/1)
      push_event(socket, "save_settings", %{
        key: "user_#{user_id}_selected_platforms",
        value: Jason.encode!(platform_atoms)
      })
    end

    {:noreply,
     socket
     |> assign(:selected_platforms, platforms)
     |> assign(:validation_states, validation_states)}
  end

  @impl true
  def handle_info({:update_preview, preview_url}, socket) do
    # Update preview URL and track validation state for photo_selection tab
    validation_states = Map.put(socket.assigns.validation_states, "photo_selection", preview_url != nil)

    {:noreply,
     socket
     |> assign(:preview_url, preview_url)
     |> assign(:validation_states, validation_states)}
  end

  @impl true
  def handle_event("settings_loaded", %{"value" => value, "key" => key}, socket) do
    # Extract user_id from key pattern user_{id}_something
    case Jason.decode(value) do
      {:ok, decoded_value} ->
        # Handle different types of settings based on key pattern
        socket = cond do
          String.contains?(key, "_advanced_settings") ->
            assign(socket, :advanced_settings, decoded_value)
            
          String.contains?(key, "_selected_platforms") ->
            # Convert string platform names back to atoms
            platforms = Enum.map(decoded_value, &String.to_existing_atom/1)
            validation_states = Map.put(socket.assigns.validation_states, "sns_selection", length(platforms) > 0)
            socket
            |> assign(:selected_platforms, platforms)
            |> assign(:validation_states, validation_states)
            
          true -> socket
        end
        
        {:noreply, socket}
      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:switch_to_photo_selection_tab, socket) do
    # Mark sns_selection as completed when moving to photo_selection
    completed_tabs =
      if socket.assigns.active_tab == "sns_selection" && "sns_selection" not in socket.assigns.completed_tabs do
        ["sns_selection" | socket.assigns.completed_tabs]
      else
        socket.assigns.completed_tabs
      end

    {:noreply,
      socket
      |> assign(:completed_tabs, completed_tabs)
      |> push_patch(to: ~p"/new_dashboard?tab=photo_selection")}
  end

  @impl true
  def handle_info(:switch_to_description_tab, socket) do
    # Mark photo_selection as completed when moving to description
    completed_tabs =
      if socket.assigns.active_tab == "photo_selection" && "photo_selection" not in socket.assigns.completed_tabs do
        ["photo_selection" | socket.assigns.completed_tabs]
      else
        socket.assigns.completed_tabs
      end

    {:noreply,
      socket
      |> assign(:completed_tabs, completed_tabs)
      |> push_patch(to: ~p"/new_dashboard?tab=description")}
  end

  @impl true
  def handle_info(:switch_to_preview_tab, socket) do
    # Mark description as completed when moving to preview
    completed_tabs =
      if socket.assigns.active_tab == "description" && "description" not in socket.assigns.completed_tabs do
        ["description" | socket.assigns.completed_tabs]
      else
        socket.assigns.completed_tabs
      end

    {:noreply,
      socket
      |> assign(:completed_tabs, completed_tabs)
      |> push_patch(to: ~p"/new_dashboard?tab=preview")}
  end

  @impl true
  def handle_info({:update_form, form_data}, socket) do
    # Filter out any schedule-related fields for simplified dashboard
    filtered_form_data = form_data
                         |> Map.drop(["schedule", "schedule_at", "schedule_date", "schedule_time", "schedule_country"])

    {:noreply,
     socket
     |> assign(:upload_form, filtered_form_data)}
  end

  @impl true
  def handle_info({:update_advanced_settings, settings}, socket) do
    # Merge the new settings with existing settings
    updated_settings = Map.merge(socket.assigns.advanced_settings, settings)

    # Save to local storage
    if socket.assigns.current_user do
      user_id = socket.assigns.current_user.id
      push_event(socket, "save_settings", %{
        key: "user_#{user_id}_advanced_settings",
        value: Jason.encode!(updated_settings)
      })
    end

    {:noreply,
     socket
     |> assign(:advanced_settings, updated_settings)}
  end

  @impl true
  def handle_info({:advanced_settings_updated, %{platform: platform, settings: settings}}, socket) do
    # This handler for messages sent by platform-specific components
    # Convert the format to match what we expect
    platform_settings = %{platform => settings}

    # Send to our existing handler
    send(self(), {:update_advanced_settings, platform_settings})
    {:noreply, socket}
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

    # Always update validation state for sns_selection based on platform selection
    valid = length(updated_platforms) > 0

    {:noreply,
      socket
      |> assign(:selected_platforms, updated_platforms)
      |> assign(:validation_states, Map.put(socket.assigns.validation_states, "sns_selection", valid))}
  end

  @impl true
  def handle_event("disconnect-platform", %{"platform" => platform}, socket) do
    platform = String.to_existing_atom(platform)

    # In a real implementation, we would revoke the tokens for this platform
    # For now, just update the UI
    updated_accounts = Map.update(
      socket.assigns.social_accounts,
      platform,
      %{connected: false},
      fn account -> %{account | connected: false} end
    )

    # Remove from selected platforms if it was selected
    selected_platforms = Enum.reject(socket.assigns.selected_platforms, fn p -> p == platform end)

    {:noreply,
      socket
      |> assign(:social_accounts, updated_accounts)
      |> assign(:selected_platforms, selected_platforms)}
  end

  @impl true
  def handle_event("publish-now", _params, socket) do
    selected_platforms = socket.assigns.selected_platforms

    if length(selected_platforms) > 0 do
      # Here we would actually publish to the selected platforms
      # For now, just simulate publishing with a flash message
      platform_names = Enum.map_join(selected_platforms, ", ", fn p -> Atom.to_string(p) end)

      {:noreply,
        socket
        |> put_flash(:info, "Content published to #{platform_names}!")
        |> push_navigate(to: ~p"/new_dashboard")}
    else
      {:noreply,
        socket
        |> put_flash(:error, "Please select at least one platform to publish to")}
    end
  end

  @impl true
  def handle_event("update_validation_state", %{"component" => component, "valid" => valid}, socket) do
    # Update the validation state for the component
    validation_states = Map.put(socket.assigns.validation_states, component, valid)

    # Mark the tab as completed if it's valid and not already completed
    completed_tabs =
      if valid && component not in socket.assigns.completed_tabs do
        [component | socket.assigns.completed_tabs]
      else
        socket.assigns.completed_tabs
      end

    {:noreply,
      socket
      |> assign(:validation_states, validation_states)
      |> assign(:completed_tabs, completed_tabs)}
  end

  # Helper functions
  defp all_tabs_valid?(validation_states) do
    validation_states["sns_selection"] &&
    validation_states["photo_selection"] &&
    validation_states["description"]
  end

  defp can_publish?(assigns) do
    all_tabs_valid?(assigns.validation_states) &&
    length(assigns.selected_platforms) > 0
  end

  # Render functions
  @impl true
  def render(assigns) do
    ~H"""
    <div id="new-dashboard" class="flex flex-col min-h-screen bg-white dark:bg-black" phx-hook="SettingsStorage">
      <div class="flex-1">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-6">
          <div class="mb-6 flex justify-between items-center">
            <div>
              <h1 class="text-2xl font-bold text-black dark:text-gray-300">Simplified Social Media Dashboard</h1>
              <p class="text-gray-400 dark:text-gray-300">Instagram and YouTube only</p>
            </div>
            <div>
              <.link
                navigate={~p"/sns-accounts"}
                class="inline-flex items-center px-4 py-2 border border-[#FD4F00] border-[1px] text-sm font-medium rounded-md shadow-sm text-[#FD4F00] bg-white dark:bg-black hover:bg-white dark:hover:bg-black hover:text-[#FD4F00] focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-[#FD4F00] transition-colors duration-200"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" viewBox="0 0 20 20" fill="currentColor">
                  <path d="M10 2a6 6 0 00-6 6v3.586l-.707.707A1 1 0 004 14h12a1 1 0 00.707-1.707L16 11.586V8a6 6 0 00-6-6zM10 18a3 3 0 01-3-3h6a3 3 0 01-3 3z" />
                </svg>
                Manage SNS Accounts
              </.link>
            </div>
          </div>

          <!-- Dashboard Tab Navigation -->
          <div class="border-b border-gray-200 dark:border-gray-700 mb-6">
            <nav class="-mb-px flex space-x-8" aria-label="Tabs">
              <.tab_link active={@active_tab == "sns_selection"} route={~p"/new_dashboard?tab=sns_selection"} completed={"sns_selection" in @completed_tabs}>
                <div class="flex items-center">
                  <span class="text-sm sm:text-base">1. Choose Platforms</span>
                </div>
              </.tab_link>
              <.tab_link active={@active_tab == "photo_selection"} route={~p"/new_dashboard?tab=photo_selection"} completed={"photo_selection" in @completed_tabs}>
                <div class="flex items-center">
                  <span class="text-sm sm:text-base">2. Select Files</span>
                </div>
              </.tab_link>
              <.tab_link active={@active_tab == "description"} route={~p"/new_dashboard?tab=description"} completed={"description" in @completed_tabs}>
                <div class="flex items-center">
                  <span class="text-sm sm:text-base">3. Add Details</span>
                </div>
              </.tab_link>
              <.tab_link active={@active_tab == "preview"} route={~p"/new_dashboard?tab=preview"} completed={"preview" in @completed_tabs}>
                <div class="flex items-center">
                  <span class="text-sm sm:text-base">4. Preview</span>
                </div>
              </.tab_link>
            </nav>
          </div>

          <!-- Tab Content -->
          <div class="flex items-center justify-between">
            <!-- Previous tab button (left) -->
            <%= if get_prev_tab(@active_tab) do %>
              <button
                phx-click="navigate-tab"
                phx-value-tab={get_prev_tab(@active_tab)}
                class="inline-flex items-center px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 dark:bg-gray-800 dark:text-gray-300 dark:border-gray-600 dark:hover:bg-gray-700"
              >
                <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path></svg>
                Previous Step
              </button>
            <% else %>
              <div></div>  <!-- Empty div to maintain flex spacing -->
            <% end %>

            <!-- Tab content container -->
            <div class="flex-1 mx-4">
              <div class={["tab-content", @active_tab != "sns_selection" && "hidden"]}>
                <.live_component
                  module={SnsSelectionComponent}
                  id="sns_selection_component"
                  social_accounts={@social_accounts}
                  selected_platforms={@selected_platforms}
                  loading={@loading_accounts}
                  social_platforms={@social_platforms}
                  parent_pid={self()}
                  show_scheduled_upload={false}
                />
              </div>
              <div class={["tab-content", @active_tab != "photo_selection" && "hidden"]}>
                <.live_component
                  module={PhotoSelectionComponent}
                  id="photo_selection_component"
                  selected_platforms={@selected_platforms}
                  preview_url={@preview_url}
                  parent_pid={self()}
                />
              </div>
              <div class={["tab-content", @active_tab != "description" && "hidden"]}>
                <.live_component
                  module={DescriptionComponent}
                  id="description_component"
                  upload_form={@upload_form}
                  selected_platforms={@selected_platforms}
                  preview_url={@preview_url}
                  advanced_settings={@advanced_settings}
                  parent_pid={self()}
                />
              </div>
              <div class={["tab-content", @active_tab != "preview" && "hidden"]}>
                <.live_component
                  module={PreviewComponent}
                  id="preview_component"
                  upload_form={@upload_form}
                  selected_platforms={@selected_platforms}
                  preview_url={@preview_url}
                  advanced_settings={@advanced_settings}
                  parent_pid={self()}
                />
              </div>
            </div>

            <!-- Next tab button (right) -->
            <%= if get_next_tab(@active_tab) do %>
              <button
                phx-click="navigate-tab"
                phx-value-tab={get_next_tab(@active_tab)}
                class="inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-md hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600"
                disabled={!@validation_states[@active_tab]}
              >
                Next Step
                <svg class="w-5 h-5 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>
              </button>
            <% else %>
              <!-- Publish button only on the final tab -->
              <button
                phx-click="publish-now"
                class="inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-green-600 border border-transparent rounded-md hover:bg-green-700 dark:bg-green-500 dark:hover:bg-green-600"
                disabled={!can_publish?(assigns)}
              >
                Publish Now
              </button>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def tab_link(assigns) do
    ~H"""
    <.link
      navigate={@route}
      class={[
        "flex items-center border-b-2 px-1 py-4 text-sm font-medium",
        @active
          && "border-blue-500 text-blue-600 dark:border-blue-400 dark:text-blue-400",
        !@active
          && "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300 dark:hover:border-gray-500"
      ]}
    >
      <%= if @completed do %>
        <div class="mr-2 flex h-5 w-5 items-center justify-center rounded-full bg-green-100 text-green-600 dark:bg-green-900 dark:text-green-400">
          <svg class="h-3 w-3" fill="currentColor" viewBox="0 0 12 12">
            <path d="M3.707 5.293a1 1 0 00-1.414 1.414l1.414-1.414zM5 8l-.707.707a1 1 0 001.414 0L5 8zm4.707-3.293a1 1 0 00-1.414-1.414l1.414 1.414zm-7.414 2l2 2 1.414-1.414-2-2-1.414 1.414zm3.414 2l4-4-1.414-1.414-4 4 1.414 1.414z" />
          </svg>
        </div>
      <% end %>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp get_next_tab("sns_selection"), do: "photo_selection"
  defp get_next_tab("photo_selection"), do: "description"
  defp get_next_tab("description"), do: "preview"
  defp get_next_tab(_), do: nil

  defp get_prev_tab("photo_selection"), do: "sns_selection"
  defp get_prev_tab("description"), do: "photo_selection"
  defp get_prev_tab("preview"), do: "description"
  defp get_prev_tab(_), do: nil

  # Handle navigation between tabs
  @impl true
  def handle_event("navigate-tab", %{"tab" => tab}, socket) do
    {:noreply, push_patch(socket, to: ~p"/new_dashboard?tab=#{tab}")}
  end
end
