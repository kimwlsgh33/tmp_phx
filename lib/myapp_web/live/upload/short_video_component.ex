defmodule MyappWeb.Upload.ShortVideoComponent do
  use MyappWeb, :live_component

  alias MyappWeb.SocialMediaController

  @max_file_size 100_000_000  # 100MB in bytes
  @max_duration 60  # 60 seconds

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> allow_upload(:video,
       accept: ~w(.mp4 .mov),
       max_entries: 1,
       max_file_size: @max_file_size,
       auto_upload: true,
       progress: &handle_progress/3,
       validate: &validate_file/2
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-md p-6">
      <form phx-submit="save" phx-change="validate" phx-target={@myself}>
        <div class="mb-4">
          <label class="block text-gray-700 mb-2">Title</label>
          <input type="text" name="title" class="w-full border rounded px-3 py-2" required />
        </div>
        <div class="mb-4">
          <label class="block text-gray-700 mb-2">Description</label>
          <textarea name="description" rows="2" class="w-full border rounded px-3 py-2" required></textarea>
        </div>
        <div class="mb-4">
          <label class="block text-gray-700 mb-2">Platforms</label>
          <div class="flex gap-4">
            <label class="inline-flex items-center">
              <input type="checkbox" name="platforms[]" value="tiktok" class="form-checkbox" />
              <span class="ml-2">TikTok</span>
            </label>
            <label class="inline-flex items-center">
              <input type="checkbox" name="platforms[]" value="instagram" class="form-checkbox" />
              <span class="ml-2">Instagram Reels</span>
            </label>
          </div>
        </div>
        <div class="mb-4">
          <label class="block text-gray-700 mb-2">Upload Short Video</label>
          <div class="border-dashed border-2 border-gray-300 p-6 text-center rounded" phx-drop-target={@uploads.video.ref}>
            <p>Drag video file here or click to browse</p>
            <small class="text-gray-500">Max duration: 60 seconds. Max size: 100MB. Formats: MP4, MOV</small>
            <.live_file_input upload={@uploads.video} class="mt-2" />
            
            <%= for entry <- @uploads.video.entries do %>
              <div class="mt-2 flex items-center">
                <div class="text-sm"><%= entry.client_name %></div>
                <div class="ml-auto">
                  <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} phx-target={@myself} class="text-red-500">
                    &times;
                  </button>
                </div>
              </div>
              <div class="w-full h-2 bg-gray-200 rounded-full mt-1">
                <div class="h-2 bg-blue-500 rounded-full" style={"width: #{entry.progress}%"}></div>
              </div>
              <%= for err <- upload_errors(@uploads.video, entry) do %>
                <div class="text-red-500 text-sm mt-1"><%= err %></div>
              <% end %>
            <% end %>
          </div>
        </div>
        <div class="flex justify-end">
          <button type="submit" class="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded">
            Upload Short Video
          </button>
        </div>
      </form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"title" => title, "description" => description, "platforms" => platforms}, socket) do
    case validate_platforms(platforms) do
      :ok ->
        handle_upload(socket, title, description, platforms)

      {:error, message} ->
        send(self(), {:upload_error, message})
        {:noreply, socket}
    end
  end

  def handle_event("save", %{"title" => _title, "description" => _description}, socket) do
    send(self(), {:upload_error, "Please select at least one platform"})
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :video, ref)}
  end

  # Private functions

  defp validate_file(%{client_type: type} = entry, socket) do
    with :ok <- validate_type(type),
         :ok <- validate_duration(entry) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_type(type) do
    case type do
      "video/mp4" -> :ok
      "video/quicktime" -> :ok  # For .mov files
      _ -> {:error, "Invalid file type. Only MP4 and MOV files are allowed"}
    end
  end

  defp validate_duration(entry) do
    # In a real application, you would use a video processing library
    # to check the actual duration of the video
    # For now, we'll assume the validation is successful
    :ok
  end

  defp validate_platforms(platforms) when is_list(platforms) do
    if Enum.empty?(platforms) do
      {:error, "Please select at least one platform"}
    else
      :ok
    end
  end

  defp validate_platforms(_), do: {:error, "Please select at least one platform"}

  defp handle_progress(:video, entry, socket) do
    if entry.done? do
      {:ok, path} = consume_uploaded_entry(socket, entry, &upload_file/2)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp upload_file(%{path: path}, entry) do
    dest = Path.join("priv/static/uploads", entry.client_name)
    File.cp!(path, dest)
    {:ok, "/uploads/#{entry.client_name}"}
  end

  defp handle_upload(socket, title, description, platforms) do
    user = socket.assigns.current_user

    # Consume uploaded video
    case consume_uploaded_entries(socket, :video, fn %{path: path}, entry ->
      upload_file(%{path: path}, entry)
    end) do
      [video_path] ->
        case SocialMediaController.create_short_video(user, %{
          title: title,
          description: description,
          video_path: video_path,
          platforms: platforms
        }) do
          {:ok, _video} ->
            send(self(), {:upload_success, "Short video uploaded successfully!"})
            {:noreply, socket}

          {:error, reason} ->
            send(self(), {:upload_error, reason})
            {:noreply, socket}
        end

      [] ->
        send(self(), {:upload_error, "Please upload a video"})
        {:noreply, socket}
    end
  end
end

