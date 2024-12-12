defmodule MyappWeb.FileLive do
  use MyappWeb, :live_view
  alias Myapp.FileServer

  @uploads_dir "priv/static/uploads"

  @impl true
  def mount(_params, _session, socket) do
    File.mkdir_p!(@uploads_dir)

    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> assign(:files, list_files())
     |> allow_upload(:file, accept: :any, max_entries: 1)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :file, fn %{path: path}, entry ->
        dest = Path.join(@uploads_dir, entry.client_name)
        File.cp!(path, dest)
        {:ok, entry.client_name}
      end)

    {:noreply,
     socket
     |> update(:uploaded_files, &(&1 ++ uploaded_files))
     |> assign(:files, list_files())}
  end

  @impl true
  def handle_event("delete", %{"filename" => filename}, socket) do
    file_path = Path.join(@uploads_dir, filename)
    FileServer.delete_file(file_path)

    {:noreply, assign(socket, :files, list_files())}
  end

  defp list_files do
    case File.ls(@uploads_dir) do
      {:ok, files} -> files
      {:error, _} -> []
    end
  end

  defp error_to_string(:too_large), do: "File is too large"
  defp error_to_string(:too_many_files), do: "Too many files"
  defp error_to_string(:not_accepted), do: "Unacceptable file type"
end
