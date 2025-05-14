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
     |> assign(:completed_tabs, [])  # Track completed tabs for checkmarks
     |> assign(:upload_form, %{
       "title" => "",
       "description" => "",
       "tags" => "",
       "schedule_at" => nil
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
    # Mark sns_selection as completed when moving to preview
    completed_tabs =
      if socket.assigns.active_tab == "sns_selection" && "sns_selection" not in socket.assigns.completed_tabs do
        ["sns_selection" | socket.assigns.completed_tabs]
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
  def handle_info({:update_preview, preview_url}, socket) do
    IO.puts("Updating preview URL to: #{preview_url}")
    {:noreply,
     socket
     |> assign(:preview_url, preview_url)}
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
  def render(assigns) do
    ~H"""
    <div id="dashboard" class="flex flex-col min-h-screen bg-white">
      <div class="flex-1">
        <div class="p-6">
          <div class="mb-6 flex justify-between items-center">
            <div>
              <h1 class="text-2xl font-bold text-black">Social Media Dashboard</h1>
              <p class="text-gray-400">Manage your content across multiple platforms</p>
            </div>
            <div>
              <.link
                navigate={~p"/sns-accounts"}
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
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
              <%= for {step, idx, label} <- [
                {"sns_selection", 1, "Choose Platforms"},
                {"photo_selection", 2, "Select Files"},
                {"description", 3, "Add Details"},
                {"preview", 4, "Preview"}
              ] do %>
                <button type="button" phx-click={JS.patch(~p"/dashboard?tab=#{step}")} class="flex items-center space-x-2">
                  <div class={"w-8 h-8 rounded-full flex items-center justify-center " <> if @active_tab == step, do: "bg-black text-white", else: "bg-gray-200 text-gray-500"}>
                    <%= if step in @completed_tabs do %>
                      <!-- Check mark icon -->
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                        <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                      </svg>
                    <% else %>
                      <%= idx %>
                    <% end %>
                  </div>
                  <span class={"text-sm uppercase " <> if @active_tab == step, do: "text-black font-semibold", else: "text-gray-500"}>
                    <%= label %>
                  </span>
                </button>
                <%= if idx < 4 do %>
                  <div class="flex-1 h-px bg-gray-200 mx-2"></div>
                <% end %>
              <% end %>
            </nav>
          </div>

    <!-- Tab Content -->
          <div class="bg-white rounded-lg shadow-md p-6">
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
                  current_user={@current_user}
                  parent_pid={self()}
                  selected_platforms={@selected_platforms}
                  preview_url={@preview_url}
                  upload_form={@upload_form}
                />
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
      class={"px-4 py-2 font-medium #{if @active, do: "border-b-2 border-indigo-600 text-indigo-600", else: "text-gray-500 hover:text-indigo-600"}"}
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
end
