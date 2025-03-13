defmodule MyappWeb.UploadLive do
  use MyappWeb, :live_view

  def mount(params, _session, socket) do
    # Set the active tab based on URL params or default to "post"
    active_tab = Map.get(params, "tab", "post")
    
    {:ok,
     socket
     |> assign(:page_title, "Upload Content")
     |> assign(:active_tab, active_tab)}
  end

  def handle_params(params, _uri, socket) do
    active_tab = Map.get(params, "tab", socket.assigns.active_tab)
    {:noreply, assign(socket, :active_tab, active_tab)}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4">
      <h1 class="text-2xl font-bold mb-4">Upload Content</h1>
      
      <div class="mb-6">
        <nav class="flex border-b">
          <.link 
            patch={~p"/upload?tab=post"}
            class={"px-4 py-2 font-medium #{if @active_tab == "post", do: "border-b-2 border-blue-500 text-blue-500", else: "text-gray-500 hover:text-blue-500"}"}>
            Post
          </.link>
          <.link 
            patch={~p"/upload?tab=short"}
            class={"px-4 py-2 font-medium #{if @active_tab == "short", do: "border-b-2 border-blue-500 text-blue-500", else: "text-gray-500 hover:text-blue-500"}"}>
            Short Video
          </.link>
          <.link 
            patch={~p"/upload?tab=long"}
            class={"px-4 py-2 font-medium #{if @active_tab == "long", do: "border-b-2 border-blue-500 text-blue-500", else: "text-gray-500 hover:text-blue-500"}"}>
            Long Video
          </.link>
        </nav>
      </div>

      <div class="content">
        <%= case @active_tab do %>
          <% "post" -> %>
            <.live_component module={MyappWeb.Upload.PostComponent} id="post-upload" />
          <% "short" -> %>
            <.live_component module={MyappWeb.Upload.ShortComponent} id="short-upload" />
          <% "long" -> %>
            <.live_component module={MyappWeb.Upload.LongComponent} id="long-upload" />
        <% end %>
      </div>
    </div>
    """
  end

  # This is no longer needed since we're using links with patch
  # def handle_event("set-tab", %{"tab" => tab}, socket) do
  #   {:noreply, 
  #    socket
  #    |> assign(:active_tab, tab)
  #    |> push_patch(to: ~p"/upload?tab=#{tab}")}
  # end
end