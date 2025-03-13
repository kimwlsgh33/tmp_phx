defmodule MyappWeb.Upload.LongVideoComponent do
  use MyappWeb, :live_component

  alias MyappWeb.SocialMediaController

  @max_file_size 500_000_000  # 500MB in bytes

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:selected_category, nil)
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
          <textarea name="description" rows="3" class="w-full border rounded px-3 py-2" required></textarea>
        </div>
        <div class="mb-4">
          <label class="block text-gray-700 mb-2">Category</label>
          <select name="category" class="w-full border rounded px-3 py-2" required>
            <option value="">Select a category</option>
            <option value="education">Education</option>
            <option value="entertainment">Entertainment</option>
            <option value="gaming">Gaming</option>
            <option value="music">Music</option>
            <option value="tech">Technology</option>
            <option value="other">Other</option>
          </select>
        </div>
        <div class="mb-4">
          <label class="block text-gray-700 mb-2">Tags (comma separated)</label>
          <input type="text" name="tags" class="w-full border rounded px-3 py-2" placeholder="e.g., tutorial, technology, programming" />
        </div>
        <div class="mb-4">
          <label class="block text-gray-700 mb-2">Platforms</label>
          <div class="flex gap-4">
            <label class="inline-flex items-center">
              <input type="checkbox" name="platforms[]" value="youtube" class="form-checkbox" />
              <span class="ml-2">YouTube</span>
            </label>
            <label class="inline-flex items-center">
              <input type="checkbox" name="platforms[]" value="vimeo" class="form-checkbox" />
              <span class="ml-2">Vimeo</span>
            </label>
          </div>
        </div>
        <div class="mb-4">
          <label class="block text-gray-700 mb-2">Visibility</label>
          <select name="visibility" class="w-full border rounded px-3 py-2" required>
            <option value="public">Public</option>
            <option value="unlisted">Unlisted</option>
            <option value="private">Private</option>
          </select>
        </div>
        <div class="mb-4">
          <label class="block text-gray-700 mb-2">Upload Long Video</label>
          <div class="border-dashed border-2 border-gray-300 p-6 text-center rounded" phx-drop-target={@uploads.video.ref}>
            <p>Drag video file here or click to browse</p>
            <small class="text-gray-500">Max size: 500MB. Formats: MP4, MOV</small>
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
            Upload Long Video
          </button>
        </div>
      </form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", params, socket) do
    # Handle category selection for dynamic form updates if needed
    socket =
      if category = params["category"] do
        assign(socket, :selected_category, category)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
    "save",
    %{
      "title" => title,
      "description" => description,
      "category" => category,
      "tags" => tags,
      "platforms" => platforms,
      "visibility" => visibility
    },
    socket
  ) do
    case validate_platforms(platforms) do
      :ok ->
        tag_list = parse_tags(tags)
        handle_upload(socket, %{
          title: title,
          description: description,
          category: category,
          tags: tag_list,
          platforms: platforms,
          visibility: visibility
        })

      {:error, message} ->
        send(self(), {:upload_error, message})
        {:noreply, socket}
    end
  end

  def handle_event("save", _params, socket) do
    send(self(), {:upload_error, "Please fill in all required fields and select at least one platform"})
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :video, ref)}
  end

  # Private functions

  defp validate_file(%{client_type: type}, _socket) do
    case type do
      "video/mp4" -> :ok
      "video/quicktime" -> :ok  # For .mov files
      _ -> {:error, "Invalid file type. Only MP4 and MOV files are allowed"}
    end
  end

  defp validate_platforms(platforms) when is_list(platforms) do
    if Enum.empty?(platforms) do
      {:error, "Please select at least one platform"}
    else
      :ok
    end
  end

  defp validate_platforms(_), do: {:error, "Please select at least one platform"}

  defp parse_tags(""), do: []
  defp parse_tags(tags) when is_binary(tags) do
    tags
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

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

  defp handle_upload(socket, params) do
    user = socket.assigns.current_user

    # Consume uploaded video
    case consume_uploaded_entries(socket, :video, fn %{path: path}, entry ->
      upload_file(%{path: path}, entry)
    end) do
      [video_path] ->
        case SocialMediaController.create_long_video(user, Map.put(params, :video_path, video_path)) do
          {:ok, _video} ->
            send(self(), {:upload_success, "Long video uploaded successfully!"})
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

