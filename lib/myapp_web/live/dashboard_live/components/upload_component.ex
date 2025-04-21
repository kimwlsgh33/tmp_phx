defmodule MyappWeb.DashboardLive.Components.UploadComponent do
  use MyappWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:upload_progress, 0)
     |> assign(:processing_filename, nil)
     |> assign(:preview_url, nil)
     |> assign(:upload_form, %{
       "title" => "",
       "description" => "",
       "tags" => ""
     })
     |> allow_upload(:video,
       accept: ~w(.mp4 .mov .avi .wmv .flv .webm),
       max_entries: 1,
       max_file_size: 500_000_000,
       progress: &handle_progress/3
     )}
  end

  @impl true
  def update(assigns, socket) do
    # Update the component state and allow uploads on each render
    socket =
      socket
      |> assign_new(:processing_filename, fn -> nil end)
      |> assign(assigns)
      |> allow_upload(:video,
         accept: ~w(.mp4 .mov .avi .wmv .flv .webm),
         max_entries: 1,
         max_file_size: 500_000_000,
         progress: &handle_progress/3
      )

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
  def handle_event("save", %{"upload_form" => form_params}, socket) do
    if socket.assigns.selected_platforms == [] do
      {:noreply,
       socket
       |> put_flash(:error, "Please select at least one social media platform")}
    else
      # In real implementation, we would handle the upload here
      Process.send_after(
        socket.assigns.parent_pid,
        {:upload_complete, socket.assigns.selected_platforms},
        1000
      )

      {:noreply,
       socket
       |> put_flash(:info, "Content uploading to selected platforms...")}
    end
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :video, ref)}
  end

  @impl true
  def handle_event("goto-schedule", _params, socket) do
    send(socket.assigns.parent_pid, :switch_to_schedule_tab)
    {:noreply, socket}
  end

  @impl true
  def handle_event("goto-preview", _params, socket) do
    send(socket.assigns.parent_pid, :switch_to_preview_tab)
    {:noreply, socket}
  end

  @impl true
  def handle_event("processing", %{"filename" => filename}, socket) do
    {:noreply,
     socket
     |> assign(:processing_filename, filename)
     |> assign(:upload_progress, 0)}
  end

  @impl true
  def handle_event("client_upload_complete", %{"url" => url}, socket) do
    # update preview and mark progress complete
    send(socket.assigns.parent_pid, {:update_preview, url})
    {:noreply,
     socket
     |> assign(:preview_url, url)
     |> assign(:upload_progress, 100)}
  end

  @impl true
  def handle_event("upload-progress", %{"pct" => pct}, socket) do
    {:noreply, assign(socket, :upload_progress, pct)}
  end

  defp handle_progress(:video, entry, socket) do
    if entry.done? do
      # When upload is complete, we can display a preview
      preview_url = "/uploads/#{entry.uuid}.mp4"

      # Update parent's preview URL
      send(socket.assigns.parent_pid, {:update_preview, preview_url})

      {:noreply,
       socket
       |> assign(:preview_url, preview_url)
       |> assign(:upload_progress, 100)}
    else
      # Update progress as the upload proceeds
      progress = floor(entry.progress)
      {:noreply, assign(socket, :upload_progress, progress)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-xl font-semibold mb-4">Upload Content</h2>

      <form phx-submit="save" phx-change="validate-form" phx-target={@myself}>
        <!-- Grid container for side-by-side layout -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
          <!-- Metadata Form Fields (Left Column) -->
          <div class="space-y-4">
            <div>
              <label for="title" class="block text-sm font-medium text-gray-700">Title</label>
              <input
                type="text"
                id="title"
                name="upload_form[title]"
                value={@upload_form["title"]}
                class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                placeholder="Enter a title for your video"
              />
            </div>

            <div>
              <label for="description" class="block text-sm font-medium text-gray-700">
                Description
              </label>
              <textarea
                id="description"
                name="upload_form[description]"
                rows="3"
                class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                placeholder="Describe your video"
              ><%= @upload_form["description"] %></textarea>
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

    <!-- File Upload Area (Right Column) -->
          <div
            id="upload-area"
            phx-drop-target={@uploads.video.ref}
            phx-target={@myself}
            phx-hook="VideoUploader"
            class="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center hover:border-indigo-500 transition-colors"
          >
            <%= if @processing_filename do %>
              <p class="text-gray-700 mb-2">Selected file: <strong><%= @processing_filename %></strong></p>
              <label for="video-upload" class="mt-2 inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 cursor-pointer">
                Select Video
              </label>
              <input id="video-upload" type="file" accept=".mp4,.mov,.avi,.wmv,.flv,.webm" class="sr-only" />
              <div class="w-full bg-gray-200 h-2 rounded mt-2">
                <div class="bg-indigo-600 h-2 rounded" style={"width: #{@upload_progress}%"}></div>
              </div>
            <% else %>
              <%= if Enum.empty?(@uploads.video.entries) do %>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="mx-auto h-12 w-12 text-gray-400"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"
                  />
                </svg>
                <p class="mt-2 text-sm text-gray-500">
                  <span class="font-medium text-indigo-600 hover:text-indigo-500">
                    Upload a video
                  </span>
                  or drag and drop
                </p>
                <p class="mt-1 text-xs text-gray-500">
                  MP4, MOV, AVI, WMV, FLV, WEBM up to 500MB
                </p>

                <label
                  for="video-upload"
                  class="mt-4 inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 cursor-pointer"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="-ml-1 mr-2 h-5 w-5"
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
                  Select Video
                </label>
                <input id="video-upload" type="file" accept=".mp4,.mov,.avi,.wmv,.flv,.webm" class="sr-only" />
                <%= if @processing_filename do %>
                  <div class="w-full bg-gray-200 h-2 rounded mt-2">
                    <div class="bg-indigo-600 h-2 rounded" style={"width: #{@upload_progress}%"}></div>
                  </div>
                <% end %>
              <% else %>
                <!-- Upload in progress or completed -->
                <%= for entry <- @uploads.video.entries do %>
                  <div class="relative">
                    <!-- Video preview or placeholder -->
                    <div class="flex items-center justify-center h-32 bg-gray-100 rounded">
                      <%= if @preview_url do %>
                        <img
                          src={@preview_url}
                          alt="Video thumbnail"
                          class="h-full object-cover rounded"
                        />
                      <% else %>
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
                      <% end %>
                    </div>

    <!-- Progress bar -->
                    <div class="w-full bg-gray-200 rounded-full h-2.5 mt-2">
                      <div
                        class="bg-indigo-600 h-2.5 rounded-full"
                        style={"width: #{@upload_progress}%"}
                      >
                      </div>
                    </div>

                    <div class="flex items-center justify-between mt-2">
                      <span class="text-sm text-gray-500">
                        {entry.client_name} ({Number.Delimit.number_to_delimited(
                          div(entry.client_size, 1024 * 1024),
                          precision: 1
                        )} MB)
                      </span>

                      <button
                        phx-click="cancel-upload"
                        phx-value-ref={entry.ref}
                        class="text-red-500 hover:text-red-700 text-sm"
                      >
                        Cancel
                      </button>
                    </div>

    <!-- Entry errors -->
                    <%= for err <- upload_errors(@uploads.video, entry) do %>
                      <div class="text-red-500 text-sm mt-1">{err}</div>
                    <% end %>
                  </div>
                <% end %>
              <% end %>
            <% end %>
          </div>
        </div>
        <!-- End of grid container -->

                    <!-- Platform Selection -->
        <div class="mb-6">
          <label class="block text-sm font-medium text-gray-700 mb-2">Where to upload</label>
          <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
            <%= for {platform, status} <- @social_accounts do %>
              <button
                type="button"
                phx-click="toggle-platform"
                phx-value-platform={platform}
                disabled={!status.connected}
                aria-label={"#{Atom.to_string(platform) |> String.capitalize()} - #{if platform in @selected_platforms, do: "Selected", else: "Not selected"}"}
                class={
                              "flex items-center justify-center py-2 px-3 border rounded-md text-sm font-medium transition-colors " <>
                              if(!status.connected) do
                                "bg-gray-100 text-gray-400 cursor-not-allowed"
                              else
                                if(platform in @selected_platforms) do
                                  "bg-indigo-100 text-indigo-700 border-indigo-300 hover:bg-indigo-200"
                                else
                                  "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
                                end
                              end
                            }
              >
                <%= case platform do %>
                  <% :twitter -> %>
                    <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
                    </svg>
                  <% :instagram -> %>
                    <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                      <path
                        fill-rule="evenodd"
                        d="M12.315 2c2.43 0 2.784.013 3.808.06 1.064.049 1.791.218 2.427.465a4.902 4.902 0 011.772 1.153 4.902 4.902 0 011.153 1.772c.247.636.416 1.363.465 2.427.048 1.067.06 1.407.06 4.123v.08c0 2.643-.012 2.987-.06 4.043-.049 1.064-.218 1.791-.465 2.427a4.902 4.902 0 01-1.153 1.772 4.902 4.902 0 01-1.772 1.153c-.636.247-1.363.416-2.427.465-1.067.048-1.407.06-4.123.06h-.08c-2.643 0-2.987-.012-4.043-.06-1.064-.049-1.791-.218-2.427-.465a4.902 4.902 0 01-1.772-1.153 4.902 4.902 0 01-1.153-1.772c-.247-.636-.416-1.363-.465-2.427-.047-1.024-.06-1.379-.06-3.808v-.63c0-2.43.013-2.784.06-3.808.049-1.064.218-1.791.465-2.427a4.902 4.902 0 011.153-1.772A4.902 4.902 0 015.45 2.525c.636-.247 1.363-.416 2.427-.465C8.901 2.013 9.256 2 11.685 2h.63zm-.081 1.802h-.468c-2.456 0-2.784.011-3.807.058-.975.045-1.504.207-1.857.344-.467.182-.8.398-1.15.748-.35.35-.566.683-.748 1.15-.137.353-.3.882-.344 1.857-.047 1.023-.058 1.351-.058 3.807v.468c0 2.456.011 2.784.058 3.807.045.975.207 1.504.344 1.857.182.467.398.8.748 1.15.35.35.683.566 1.15.748.353.137.882.3 1.857.344 1.054.048 1.37.058 4.041.058h.08c2.597 0 2.917-.01 3.96-.058.976-.045 1.505-.207 1.858-.344.466-.182.8-.398 1.15-.748.35-.35.566-.683.748-1.15.137-.353.3-.882.344-1.857.048-1.055.058-1.37.058-4.041v-.08c0-2.597-.01-2.917-.058-3.96-.045-.976-.207-1.505-.344-1.858a3.097 3.097 0 00-.748-1.15 3.098 3.098 0 00-1.15-.748c-.353-.137-.882-.3-1.857-.344-1.023-.047-1.351-.058-3.807-.058zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  <% :facebook -> %>
                    <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                      <path
                        fill-rule="evenodd"
                        d="M22 12c0-5.523-4.477-10-10-10S2 6.477 2 12c0 4.991 3.657 9.128 8.438 9.878v-6.987h-2.54V12h2.54V9.797c0-2.506 1.492-3.89 3.777-3.89 1.094 0 2.238.195 2.238.195v2.46h-1.26c-1.243 0-1.63.771-1.63 1.562V12h2.773l-.443 2.89h-2.33v6.988C18.343 21.128 22 16.991 22 12z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  <% :youtube -> %>
                    <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                      <path
                        fill-rule="evenodd"
                        d="M19.812 5.418c.861.23 1.538.907 1.768 1.768C21.998 8.746 22 12 22 12s0 3.255-.418 4.814a2.504 2.504 0 011.772 1.153 2.504 2.504 0 011.153 1.772c.247.636.416 1.363.465 2.427.048 1.067.06 1.407.06 4.123v.08c0 2.643-.012 2.987-.06 4.043-.049 1.064-.218 1.791-.465 2.427a4.902 4.902 0 01-1.153 1.772 4.902 4.902 0 01-1.772 1.153c-.636.247-1.363.416-2.427.465-1.067.048-1.407.06-4.123.06h-.08c-2.643 0-2.987-.012-4.043-.06-1.064-.049-1.791-.218-2.427-.465a4.902 4.902 0 01-1.772-1.153 4.902 4.902 0 01-1.153-1.772c-.247-.636-.416-1.363-.465-2.427-.047-1.024-.06-1.379-.06-3.808v-.63c0-2.43.013-2.784.06-3.808.049-1.064.218-1.791.465-2.427a4.902 4.902 0 011.153-1.772A4.902 4.902 0 015.45 2.525c.636-.247 1.363-.416 2.427-.465C8.901 2.013 9.256 2 11.685 2h.63zm-.081 1.802h-.468c-2.456 0-2.784.011-3.807.058-.975.045-1.504.207-1.857.344-.467.182-.8.398-1.15.748-.35.35-.566.683-.748 1.15-.137.353-.3.882-.344 1.857-.047 1.023-.058 1.351-.058 3.807v.468c0 2.456.011 2.784.058 3.807.045.975.207 1.504.344 1.857.182.466.399.8.748 1.15.35.35.683.566 1.15.748.353.137.882.3 1.857.344 1.054.048 1.37.058 4.041.058h.08c2.597 0 2.917-.01 3.96-.058.976-.045 1.505-.207 1.858-.344.466-.182.8-.398 1.15-.748.35-.35.566-.683.748-1.15.137-.353.3-.882.344-1.857.048-1.055.058-1.37.058-4.041v-.08c0-2.597-.01-2.917-.058-3.96-.045-.976-.207-1.505-.344-1.858a3.097 3.097 0 00-.748-1.15 3.098 3.098 0 00-1.15-.748c-.353-.137-.882-.3-1.857-.344-1.023-.047-1.351-.058-3.807-.058zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  <% :tiktok -> %>
                    <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                      <path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z" />
                    </svg>
                  <% :linkedin -> %>
                    <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                      <path
                        fill-rule="evenodd"
                        d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  <% :pinterest -> %>
                    <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                      <path d="M12.017 0C5.396 0 .029 5.367.029 11.987c0 5.079 3.158 9.417 7.618 11.162-.105-.949-.199-2.403.041-3.439.219-.937 1.406-5.957 1.406-5.957s-.359-.72-.359-1.781c0-1.663.967-2.911 2.168-2.911 1.024 0 1.518.769 1.518 1.688 0 1.029-.653 2.567-.992 3.992-.285 1.193.6 2.165 1.775 2.165 2.128 0 3.768-2.245 3.768-5.487 0-2.861-2.063-4.869-5.008-4.869-3.41 0-5.409 2.562-5.409 5.199 0 1.033.394 2.143.889 2.741.099.12.112.225.085.345-.09.375-.293 1.199-.334 1.363-.053.225-.172.271-.401.165-1.495-.69-2.433-2.878-2.433-4.646 0-3.776 2.748-7.252 7.92-7.252 4.158 0 7.392 2.967 7.392 6.923 0 4.135-2.607 7.462-6.233 7.462-1.214 0-2.354-.629-2.758-1.379l-.749 2.848c-.269 1.045-1.004 2.352-1.498 3.146 1.123.345 2.306.535 3.55.535 6.607 0 11.985-5.365 11.985-11.987C23.97 5.39 18.592.022 11.985.022L12.017 0z" />
                    </svg>
                <% end %>
                <%= if platform in @selected_platforms do %>
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="ml-2 h-4 w-4 text-indigo-500"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                      clip-rule="evenodd"
                    />
                  </svg>
                <% end %>
              </button>
            <% end %>
          </div>
          <%= if !Enum.empty?(@selected_platforms) do %>
            <p class="mt-2 text-sm text-gray-600">
              Selected: {@selected_platforms
              |> Enum.map(&(Atom.to_string(&1) |> String.capitalize()))
              |> Enum.join(", ")}
            </p>
          <% else %>
            <p class="mt-2 text-sm text-red-500">
              Please select at least one platform
            </p>
          <% end %>
        </div>

    <!-- Action Buttons -->
        <div class="flex items-center space-x-3">
          <button
            type="submit"
            class="inline-flex justify-center items-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
            disabled={
              Enum.empty?(@uploads.video.entries) || @upload_progress < 100 ||
                Enum.empty?(@selected_platforms)
            }
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

          <button
            type="button"
            phx-click={JS.patch(~p"/dashboard?tab=schedule")}
            class="inline-flex justify-center items-center py-2 px-4 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            disabled={
              Enum.empty?(@uploads.video.entries) || @upload_progress < 100 ||
                Enum.empty?(@selected_platforms)
            }
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="-ml-1 mr-2 h-5 w-5 text-gray-500"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fill-rule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z"
                clip-rule="evenodd"
              />
            </svg>
            Schedule For Later
          </button>

          <button
            type="button"
            phx-click={JS.patch(~p"/dashboard?tab=preview")}
            class="inline-flex justify-center items-center py-2 px-4 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            disabled={
              Enum.empty?(@uploads.video.entries) || @upload_progress < 100 ||
                Enum.empty?(@selected_platforms)
            }
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="-ml-1 mr-2 h-5 w-5 text-gray-500"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path d="M10 12a2 2 0 100-4 2 2 0 000 4z" />
              <path
                fill-rule="evenodd"
                d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z"
                clip-rule="evenodd"
              />
            </svg>
            Preview
          </button>
        </div>
      </form>
    </div>
    """
  end
end
