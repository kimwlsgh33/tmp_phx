defmodule MyappWeb.DashboardLive.Components.UploadTabs.PhotoSelectionComponent do
  use MyappWeb, :live_component

  # Define YouTube specific formats
  @youtube_formats ~w(.mov .mp4 .mpg .mpeg .avi .webm)
  # Define general video formats
  @general_formats ~w(.mp4 .mov .avi .wmv .flv .webm)

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:upload_progress, 0)
     |> assign(:processing_filename, nil)
     |> assign(:preview_url, nil)
     |> assign(:files_selected, false)
     |> allow_upload(:video,
       accept: @general_formats,
       max_entries: 5,
       max_file_size: 500_000_000,
       progress: &handle_progress/3
     )}
  end

  @impl true
  def update(assigns, socket) do
    # Assign default value for selected_platforms if not provided
    socket = socket
      |> assign_new(:processing_filename, fn -> nil end)
      |> assign(assigns)
      |> assign_new(:selected_platforms, fn -> [] end)
      
    # Determine which formats to accept based on selected platforms
    accepted_formats = get_accepted_formats(socket.assigns.selected_platforms)

    # Update the component state and allow uploads on each render
    socket = socket
      |> allow_upload(:video,
        accept: accepted_formats,
        max_entries: 5,
        max_file_size: 500_000_000,
        progress: &handle_progress/3
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :video, ref)}
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

  @impl true
  def handle_event("goto-description", _params, socket) do
    # Notify parent to switch to the description tab
    send(socket.assigns.parent_pid, :switch_to_description_tab)
    {:noreply, socket}
  end

  @impl true
  def handle_event("file_selected", %{"count" => count}, socket) do
    count_int = case count do
      i when is_integer(i) -> i
      s when is_binary(s) -> String.to_integer(s)
    end
    {:noreply, assign(socket, :files_selected, count_int > 0)}
  end

  # Get the appropriate file formats based on selected platforms
  defp get_accepted_formats(selected_platforms) do
    if :youtube in selected_platforms do
      # If YouTube is selected, only allow YouTube supported formats
      @youtube_formats
    else
      # Otherwise, allow all general formats
      @general_formats
    end
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
      <h2 class="text-xl font-semibold mb-4">Select Photos & Videos</h2>
      <p class="text-gray-600 mb-6">Choose the content you want to share to your social media accounts.</p>

      <%= if is_list(@selected_platforms) and :youtube in @selected_platforms do %>
        <div class="mb-4 p-4 bg-yellow-50 border-l-4 border-yellow-400 rounded-md">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-yellow-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
              </svg>
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-medium text-yellow-800">YouTube 업로드 제한</h3>
              <div class="mt-1 text-sm text-yellow-700">
                <p>YouTube를 선택한 경우, 다음 파일 형식만 업로드할 수 있습니다: MOV, MP4, MPG, MPEG, AVI, WEBM</p>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <div class="mb-6">
        <!-- File Upload Area -->
        <div
          id="upload-area"
          phx-hook="FileUploader"
          phx-target={@myself}
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
              accept={if is_list(@selected_platforms) and :youtube in @selected_platforms, do: "video/mp4,.mp4,video/x-m4v,.m4v,video/quicktime,.mov,video/x-msvideo,.avi,video/mpeg,.mpg,.mpeg,video/webm,.webm", else: "image/*,video/*"}
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

      <!-- Upload Progress Indicator -->
      <%= if @upload_progress > 0 && @upload_progress < 100 do %>
        <div class="mb-6">
          <div class="w-full bg-gray-200 rounded-full h-2.5">
            <div class="bg-indigo-600 h-2.5 rounded-full" style={"width: #{@upload_progress}%"}></div>
          </div>
          <p class="text-sm text-gray-600 mt-1">Uploading... <%= @upload_progress %>%</p>
        </div>
      <% end %>

      <!-- Actions -->
      <div class="flex justify-between">
        <div>
          <!-- Left side - can be empty or have help text -->
        </div>
        <button
          type="button"
          phx-click="goto-description"
          phx-target={@myself}
          class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
          disabled={@files_selected == false}
        >
          Continue to Description
          <svg xmlns="http://www.w3.org/2000/svg" class="ml-2 h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M12.293 5.293a1 1 0 011.414 0l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414-1.414L14.586 11H3a1 1 0 110-2h11.586l-2.293-2.293a1 1 0 010-1.414z" clip-rule="evenodd" />
          </svg>
        </button>
      </div>
    </div>
    """
  end
end
