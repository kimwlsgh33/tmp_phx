defmodule MyappWeb.ConsolidatedUploadLive do
  use MyappWeb, :live_view

  alias MyappWeb.Upload.{PostComponent, ShortVideoComponent, LongVideoComponent}

  @impl true
  def mount(_params, session, socket) do
    case MyappWeb.Auth.verify_session(session) do
      {:ok, user} ->
        active_tab = Map.get(_params, "tab", "post")
        
        {:ok,
         socket
         |> assign(:current_user, user)
         |> assign(:page_title, "Upload Content")
         |> assign(:active_tab, active_tab)
         |> assign(:upload_error, nil)}

      {:error, _reason} ->
        {:ok,
         socket
         |> put_flash(:error, "Please login to continue")
         |> redirect(to: ~p"/login")}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    active_tab = Map.get(params, "tab", socket.assigns.active_tab)
    {:noreply, assign(socket, :active_tab, active_tab)}
  end

  @impl true
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
        <%= if @upload_error do %>
          <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative mb-4" role="alert">
            <span class="block sm:inline"><%= @upload_error %></span>
          </div>
        <% end %>

        <%= case @active_tab do %>
          <% "post" -> %>
            <.live_component 
              module={PostComponent}
              id="post-upload"
              current_user={@current_user} />
          <% "short" -> %>
            <.live_component 
              module={ShortVideoComponent}
              id="short-upload"
              current_user={@current_user} />
          <% "long" -> %>
            <.live_component 
              module={LongVideoComponent}
              id="long-upload"
              current_user={@current_user} />
        <% end %>
      </div>
    </div>
    """
  end

  # Handle authentication refresh
  def handle_info({:token_refresh_required, reason}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "Please login again: #{reason}")
     |> redirect(to: ~p"/login")}
  end

  # Handle upload errors from components
  def handle_info({:upload_error, error_message}, socket) do
    {:noreply, assign(socket, :upload_error, error_message)}
  end
end

