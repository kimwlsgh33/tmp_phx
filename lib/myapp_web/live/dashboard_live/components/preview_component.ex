defmodule MyappWeb.DashboardLive.Components.PreviewComponent do
  use MyappWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("goto-upload", _params, socket) do
    send(socket.assigns.parent_pid, :switch_to_upload_tab)
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    # Notify the parent to handle the upload
    Process.send_after(
      socket.assigns.parent_pid,
      {:upload_complete, socket.assigns.selected_platforms},
      1000
    )

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between items-center mb-6">
        <h2 class="text-xl font-semibold">Preview Your Post</h2>
        <div class="flex space-x-3">
          <button
            type="button"
            phx-click="goto-upload"
            phx-target={@myself}
            class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="-ml-1 mr-2 h-5 w-5 text-gray-500"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fill-rule="evenodd"
                d="M9.707 14.707a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 1.414L7.414 9H15a1 1 0 110 2H7.414l2.293 2.293a1 1 0 010 1.414z"
                clip-rule="evenodd"
              />
            </svg>
            Back to Edit
          </button>
          <button
            type="button"
            phx-click="save"
            phx-target={@myself}
            class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="-ml-1 mr-2 h-5 w-5"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fill-rule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-8.707l-3-3a1 1 0 00-1.414 0l-3 3a1 1 0 001.414 1.414L9 9.414V13a1 1 0 102 0V9.414l1.293 1.293a1 1 0 001.414-1.414z"
                clip-rule="evenodd"
              />
            </svg>
            Upload Now
          </button>
        </div>
      </div>

      <p class="text-gray-600 mb-6">
        Here's how your post will appear on each selected platform. Review to ensure everything looks correct before uploading.
      </p>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <%= for platform <- @selected_platforms do %>
          <div class="bg-white border rounded-lg overflow-hidden shadow-sm">
            {render_platform_preview(platform, assigns)}
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Platform preview templates
  defp render_platform_preview(:twitter, assigns) do
    ~H"""
    <div>
      <div class="p-4 border-b bg-white">
        <div class="flex items-start">
          <div class="flex-shrink-0">
            <div class="w-12 h-12 rounded-full bg-blue-400 flex items-center justify-center text-white font-bold">
              {String.at(@current_user.email, 0) |> String.upcase()}
            </div>
          </div>
          <div class="ml-3 flex-1">
            <div class="flex items-center">
              <p class="font-bold text-gray-900">
                {@current_user.email |> String.split("@") |> hd()}
              </p>
              <span class="ml-1 text-gray-500">
                @{@current_user.email |> String.split("@") |> hd()} · 1m
              </span>
            </div>
            <p class="mt-1 text-gray-800">{@upload_form["title"]}</p>
            <p class="mt-1 text-gray-600">{@upload_form["description"]}</p>

            <%= if @preview_url do %>
              <div class="mt-3 rounded-lg overflow-hidden border border-gray-200">
                <img src={@preview_url} alt="Content preview" class="w-full h-auto" />
              </div>
            <% else %>
              <div class="mt-3 rounded-lg overflow-hidden border border-gray-200 bg-gray-100 h-48 flex items-center justify-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-10 w-10 text-gray-400"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
                  />
                </svg>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <div class="p-4 bg-gray-50">
        <div class="text-sm font-medium text-gray-500">Twitter Preview</div>
        <div class="mt-2 text-sm text-gray-500">
          Tags: {if @upload_form["tags"] && @upload_form["tags"] != "",
            do: @upload_form["tags"],
            else: "No tags"}
        </div>
      </div>
    </div>
    """
  end

  defp render_platform_preview(:instagram, assigns) do
    ~H"""
    <div>
      <div class="border-b">
        <div class="p-3 flex items-center">
          <div class="flex-shrink-0">
            <div class="w-8 h-8 rounded-full bg-gradient-to-r from-purple-500 via-pink-500 to-red-500 flex items-center justify-center text-white font-bold text-xs">
              {String.at(@current_user.email, 0) |> String.upcase()}
            </div>
          </div>
          <div class="ml-3">
            <p class="text-sm font-bold">
              {@current_user.email |> String.split("@") |> hd()}
            </p>
          </div>
        </div>

        <div class="aspect-square">
          <%= if @preview_url do %>
            <img src={@preview_url} alt="Content preview" class="w-full h-auto" />
          <% else %>
            <div class="bg-gray-100 h-80 flex items-center justify-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-10 w-10 text-gray-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
                />
              </svg>
            </div>
          <% end %>
        </div>

        <div class="p-3">
          <p class="text-sm">{@upload_form["title"]}</p>
          <p class="text-xs text-gray-500 mt-1">{@upload_form["description"]}</p>
        </div>
      </div>

      <div class="p-4 bg-gray-50">
        <div class="text-sm font-medium text-gray-500">Instagram Preview</div>
        <div class="mt-2 text-sm text-gray-500">
          Tags: {if @upload_form["tags"] && @upload_form["tags"] != "",
            do: @upload_form["tags"],
            else: "No tags"}
        </div>
      </div>
    </div>
    """
  end

  defp render_platform_preview(:facebook, assigns) do
    ~H"""
    <div>
      <div class="p-4 border-b bg-white">
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <div class="w-10 h-10 rounded-full bg-blue-600 flex items-center justify-center text-white font-bold">
              {String.at(@current_user.email, 0) |> String.upcase()}
            </div>
          </div>
          <div class="ml-3">
            <p class="font-semibold text-gray-900">
              {@current_user.email |> String.split("@") |> hd()}
            </p>
            <p class="text-xs text-gray-500">
              Just now ·
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="inline h-3 w-3"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path d="M10 12a2 2 0 100-4 2 2 0 000 4z" />
              </svg>
            </p>
          </div>
        </div>

        <div class="aspect-square">
          <%= if @preview_url do %>
            <img src={@preview_url} alt="Content preview" class="w-full h-auto" />
          <% else %>
            <div class="bg-gray-100 h-80 flex items-center justify-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-10 w-10 text-gray-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a
                2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
                />
              </svg>
            </div>
          <% end %>
        </div>

        <div class="p-3">
          <p class="text-sm">{@upload_form["title"]}</p>
          <p class="text-xs text-gray-500 mt-1">{@upload_form["description"]}</p>
        </div>
      </div>

      <div class="p-4 bg-gray-50">
        <div class="text-sm font-medium text-gray-500">
          <svg
            class="inline-block h-5 w-5 mr-1 text-blue-600"
            fill="currentColor"
            viewBox="0 0 24 24"
            aria-hidden="true"
          >
            <path
              fill-rule="evenodd"
              d="M22 12c0-5.523-4.477-10-10-10S2 6.477 2 12c0 4.991 3.657 9.128 8.438 9.878v-6.987h-2.5
            4V12h2.54V9.797c0-2.506 1.492-3.89 3.777-3.89 1.094 0 2.238.195 2.238.195v2.46h-1.26c-1.243 0-1.63.771-1.63 1.562V12h2.773l-.443 2.89h-2.33v6.988C18.343 21.128 22 16.991 22 12z"
              clip-rule="evenodd"
            />
          </svg>
          Facebook Preview
        </div>
        <div class="mt-2 text-sm text-gray-500">
          Tags: {if @upload_form["tags"] && @upload_form["tags"] != "",
            do: @upload_form["tags"],
            else: "No tags"}
        </div>
      </div>
    </div>
    """
  end

  defp render_platform_preview(:youtube, assigns) do
    ~H"""
    <div>
      <div class="aspect-video bg-black flex items-center justify-center">
        <%= if @preview_url do %>
          <img src={@preview_url} alt="Video thumbnail" class="max-h-full max-w-full" />
        <% else %>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-16 w-16 text-gray-600"
            viewBox="0 0 20 20"
            fill="currentColor"
          >
            <path
              fill-rule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z"
              clip-rule="evenodd"
            />
          </svg>
        <% end %>
      </div>

      <div class="p-4 bg-gray-50">
        <div class="text-sm font-medium text-gray-500">
          <svg
            class="inline-block h-5 w-5 mr-1 text-red-600"
            fill="currentColor"
            viewBox="0 0 24 24"
            aria-hidden="true"
          >
            <path
              fill-rule="evenodd"
              d="M19.812 5.418c.861.23 1.538.907 1.768 1.768C21.998 8.746 22 12 22 12s0 3.255-.418 4.814 a2.504 2.504 0 0 1-1.768 1.768c-1.56.419-7.814.419-7.814.419s-6.255 0-7.814-.419a2.505 2.505 0 0 1-1.768-1.768C2 15.255 2 12 2 12s0-3.255.417-4.814a2.507 2.507 0 0 1 1.768-1.768C5.744 5 11.998 5 11.998 5s6.255 0 7.814.418ZM15.194 12 10 15V9l5.194 3Z"
              clip-rule="evenodd"
            />
          </svg>
          YouTube Preview
        </div>
        <div class="mt-2 text-sm text-gray-500">
          Tags: {if @upload_form["tags"] && @upload_form["tags"] != "",
            do: @upload_form["tags"],
            else: "No tags"}
        </div>
      </div>
    </div>
    """
  end

  defp render_platform_preview(:tiktok, assigns) do
    ~H"""
    <div>
      <div class="bg-gray-800 aspect-[9/16] flex items-center justify-center">
        <%= if @preview_url do %>
          <img src={@preview_url} alt="Video thumbnail" class="max-h-full max-w-full" />
        <% else %>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-16 w-16 text-gray-500"
            viewBox="0 0 24 24"
            fill="currentColor"
          >
            <path
              fill-rule="evenodd"
              d="M19.812 5.418c.861.23 1.538.907 1.768 1.768C21.998 8.746 22 12 22 12s0 3.255-.418 4.814 a2.504 2.504 0 0 1-1.768 1.768c-1.56.419-7.814.419-7.814.419s-6.255 0-7.814-.419a2.505 2.505 0 0 1-1.768-1.768C2 15.255 2 12 2 12s0-3.255.417-4.814a2.507 2.507 0 0 1 1.768-1.768C5.744 5 11.998 5 11.998 5s6.255 0 7.814.418ZM15.194 12 10 15V9l5.194 3Z"
              clip-rule="evenodd"
            />
          </svg>
        <% end %>
      </div>

      <div class="p-4 bg-gray-50">
        <div class="text-sm font-medium text-gray-500">TikTok Preview</div>
        <div class="mt-2 text-sm text-gray-500">
          Tags: {if @upload_form["tags"] && @upload_form["tags"] != "",
            do: @upload_form["tags"],
            else: "No tags"}
        </div>
      </div>
    </div>
    """
  end

  defp render_platform_preview(platform, assigns) do
    ~H"""
    <div class="p-4">
      <p class="text-gray-500">
        Preview for {platform |> Atom.to_string() |> String.capitalize()} not available
      </p>
    </div>
    """
  end
end
