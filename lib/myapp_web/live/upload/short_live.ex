defmodule MyappWeb.Upload.ShortLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Upload Short Video")
     |> allow_upload(:video, accept: ~w(.mp4 .mov .avi), max_entries: 1, max_file_size: 100_000_000)}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4">
      <h1 class="text-2xl font-bold mb-4">Upload Short Video</h1>
      <div class="bg-white rounded-lg shadow-md p-6">
        <form phx-submit="save" phx-change="validate">
          <div class="mb-4">
            <label class="block text-gray-700 mb-2">Title</label>
            <input type="text" name="title" class="w-full border rounded px-3 py-2" />
          </div>
          <div class="mb-4">
            <label class="block text-gray-700 mb-2">Description</label>
            <textarea name="description" rows="2" class="w-full border rounded px-3 py-2"></textarea>
          </div>
          <div class="mb-4">
            <label class="block text-gray-700 mb-2">Upload Short Video (max 60 seconds)</label>
            <div class="border-dashed border-2 border-gray-300 p-6 text-center rounded">
              <p>Drag video file here or click to browse</p>
              <.live_file_input upload={@uploads.video} class="mt-2" />
              
              <%= for entry <- @uploads.video.entries do %>
                <div class="mt-2 flex items-center">
                  <div class="text-sm"><%= entry.client_name %></div>
                  <div class="ml-auto">
                    <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} class="text-red-500">
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
          <div class="flex justify-between">
            <a href={~p"/upload"} class="bg-gray-300 hover:bg-gray-400 text-gray-800 px-4 py-2 rounded">
              Back
            </a>
            <button type="submit" class="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded">
              Upload Short
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"title" => title, "description" => description}, socket) do
    # Handle video upload
    uploaded_files =
      consume_uploaded_entries(socket, :video, fn %{path: path}, entry ->
        dest = Path.join("priv/static/uploads", entry.client_name)
        File.cp!(path, dest)
        {:ok, "/uploads/#{entry.client_name}"}
      end)

    # Process the upload (in a real app, you'd save to database)
    IO.inspect(%{title: title, description: description, video: uploaded_files}, label: "Short Video Upload")

    {:noreply,
     socket
     |> put_flash(:info, "Short video uploaded successfully!")
     |> push_navigate(to: ~p"/upload")}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :video, ref)}
  end
end