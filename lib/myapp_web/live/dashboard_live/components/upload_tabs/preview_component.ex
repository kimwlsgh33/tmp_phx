defmodule MyappWeb.DashboardLive.Components.UploadTabs.PreviewComponent do
  use MyappWeb, :live_component
  alias MyappWeb.DashboardLive.Components.UploadTabs.SnsPreview

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:selected_platforms, fn -> [] end)
      |> assign_new(:preview_url, fn -> nil end)
      |> assign_new(:upload_form, fn -> %{} end)

    {:ok, socket}
  end

  @impl true
  def handle_event("goto-description", _params, socket) do
    send(socket.assigns.parent_pid, :switch_to_description_tab)
    {:noreply, socket}
  end

  @impl true
  def handle_event("goto-sns-selection", _params, socket) do
    send(socket.assigns.parent_pid, :switch_to_sns_selection_tab)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-[600px]">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
        <%= for platform <- @selected_platforms do %>
          <%= case platform do %>
            <% :tiktok -> %>
              <.live_component
                module={SnsPreview.TiktokComponent}
                id="tiktok-preview"
                preview_url={@preview_url}
                upload_form={@upload_form}
              />
            <% :youtube -> %>
              <.live_component
                module={SnsPreview.YoutubeComponent}
                id="youtube-preview"
                preview_url={@preview_url}
                upload_form={@upload_form}
              />
            <% :instagram -> %>
              <.live_component
                module={SnsPreview.InstagramComponent}
                id="instagram-preview"
                preview_url={@preview_url}
                upload_form={@upload_form}
              />
            <% :twitter -> %>
              <.live_component
                module={SnsPreview.TwitterComponent}
                id="twitter-preview"
                preview_url={@preview_url}
                upload_form={@upload_form}
              />
            <% :facebook -> %>
              <.live_component
                module={SnsPreview.FacebookComponent}
                id="facebook-preview"
                preview_url={@preview_url}
                upload_form={@upload_form}
              />
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end
