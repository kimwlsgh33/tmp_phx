defmodule MyappWeb.DashboardLive do
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

  @social_platforms [:twitter, :instagram, :tiktok, :youtube, :facebook]

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
     |> assign(:page_title, "Social Media Dashboard")
     |> assign(:active_tab, "sns_selection")
     |> assign(:social_accounts, %{})
     |> assign(:loading_accounts, true)
     |> assign(:loading_uploads, true)
     |> assign(:recent_uploads, [])
     |> assign(:selected_platforms, [])
     |> assign(:preview_url, nil)
     |> assign(:scheduled_upload, false)  # Track if schedule for later is enabled
     |> assign(:completed_tabs, [])  # Track completed tabs for checkmarks
     |> assign(:upload_form, %{
       "title" => "",
       "description" => "",
       "tags" => "",
       "schedule_at" => nil,
       "schedule_date" => "",
       "schedule_time" => elem(get_current_formatted_time(), 0)
     })
     |> assign(:selected_time_period, elem(get_current_formatted_time(), 1))
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
      |> push_patch(to: ~p"/dashboard?tab=photo_selection")}
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
      |> push_patch(to: ~p"/dashboard?tab=description")}
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

  @impl true
  def handle_info(:switch_to_file_selection_tab, socket) do
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
      |> push_patch(to: ~p"/dashboard?tab=photo_selection")}
  end

  @impl true
  def handle_info(:switch_to_sns_selection_tab, socket) do
    # Mark description as completed when moving to sns_selection
    completed_tabs =
      if socket.assigns.active_tab == "description" && "description" not in socket.assigns.completed_tabs do
        ["description" | socket.assigns.completed_tabs]
      else
        socket.assigns.completed_tabs
      end

    {:noreply,
      socket
      |> assign(:completed_tabs, completed_tabs)
      |> push_patch(to: ~p"/dashboard?tab=sns_selection")}
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
      |> push_patch(to: ~p"/dashboard?tab=preview")}
  end



  @impl true
  def handle_info({:update_form, form_data}, socket) do
    {:noreply,
     socket
     |> assign(:upload_form, form_data)}
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
    # This is our new handler for messages sent by the Facebook/Twitter components
    # Convert the new format to existing format and use the existing handler

    # Create a map with the platform as key and settings as value
    # This matches the format expected by the original update_advanced_settings
    platform_settings = %{platform => settings}

    # Log what we're updating to help with debugging
    IO.inspect(platform_settings, label: "SNS Advanced Settings Update")

    # Merge the new settings with existing settings
    updated_settings = Map.merge(socket.assigns.advanced_settings, platform_settings)

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
  def handle_info({:update_preview, preview_url}, socket) do
    IO.puts("Updating preview URL to: #{preview_url}")
    {:noreply,
     socket
     |> assign(:preview_url, preview_url)}
  end

  @impl true
  def handle_info(:load_saved_settings, socket) do
    if socket.assigns.current_user do
      user_id = socket.assigns.current_user.id
      push_event(socket, "load_settings", %{key: "user_#{user_id}_advanced_settings"})
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("settings_loaded", %{"value" => settings_json}, socket) do
    case Jason.decode(settings_json) do
      {:ok, settings} ->
        {:noreply, assign(socket, :advanced_settings, settings)}
      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:update_selected_platforms, platforms}, socket) do
    {:noreply,
     socket
     |> assign(:selected_platforms, platforms)}
  end

  @impl true
  def handle_info({:update_social_accounts, accounts}, socket) do
    {:noreply, assign(socket, social_accounts: accounts)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    active_tab = Map.get(params, "tab", socket.assigns.active_tab)
    {:noreply, assign(socket, :active_tab, active_tab)}
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
  def handle_event("disconnect-platform", %{"platform" => platform}, socket) do
    platform = String.to_existing_atom(platform)

    # In a real implementation, we would revoke the tokens for this platform
    # For now, just update the UI
    updated_accounts =
      Map.update!(
        socket.assigns.social_accounts,
        platform,
        fn status -> %{status | connected: false} end
      )

    # Also remove it from selected platforms if it was selected
    updated_platforms =
      Enum.reject(
        socket.assigns.selected_platforms,
        fn p -> p == platform end
      )

    {:noreply,
     socket
     |> assign(:social_accounts, updated_accounts)
     |> assign(:selected_platforms, updated_platforms)
     |> put_flash(
       :info,
       "Disconnected from #{platform |> Atom.to_string() |> String.capitalize()}"
     )}
  end

  @impl true
  def handle_info(:load_social_accounts, socket) do
    # In a real implementation, we would fetch the actual connection status
    # for each platform from the database or API
    social_accounts =
      Enum.into(@social_platforms, %{}, fn platform ->
        # Generate multiple accounts per platform (for demo purposes)
        accounts = if Enum.random([true, false]) do
          account_count = Enum.random(1..3)
          Enum.map(1..account_count, fn i ->
            %{
              id: "#{platform}-#{i}",
              username: "#{platform}_user_#{i}",
              avatar: "/images/avatar-placeholder.png",
              connected: true,
              selected: i == 1 # Default select the first account for each platform
            }
          end)
        else
          []
        end

        {platform, accounts}
      end)

    {:noreply,
     socket
     |> assign(:social_accounts, social_accounts)
     |> assign(:loading_accounts, false)}
  end

  @impl true
  def handle_info(:load_recent_uploads, socket) do
    # In a real implementation, we would fetch recent uploads from the database
    recent_uploads = [
      %{
        id: "1",
        timestamp: ~N[2025-04-05 10:30:00],
        platforms: [:twitter, :instagram],
        status: :success,
        links: %{
          twitter: "https://twitter.com/user/status/123456789",
          instagram: "https://instagram.com/p/ABC123"
        }
      },
      %{
        id: "2",
        timestamp: ~N[2025-04-04 15:45:00],
        platforms: [:youtube],
        status: :processing,
        links: %{
          youtube: nil
        }
      },
      %{
        id: "3",
        timestamp: ~N[2025-04-03 09:15:00],
        platforms: [:tiktok, :facebook],
        status: :failed,
        links: %{},
        error: "Upload failed: invalid token"
      }
    ]

    {:noreply,
     socket
     |> assign(:recent_uploads, recent_uploads)
     |> assign(:loading_uploads, false)}
  end

  @impl true
  def handle_info({:load_social_accounts_for_schedule, pid}, socket) do
    if socket.assigns.loading_accounts do
      # If we're still loading accounts, we'll send a message when done
      Process.send_after(self(), {:send_social_accounts_to_component, pid}, 100)
    else
      # If accounts are loaded, send them right away
      send(pid, {:social_accounts_loaded, socket.assigns.social_accounts})
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:send_social_accounts_to_component, pid}, socket) do
    send(pid, {:social_accounts_loaded, socket.assigns.social_accounts})
    {:noreply, socket}
  end

  @impl true
  def handle_info({:upload_complete, platforms}, socket) do
    # In a real implementation, we would update the database with the results
    # and fetch the updated recent uploads list

    platform_names =
      Enum.map_join(platforms, ", ", fn p ->
        p |> Atom.to_string() |> String.capitalize()
      end)

    {:noreply,
     socket
     |> put_flash(:info, "Upload complete! Posted to #{platform_names}")
     |> push_patch(to: ~p"/dashboard?tab=results")}
  end

  @impl true
  def handle_info({:schedule_complete, platforms, scheduled_time, country}, socket) do
    # In a real implementation, we would save the schedule to the database

    platform_names =
      Enum.map_join(platforms, ", ", fn p ->
        p |> Atom.to_string() |> String.capitalize()
      end)

    {:noreply,
     socket
     |> put_flash(:info, "Content scheduled for #{platform_names} at #{scheduled_time} (#{country})")
     |> push_patch(to: ~p"/dashboard?tab=results")}
  end

  # For backward compatibility
  @impl true
  def handle_info({:schedule_complete, platforms, scheduled_time}, socket) do
    # In a real implementation, we would save the schedule to the database

    platform_names =
      Enum.map_join(platforms, ", ", fn p ->
        p |> Atom.to_string() |> String.capitalize()
      end)

    {:noreply,
     socket
     |> put_flash(:info, "Content scheduled for #{platform_names} at #{scheduled_time}")
     |> push_patch(to: ~p"/dashboard?tab=results")}
  end

  @impl true
  def handle_info({:retry_upload, id}, socket) do
    # In a real implementation, we would retry the upload
    # For now, just show a flash message

    {:noreply,
     socket
     |> put_flash(:info, "Retrying upload ##{id}...")}
  end

  @impl true
  def handle_info({:social_accounts_loaded, _accounts}, socket) do
    # This message is meant for ScheduleComponent, just ignore it if received by the LiveView
    {:noreply, socket}
  end

  @impl true
  def handle_info({:update_scheduled_upload, scheduled_upload}, socket) do
    # Update the scheduled upload status in the socket
    {:noreply, assign(socket, :scheduled_upload, scheduled_upload)}
  end

  @impl true
  def handle_info({:calendar_time_updated, time, period, country}, socket) do
    # Update form with time and country from calendar without date
    upload_form = Map.merge(socket.assigns.upload_form, %{
      "schedule_time" => time,
    })

    # Update the socket with the new values
    socket = socket
      |> assign(:upload_form, upload_form)
      |> assign(:selected_time_period, period)

    {:noreply, socket}
  end

  def handle_info({:calendar_date_selected, datetime, country}, socket) do
    # Forward the message to the SNS selection component with country
    send_update(MyappWeb.DashboardLive.Components.UploadTabs.SnsSelectionComponent,
      id: "sns-selection",
      selected_date: datetime,
      selected_country: country
    )
    {:noreply, socket}
  end

  # Backward compatibility for older calendar component messages
  @impl true
  def handle_info({:calendar_date_selected, datetime}, socket) do
    # Forward the message to the SNS selection component without country
    send_update(MyappWeb.DashboardLive.Components.UploadTabs.SnsSelectionComponent,
      id: "sns-selection",
      selected_date: datetime
    )
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="dashboard" class="flex flex-col min-h-screen bg-white dark:bg-black" phx-hook="SettingsStorage">
      <div class="flex-1">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-6">
          <div class="mb-6 flex justify-between items-center">
            <div>
              <h1 class="text-2xl font-bold text-black dark:text-gray-300">Social Media Dashboard</h1>
              <p class="text-gray-400 dark:text-gray-300">Manage your content across multiple platforms</p>
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

    <!-- Tabs Navigation -->
          <div class="mb-6">
            <nav class="flex items-center justify-center space-x-6 mb-6">
              <%= for {step, idx, label, icon_render} <- [
                {"sns_selection", 1, "Choose Platforms", fn _ -> render_platform_icons(%{}) end},
                {"photo_selection", 2, "Select Files", fn _ -> render_file_icon(%{}) end},
                {"description", 3, "Add Details", fn _ -> render_description_icon(%{}) end},
                {"preview", 4, "Preview", fn _ -> render_preview_icon(%{}) end}
              ] do %>
                <button type="button" phx-click={JS.patch(~p"/dashboard?tab=#{step}")} class="flex items-center space-x-2">
                  <div class={"w-8 h-8 rounded-full flex items-center justify-center " <> if @active_tab == step, do: "border border-orange-600 dark:border-orange-700 dark:text-white", else: "bg-gray-200 dark:bg-dark-800 text-gray-500 dark:text-gray-400"}>
                    <%= if step in @completed_tabs do %>
                      <!-- Check mark icon -->
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                        <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                      </svg>
                    <% else %>
                      <%= idx %>
                    <% end %>
                  </div>
                  <div class="flex flex-col items-start">
                    <span class={"text-sm uppercase font-medium " <> if @active_tab == step, do: "text-black dark:text-gray-300 font-semibold", else: "text-gray-500 dark:text-gray-400"}>
                      <%= label %>
                    </span>
                    <div class={"flex items-center mt-1 " <> if @active_tab == step, do: "text-primary-600 dark:text-primary-500", else: "text-gray-400 dark:text-gray-500"}>
                      <%= icon_render.(%{}) %>
                    </div>
                  </div>
                </button>
                <%= if idx < 4 do %>
                  <div class="flex-1 h-px bg-gray-200 dark:bg-dark-800 mx-2"></div>
                <% end %>
              <% end %>
            </nav>
          </div>

    <!-- Tab Content -->
          <div class="flex items-center justify-between">
            <!-- Previous tab button (left) -->
            <%= if get_prev_tab(@active_tab) do %>
              <button
                type="button"
                phx-click={JS.patch(~p"/dashboard?tab=#{get_prev_tab(@active_tab)}")}
                class="absolute left-4 sm:left-6 lg:left-8 flex items-center justify-center h-12 w-12 text-gray-700 dark:text-gray-300 hover:text-black dark:hover:text-white hover:bg-gray-100 dark:hover:bg-dark-800 rounded-full transition-colors z-10"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clip-rule="evenodd" />
                </svg>
              </button>
            <% end %>

            <!-- Component Content (full width) -->
            <div class="bg-white dark:bg-black rounded-lg shadow-md p-6 w-full border border-gray-100 dark:border-gray-800">
              <%= case @active_tab do %>
                <% "photo_selection" -> %>
                  <.live_component
                    module={PhotoSelectionComponent}
                    id="photo-selection"
                    current_user={@current_user}
                    parent_pid={self()}
                    upload_progress={0}
                    preview_url={@preview_url}
                    selected_platforms={@selected_platforms}
                  />
                <% "description" -> %>
                  <.live_component
                    module={DescriptionComponent}
                    id="description"
                    current_user={@current_user}
                    parent_pid={self()}
                    upload_form={@upload_form}
                    selected_platforms={@selected_platforms}
                    advanced_settings={@advanced_settings}
                  />
                <% "sns_selection" -> %>
                  <.live_component
                    module={SnsSelectionComponent}
                    id="sns-selection"
                    current_user={@current_user}
                    parent_pid={self()}
                    social_accounts={@social_accounts}
                    selected_platforms={@selected_platforms}
                    upload_form={@upload_form}
                  />
                <% "preview" -> %>
                  <.live_component
                    module={PreviewComponent}
                    id="preview"
                    selected_platforms={@selected_platforms}
                    preview_url={@preview_url}
                    upload_form={@upload_form}
                    advanced_settings={@advanced_settings}
                    parent_pid={self()}
                  />
              <% end %>
            </div>

            <!-- Next tab button (right) -->
            <%= if get_next_tab(@active_tab) do %>
              <button
                type="button"
                phx-click={JS.patch(~p"/dashboard?tab=#{get_next_tab(@active_tab)}")}
                disabled={!Map.get(@validation_states, @active_tab, false)}
                class={[
                  "absolute right-4 sm:right-6 lg:right-8 flex items-center justify-center h-12 w-12 rounded-full transition-colors z-10",
                  if Map.get(@validation_states, @active_tab, false) do
                    "text-primary-600 dark:text-primary-500 hover:text-primary-800 dark:hover:text-primary-400 hover:bg-primary-50 dark:hover:bg-primary-900/50"
                  else
                    "text-gray-400 dark:text-gray-600 cursor-not-allowed"
                  end
                ]}
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd" />
                </svg>
              </button>
            <% else %>
              <div class="w-12 flex-shrink-0"></div> <!-- Placeholder to maintain layout -->
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
      patch={@patch}
      class={"px-4 py-2 font-medium #{if @active, do: "border-b-2 border-primary-600 dark:border-primary-500 text-primary-600 dark:text-primary-500", else: "text-gray-500 dark:text-gray-400 hover:text-primary-600 dark:hover:text-primary-500"}"}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp platform_color(platform) do
    case platform do
      :twitter -> "bg-blue-500"
      :instagram -> "bg-pink-600"
      :facebook -> "bg-blue-700"
      :youtube -> "bg-red-600"
      :tiktok -> "bg-black"
      # Default color
      _ -> "bg-gray-600"
    end
  end

  # 탭 제목에 표시할 SNS 플랫폼 로고들을 렌더링하는 함수
  def render_platform_icons(assigns) do
    ~H"""
    <div class="flex space-x-1">
      <!-- X (Twitter) 로고 -->
      <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor" class="dark:text-white">
        <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
      </svg>

      <!-- Instagram 로고 -->
      <svg class="w-4 h-4" viewBox="0 0 24 24">
        <linearGradient id="instagram-gradient" x1="0%" y1="100%" x2="100%" y2="0%">
          <stop offset="0%" stop-color="#FFDC80" />
          <stop offset="10%" stop-color="#FCAF45" />
          <stop offset="50%" stop-color="#F77737" />
          <stop offset="70%" stop-color="#F56040" />
          <stop offset="80%" stop-color="#FD1D1D" />
          <stop offset="90%" stop-color="#E1306C" />
          <stop offset="100%" stop-color="#C13584" />
        </linearGradient>
        <path fill="url(#instagram-gradient)" d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/>
      </svg>

      <!-- TikTok 로고 -->
      <svg class="w-4 h-4 text-black dark:text-white" viewBox="0 0 24 24" fill="currentColor">
        <path d="M19.59 6.69a4.83 4.83 0 01-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 01-5.2 1.74 2.89 2.89 0 012.31-4.64 2.93 2.93 0 01.88.13V9.4a6.84 6.84 0 00-1-.05A6.33 6.33 0 005 20.1a6.34 6.34 0 0010.86-4.43v-7a8.16 8.16 0 004.77 1.52v-3.4a4.85 4.85 0 01-1-.1z"/>
      </svg>

      <!-- Facebook 로고 -->
      <svg class="w-4 h-4 text-[#1877F2] dark:text-white" viewBox="0 0 24 24" fill="currentColor">
        <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
      </svg>

      <!-- YouTube 로고 -->
      <svg class="w-4 h-4" viewBox="0 0 24 24" fill="#FF0000">
        <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
      </svg>
    </div>
    """
  end

  # 파일 및 미디어를 위한 아이콘
  def render_file_icon(assigns) do
    ~H"""
    <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
      <path d="M4 5h16v14H4V5zm11 10l2.5-1.5L20 15V5H4v14l5-3l3 2l3-3z"></path>
      <circle cx="15.5" cy="8.5" r="1.5"></circle>
    </svg>
    """
  end

  # 설명 추가를 위한 아이콘
  def render_description_icon(assigns) do
    ~H"""
    <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
      <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z"></path>
    </svg>
    """
  end

  # 미리보기를 위한 아이콘
  def render_preview_icon(assigns) do
    ~H"""
    <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z"></path>
    </svg>
    """
  end

  # Helper functions to determine previous and next tabs
  defp get_prev_tab(current_tab) do
    tab_order = ["sns_selection", "photo_selection", "description", "preview"]
    current_idx = Enum.find_index(tab_order, fn tab -> tab == current_tab end)

    if current_idx && current_idx > 0 do
      Enum.at(tab_order, current_idx - 1)
    else
      nil
    end
  end

  defp get_next_tab(current_tab) do
    tab_order = ["sns_selection", "photo_selection", "description", "preview"]
    current_idx = Enum.find_index(tab_order, fn tab -> tab == current_tab end)

    if current_idx && current_idx < length(tab_order) - 1 do
      Enum.at(tab_order, current_idx + 1)
    else
      nil
    end
  end

  # Helper function to get current time formatted as HH:MM based on Korea time (UTC+9)
  defp get_current_formatted_time(country \\ "Korea") do
    # Get UTC time
    now = Time.utc_now()
    {hours, minutes, _} = {now.hour, now.minute, now.second}

    # Apply timezone offset based on country
    hours = case country do
      "Korea" -> rem(hours + 9, 24)  # UTC+9
      "Japan" -> rem(hours + 9, 24)  # UTC+9
      "China" -> rem(hours + 8, 24)  # UTC+8
      "USA" ->
        # Handle negative hours properly
        us_hours = hours - 5
        if us_hours < 0, do: us_hours + 24, else: us_hours
      _ -> rem(hours + 9, 24)        # Default to Korea time
    end

    # Convert to 12-hour format
    period = if hours >= 12, do: "PM", else: "AM"
    formatted_hour = rem(hours, 12)
    formatted_hour = if formatted_hour == 0, do: 12, else: formatted_hour

    # Format time as HH:MM
    {
      String.pad_leading(Integer.to_string(formatted_hour), 2, "0") <> ":" <>
      String.pad_leading(Integer.to_string(minutes), 2, "0"),
      period
    }
  end
end
