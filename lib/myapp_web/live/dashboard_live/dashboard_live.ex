defmodule MyappWeb.DashboardLive do
  use MyappWeb, :live_view

  alias MyappWeb.DashboardLive.Components.{
    UploadComponent,
    PreviewComponent,
    ResultsComponent,
    SettingsComponent
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
     |> assign(:active_tab, "upload")
     |> assign(:social_accounts, %{})
     |> assign(:loading_accounts, true)
     |> assign(:loading_uploads, true)
     |> assign(:recent_uploads, [])
     |> assign(:selected_platforms, [])
     |> assign(:preview_url, nil)
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
  def handle_info(:switch_to_upload_tab, socket) do
    {:noreply, push_patch(socket, to: ~p"/dashboard?tab=upload")}
  end


  @impl true
  def handle_info(:switch_to_preview_tab, socket) do
    {:noreply, push_patch(socket, to: ~p"/dashboard?tab=preview")}
  end

  @impl true
  def handle_info({:update_preview, preview_url}, socket) do
    {:noreply, assign(socket, :preview_url, preview_url)}
  end

  @impl true
  def handle_info(:switch_to_results_tab, socket) do
    {:noreply, push_patch(socket, to: ~p"/dashboard?tab=results")}
  end

  @impl true
  def handle_info({:update_form, form_data}, socket) do
    {:noreply,
     socket
     |> assign(:upload_form, form_data)}
  end

  @impl true
  def handle_info({:update_preview, preview_url}, socket) do
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
        # This is just a placeholder. In a real app, you would check if the
        # user is authenticated with each platform
        connected = Enum.random([true, false])
        {platform, %{connected: connected}}
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
          <div class="mb-6">
            <h1 class="text-2xl font-bold text-black">Social Media Dashboard</h1>
            <p class="text-gray-400">Manage your content across multiple platforms</p>
          </div>

    <!-- Tabs Navigation -->
          <div class="mb-6">
            <nav class="flex border-b border-black">
              <.tab_link patch={~p"/dashboard?tab=upload"} active={@active_tab == "upload"}>
                Upload
              </.tab_link>
              <.tab_link patch={~p"/dashboard?tab=settings"} active={@active_tab == "settings"}>
                SNS Settings
              </.tab_link>

              <.tab_link patch={~p"/dashboard?tab=results"} active={@active_tab == "results"}>
                Results
              </.tab_link>
              <.tab_link patch={~p"/dashboard?tab=preview"} active={@active_tab == "preview"}>
                Preview
              </.tab_link>
            </nav>
          </div>

    <!-- Tab Content -->
          <div class="bg-white rounded-lg shadow-md p-6">
            <%= case @active_tab do %>
              <% "upload" -> %>
                <.live_component
                  module={UploadComponent}
                  id="upload-form"
                  current_user={@current_user}
                  parent_pid={self()}
                  social_accounts={@social_accounts}
                  selected_platforms={@selected_platforms}
                  upload_form={@upload_form}
                  preview_url={@preview_url}
                />
              <% "preview" -> %>
                <.live_component
                  module={PreviewComponent}
                  id="preview"
                  current_user={@current_user}
                  parent_pid={self()}
                  selected_platforms={@selected_platforms}
                  upload_form={@upload_form}
                  preview_url={@preview_url}
                />
              <% "results" -> %>
                <.live_component
                  module={ResultsComponent}
                  id="results"
                  current_user={@current_user}
                  parent_pid={self()}
                  recent_uploads={@recent_uploads}
                />
              <% "settings" -> %>
                <.live_component
                  module={SettingsComponent}
                  id="settings"
                  current_user={@current_user}
                  parent_pid={self()}
                  social_accounts={@social_accounts}
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
