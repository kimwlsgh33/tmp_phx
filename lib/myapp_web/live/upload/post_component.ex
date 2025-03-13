defmodule MyappWeb.Upload.PostComponent do
  use MyappWeb, :live_component

  alias MyappWeb.SocialMediaController

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> allow_upload(:files,
       accept: ~w(.jpg .jpeg .png .pdf .doc .docx),
       max_entries: 5,
       max_file_size: 50_000_000,
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
          <label class="block text-gray-700 mb-2">Content</label>
          <textarea name="content" rows="4" class="w-full border rounded px-3 py-2" required></textarea>
        </div>
        <div class="mb-4">
          <label class="block text-gray-700 mb-2">Platforms</label>
          <div class="flex gap-4">
            <label class="inline-flex items-center">
              <input type="checkbox" name="platforms[]" value="twitter" class="form-checkbox" />
              <span class="ml-2">Twitter</span>
            </label>
            <label class="inline-flex items-center">
              <input type="checkbox" name="platforms[]" value="facebook" class="form-checkbox" />
              <span class="ml-2">Facebook</span>
            </label>
            <label class="inline-flex items-center">
              <input type="checkbox" name="platforms[]" value="instagram" class="form-checkbox" />
              <span class="ml-2">Instagram</span>
            </label>
          </div>
        </div>
        <div class="mb-4">
          <label class="block text-gray-700 mb-2">Upload Files</label>
          <div class="border-dashed border-2 border-gray-300 p-6 text-center rounded" phx-drop-target={@uploads.files.ref}>
            <p>Drag files here or click to browse</p>
            <small class="text-gray-500">Accepted formats: JPG, JPEG, PNG, PDF, DOC, DOCX (max 50MB)</small>
            <.live_file_input upload={@uploads.files} class="mt-2" />
            
            <%= for entry <- @uploads.files.entries do %>
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
              <%= for err <- upload_errors(@uploads.files, entry) do %>
                <div class="text-red-500 text-sm mt-1"><%= err %></div>
              <% end %>
            <% end %>
          </div>
        </div>
        <div class="flex justify-end">
          <button type="submit" class="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded">
            Upload Post
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
  def handle_event("save", %{"title" => title, "content" => content, "platforms" => platforms}, socket) do
    case validate_platforms(platforms) do
      :ok ->
        handle_upload(socket, title, content, platforms)

      {:error, message} ->
        send(self(), {:upload_error, message})
        {:noreply, socket}
    end
  end

  def handle_event("save", %{"title" => _title, "content" => _content}, socket) do
    send(self(), {:upload_error, "Please select at least one platform"})
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :files, ref)}
  end

  # Private functions

  defp validate_file(%{client_type: type}, _socket) do
    case type do
      "image/jpeg" -> :ok
      "image/png" -> :ok
      "application/pdf" -> :ok
      "application/msword" -> :ok
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" -> :ok
      _ -> {:error, "Invalid file type"}
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

  defp handle_progress(:files, entry, socket) do
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

  defp handle_upload(socket, title, content, platforms) do
    user = socket.assigns.current_user

    # Consume uploaded files
    uploaded_files =
      consume_uploaded_entries(socket, :files, fn %{path: path}, entry ->
        upload_file(%{path: path}, entry)
      end)

    case SocialMediaController.create_post(user, %{
      title: title,
      content: content,
      files: uploaded_files,
      platforms: platforms
    }) do
      {:ok, _post} ->
        send(self(), {:upload_success, "Post uploaded successfully!"})
        {:noreply, socket}

      {:error, reason} ->
        send(self(), {:upload_error, reason})
        {:noreply, socket}
    end
  end
end

defmodule MyappWeb.Upload.PostComponent do
  use MyappWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> allow_upload(:files, accept: ~w(.jpg .jpeg .png .pdf .doc .docx), max_entries: 5)}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-md p-6">
      <form phx-submit="save" phx-change="validate" phx-target={@myself}>
        <div class="mb-4">
          <label class="block text-gray-700 mb-2">Title</label>
          <input type="text" name="title" class="w-full border rounded px-3 py-2" />
        </div>
        <div class="mb-4">
          <label class="block text-gray-700 mb-2">Content</label>
          <textarea name="content" rows="4" class="w-full border rounded px-3 py-2"></textarea>
        </div>
        <div class="mb-4">
          <label class="block text-gray-700 mb-2">Upload Files</label>
          <div class="border-dashed border-2 border-gray-300 p-6 text-center rounded">
            <p>Drag files here or click to browse</p>
            <.live_file_input upload={@uploads.files} class="mt-2" />
            
            <%= for entry <- @uploads.files.entries do %>
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
            <% end %>
          </div>
        </div>
        <div class="flex justify-end">
          <button type="submit" class="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded">
            Upload Post
          </button>
        </div>
      </form>
    </div>
    """
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"title" => title, "content" => content}, socket) do
    # Handle file uploads
    uploaded_files =
      consume_uploaded_entries(socket, :files, fn %{path: path}, entry ->
        dest = Path.join("priv/static/uploads", entry.client_name)
        File.cp!(path, dest)
        {:ok, "/uploads/#{entry.client_name}"}
      end)

    # Process the upload (in a real app, you'd save to database)
    IO.inspect(%{title: title, content: content, files: uploaded_files}, label: "Post Upload")

    {:noreply,
     socket
     |> put_flash(:info, "Post uploaded successfully!")}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :files, ref)}
  end
end