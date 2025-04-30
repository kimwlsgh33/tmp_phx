defmodule MyappWeb.DashboardLive.Components.UploadComponent do
  use MyappWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:upload_progress, 0)
     |> assign(:processing_filename, nil)
     |> assign(:preview_url, nil)
     |> assign(:scheduled_upload, false)
     |> assign(:upload_form, %{
       "title" => "",
       "description" => "",
       "tags" => "",
       "schedule_at" => ""
     })
     |> allow_upload(:video,
       accept: ~w(.mp4 .mov .avi .wmv .flv .webm),
       max_entries: 5,
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
      |> assign_new(:scheduled_upload, fn -> false end)
      |> assign(assigns)
      |> allow_upload(:video,
        accept: ~w(.mp4 .mov .avi .wmv .flv .webm),
        max_entries: 5,
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
  def handle_event("toggle-scheduled-upload", %{"value" => value}, socket) do
    # Toggle the scheduled_upload state
    scheduled_upload = case value do
      "on" -> true  # Checkbox checked
      "true" -> true
      "false" -> false
      _ -> !socket.assigns.scheduled_upload  # Toggle current value as fallback
    end
    
    {:noreply, assign(socket, :scheduled_upload, scheduled_upload)}
  end

  @impl true
  def handle_event("save", %{"upload_form" => form_params}, socket) do
    if socket.assigns.selected_platforms == [] do
      {:noreply,
       socket
       |> put_flash(:error, "Please select at least one social media platform")}
    else
      if socket.assigns.scheduled_upload do
        # Handle scheduled upload
        scheduled_time = form_params["schedule_at"]
        
        if scheduled_time == "" do
          {:noreply, socket |> put_flash(:error, "Please select a scheduled time")}
        else
          # Save the schedule to the database here (in a real implementation)
          send(socket.assigns.parent_pid, {:schedule_complete, socket.assigns.selected_platforms, scheduled_time})
          
          {:noreply,
           socket
           |> put_flash(:info, "Content scheduled for upload at #{scheduled_time}")}
        end
      else
        # In real implementation, we would handle the immediate upload here
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
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :video, ref)}
  end



  @impl true
  def handle_event("schedule", %{"upload_form" => form_params}, socket) do
    scheduled_time = form_params["schedule_at"]

    if socket.assigns.selected_platforms == [] do
      {:noreply,
       socket
       |> put_flash(:error, "Please select at least one social media platform")}
    else
      # In a real implementation, save the schedule to the database here
      send(socket.assigns.parent_pid, {:schedule_complete, socket.assigns.selected_platforms, scheduled_time})
      {:noreply,
       socket
       |> put_flash(:info, "Content scheduled for upload at #{scheduled_time}")}
    end
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
            phx-hook="FileUploader"
            class="border border-gray-300 rounded-lg p-8 text-center hover:border-gray-300 transition-colors flex flex-col justify-center items-center min-h-[320px]"
          >
            <div id="file-input-container" class="w-full flex justify-center mb-6" phx-update="ignore">
              <label
                for="client-upload-input"
                class="custom-file-label cursor-pointer flex flex-col items-center justify-center max-w-xs w-full px-8 py-6 bg-indigo-50 border-2 border-dashed border-indigo-300 rounded-xl shadow-lg hover:bg-indigo-100 transition-colors text-center"
              >
                <span class="text-indigo-700 font-bold text-base mb-1">Click to select files</span>
                <span class="text-xs text-gray-500">(Images or videos, multiple allowed)</span>
              </label>
              <input
                type="file"
                id="client-upload-input"
                multiple
                accept="image/*,video/*"
                class="hidden"
              />
            </div>

    <!-- Preview area: Previews before upload are handled by JS (see file_uploader.js). This div is ignored by LiveView updates. -->
            <div class="w-full flex flex-col items-center">
              <div class="relative w-full">
                <div
                  id="preview-area"
                  class="preview flex flex-wrap gap-4 justify-center mb-4"
                  phx-update="ignore"
                >
                </div>
              </div>
              <figure
                id="file-count-figure"
                class="file-count flex flex-col items-center mt-2"
                phx-update="ignore"
                style="display:none"
              >
                <div class="rounded bg-gray-100 text-gray-600 font-semibold px-2 py-1 text-xs shadow border border-gray-200">
                </div>
                <figcaption class="text-[10px] text-gray-400"></figcaption>
              </figure>
            </div>
          </div>
        </div>

    <!-- Platform Selection: Select the SNS platform(s) to upload to. -->
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
                        d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"
                      />
                    </svg>
                  <% :instagram -> %>
                    <!-- Official Instagram Glyph from brand.instagram.com, monochrome adaptation -->
                    <svg
                      class="h-5 w-5"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="1.8"
                      viewBox="0 0 24 24"
                      aria-hidden="true"
                    >
                      <rect x="2.5" y="2.5" width="19" height="19" rx="5" />
                      <circle cx="12" cy="12" r="5" />
                      <circle cx="18" cy="6" r="1.3" />
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
                    <!-- Official YouTube Brand Icon from youtube.com/about/brand-resources -->
                    <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                      <g>
                        <path d="M23.498 6.186a2.998 2.998 0 0 0-2.11-2.117C19.507 3.5 12 3.5 12 3.5s-7.507 0-9.388.569a2.998 2.998 0 0 0-2.11 2.117A31.566 31.566 0 0 0 0 12c-.057 1.801-.061 3.597.502 5.814a2.998 2.998 0 0 0 2.11 2.117C4.493 20.5 12 20.5 12 20.5s7.507 0 9.388-.569a2.988 2.988 0 0 0 2.11-2.117C24 15.597 24 12 24 12s0-3.597-.502-5.814zM9.545 15.568V8.432l6.55 3.568-6.55 3.568z">
                        </path>
                      </g>
                    </svg>
                  <% :tiktok -> %>
                    <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                      <path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z" />
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

        <!-- Scheduled Upload Option -->
        <div class="mb-6">
          <div class="flex items-center">
            <input
              id="scheduled-upload"
              type="checkbox"
              phx-click="toggle-scheduled-upload"
              phx-click="toggle-scheduled-upload"
              phx-target={@myself}
              checked={@scheduled_upload}
            />
            <label for="scheduled-upload" class="ml-2 block text-sm text-gray-700">
              Schedule upload for later
            </label>
          </div>

          <%= if @scheduled_upload do %>
            <div class="mt-3">
              <label for="schedule_at" class="block text-sm font-medium text-gray-700">
                Select date and time
              </label>
              <input
                type="datetime-local"
                id="schedule_at"
                name="upload_form[schedule_at]"
                value={@upload_form["schedule_at"]}
                class="mt-1 block w-full sm:w-96 border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                min={DateTime.utc_now() |> DateTime.add(60, :second) |> DateTime.to_iso8601()}
              />
              <p class="mt-1 text-xs text-gray-500">
                Select when you want this content to be uploaded
              </p>
            </div>
          <% end %>
        </div>

    <!-- Action Buttons -->
        <div class="flex items-center space-x-3">
          <button
            type="button"
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
            <%= if @scheduled_upload do %>
              Schedule Upload
            <% else %>
              Upload Now
            <% end %>
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
