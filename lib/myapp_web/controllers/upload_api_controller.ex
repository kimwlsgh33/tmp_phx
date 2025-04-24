defmodule MyappWeb.UploadApiController do
  use MyappWeb, :controller

  @chunk_dir Path.join([:code.priv_dir(:myapp), "static", "uploads", "tmp"])
  @final_dir Path.join([:code.priv_dir(:myapp), "static", "uploads"])

  alias Myapp.Upload.Upload
  alias Myapp.Repo

  # POST /api/upload_chunk
  def upload_chunk(conn, %{"fileId" => file_id, "chunk" => %Plug.Upload{} = upload, "start" => start, "fileName" => file_name, "total" => total_size}) do
    user_id = conn.assigns[:current_user] && conn.assigns.current_user.id
    chunk_dir = Path.join(@chunk_dir, file_id)
    File.mkdir_p!(chunk_dir)
    chunk_path = Path.join(chunk_dir, "#{start}")
    File.cp!(upload.path, chunk_path)
    # Update or create DB record
    bytes_uploaded =
      File.ls!(chunk_dir)
      |> Enum.map(&Path.join(chunk_dir, &1))
      |> Enum.map(&File.stat!/1)
      |> Enum.map(& &1.size)
      |> Enum.sum()
    upload_rec = Repo.get_by(Upload, file_id: file_id) || %Upload{}
    changeset = Upload.changeset(upload_rec, %{
      file_id: file_id,
      file_name: file_name,
      user_id: user_id,
      status: "in_progress",
      bytes_uploaded: bytes_uploaded
    })
    Repo.insert_or_update!(changeset)
    json(conn, %{status: "ok", start: start, bytes_uploaded: bytes_uploaded})
  end

  # GET /api/upload_status/:file_id
  def upload_status(conn, %{"file_id" => file_id}) do
    chunk_dir = Path.join(@chunk_dir, file_id)
    uploaded =
      if File.exists?(chunk_dir) do
        File.ls!(chunk_dir)
        |> Enum.map(&String.to_integer/1)
        |> Enum.sort()
      else
        []
      end
    bytes_uploaded = Enum.reduce(uploaded, 0, fn offset, acc ->
      chunk_path = Path.join(chunk_dir, Integer.to_string(offset))
      acc + File.stat!(chunk_path).size
    end)
    json(conn, %{uploaded: uploaded, bytesUploaded: bytes_uploaded})
  end

  # POST /api/complete_upload
  def complete_upload(conn, %{"fileId" => file_id, "fileName" => file_name}) do
    user_id = conn.assigns[:current_user] && conn.assigns.current_user.id
    chunk_dir = Path.join(@chunk_dir, file_id)
    final_ext = Path.extname(file_name)
    final_name = "#{file_id}#{final_ext}"
    final_path = Path.join(@final_dir, final_name)
    {:ok, files} = File.ls(chunk_dir)
    files = Enum.map(files, &String.to_integer/1) |> Enum.sort()
    File.open!(final_path, [:write, :binary], fn dest ->
      Enum.each(files, fn offset ->
        chunk_path = Path.join(chunk_dir, Integer.to_string(offset))
        chunk = File.read!(chunk_path)
        IO.binwrite(dest, chunk)
      end)
    end)
    url = "/uploads/#{final_name}"
    # Clean up chunk directory after successful merge
    File.rm_rf!(chunk_dir)
    # Update DB record
    upload_rec = Repo.get_by(Upload, file_id: file_id) || %Upload{}
    changeset = Upload.changeset(upload_rec, %{
      file_id: file_id,
      file_name: file_name,
      user_id: user_id,
      url: url,
      status: "completed"
    })
    Repo.insert_or_update!(changeset)
    json(conn, %{status: "ok", url: url})
  end

  # POST /api/sns_post
  def sns_post(conn, %{"fileId" => file_id, "sns" => sns}) do
    # TODO: Integrate with SNS APIs using user's connected accounts
    # For now, just return ok
    json(conn, %{status: "ok"})
  end

  # Helper: get final file name from chunk_dir
  defp get_final_filename(chunk_dir) do
    Path.basename(chunk_dir) <> ".mp4"
  end

  # Scheduler (not implemented):
  # Use Quantum, Oban, or a simple Task to periodically delete old chunk dirs
  # Example: delete dirs in @chunk_dir older than 12 hours
  # See README for details on how to implement

  # Helper: get final file name from chunk_dir
  defp get_final_filename(chunk_dir) do
    # Try to find the original name from a chunk or metadata
    # For now, just use file_id.mp4 (improve as needed)
    Path.basename(chunk_dir) <> ".mp4"
  end

  # Scheduler (not implemented):
  # Use Quantum, Oban, or a simple Task to periodically delete old chunk dirs
  # Example: delete dirs in @chunk_dir older than 24 hours
  # See README for details on how to implement
end
