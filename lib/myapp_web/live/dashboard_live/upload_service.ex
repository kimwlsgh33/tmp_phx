defmodule MyappWeb.DashboardLive.UploadService do
  @moduledoc """
  Service module for handling video uploads.
  This module handles video file processing and storage.
  """
  
  @doc """
  Process a video upload entry.
  Creates a temporary file and returns the URL for the video.
  """
  def process_video_upload(entry) do
    if entry.done? do
      # Create a unique filename with the original extension
      temp_filename = "temp_#{entry.uuid}#{Path.extname(entry.client_name)}"
      temp_path = Path.join("priv/static/uploads", temp_filename)

      # Ensure directory exists
      File.mkdir_p!(Path.dirname(temp_path))

      # Copy the uploaded file to our static directory
      File.cp!(entry.path, temp_path)

      # Create URL for the video that will be served by Plug.Static
      temp_video_url = "/media/#{temp_filename}"

      # Log upload completion
      IO.puts("Upload complete: #{temp_video_url}")
      IO.puts("File exists at #{temp_path}: #{File.exists?(temp_path)}")

      {:ok, temp_video_url}
    else
      {:in_progress, floor(entry.progress)}
    end
  end
  
  @doc """
  Handle upload errors.
  """
  def handle_upload_error(error) do
    IO.puts("Error in upload processing: #{inspect(error)}")
    {:error, "Error processing video: #{inspect(error)}"}
  end
end
