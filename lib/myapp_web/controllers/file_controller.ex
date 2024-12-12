defmodule MyappWeb.FileController do
  use MyappWeb, :controller

  alias Myapp.FileServer

  def upload(conn, %{"file" => file_params}) do
    upload = file_params.path
    filename = file_params.filename

    case FileServer.write_file(upload_path(filename), File.read!(upload)) do
      :ok ->
        json(conn, %{status: "success", message: "File uploaded successfully"})
      
      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{status: "error", message: "Failed to upload file: #{inspect(reason)}"})
    end
  end

  def download(conn, %{"filename" => filename}) do
    case FileServer.read_file(upload_path(filename)) do
      {:ok, content} ->
        conn
        |> put_resp_content_type("application/octet-stream")
        |> put_resp_header("content-disposition", ~s(attachment; filename="#{filename}"))
        |> send_resp(200, content)

      {:error, reason} ->
        conn
        |> put_status(:not_found)
        |> json(%{status: "error", message: "File not found: #{inspect(reason)}"})
    end
  end

  defp upload_path(filename) do
    Path.join(Application.get_env(:myapp, :upload_path, "priv/static/uploads"), filename)
  end
end
