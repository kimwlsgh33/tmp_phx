defmodule MyappWeb.TiktokController do
  @moduledoc """
  Controller for TikTok-related web interface.
  
  This controller handles web requests related to TikTok functionality,
  providing a user interface for interacting with the TikTok API and
  related features implemented in the Myapp.Tiktok module.
  """
  use MyappWeb, :controller
  
  alias Myapp.Tiktok
  alias Myapp.TiktokOauth

  @doc """
  Renders the TikTok page.
  
  This action displays the main TikTok interface where users can interact
  with TikTok-related features such as video uploads, account management,
  and other TikTok API functionality.
  
  Assigns:
    * `connected` - Boolean indicating whether the user is connected to TikTok
    * `recent_videos` - List of recent TikTok videos if connected
  """
  def show(conn, _params) do
    {connected, recent_videos} = case Tiktok.validate_access_token([]) do
      {:ok, _access_token} ->
        case Tiktok.list_videos() do
          {:ok, %{"data" => %{"videos" => videos}}} ->
            {true, videos}
          _ ->
            {true, []}
        end
      {:error, _reason} ->
        {false, []}
    end
    
    conn
    |> assign(:connected, connected)
    |> assign(:recent_videos, recent_videos)
    |> render(:show)
  end

  @doc """
  Renders the TikTok video upload form.

  This action displays a form where users can upload videos to TikTok.
  It first checks if the user is connected to TikTok (authenticated)
  before rendering the form.

  Assigns:
    * `connected` - Boolean indicating whether the user is connected to TikTok
  """
  def upload_form(conn, _params) do
    case Tiktok.validate_access_token([]) do
      {:ok, _access_token} ->
        conn
        |> assign(:connected, true)
        |> render(:upload_form)
      {:error, _reason} ->
        conn
        |> put_flash(:error, "You need to connect to TikTok before uploading videos")
        |> redirect(to: ~p"/tiktok")
    end
  end

  @doc """
  Processes the TikTok video upload form submission.

  This action handles the video upload processing by:
  1. Validating the uploaded file
  2. Uploading the video to TikTok via the Tiktok module
  3. Redirecting back with appropriate success/error messages

  Params:
    * `video` - The video file upload params
    * `title` - Title for the video
    * `description` - Description for the video
  """
  def upload_video(conn, %{"video" => video_params} = _params) do
    case Tiktok.validate_access_token([]) do
      {:ok, _access_token} ->
        upload_result = 
          with {:ok, video_path} <- validate_upload(video_params),
               # Prepare options map with remaining parameters
               # Prepare options as keyword list with correctly mapped parameters
               options = [
                 title: video_params["title"] || "",
                 description: video_params["description"] || "",
                 privacy_level: video_params["privacy_level"] || "public",
                 # Invert the logic for 'allow_' fields to 'disable_' fields
                 disable_comments: video_params["allow_comment"] != "true",
                 disable_stitch: video_params["allow_stitch"] != "true",
                 disable_duet: video_params["allow_duet"] != "true"
               ],
               # Call upload_video with file path as first param and options as keyword list
               {:ok, response} <- Tiktok.upload_video(video_path, options) do
            {:ok, response}
          else
            {:error, reason} -> {:error, reason}
          end

        case upload_result do
          {:ok, _response} ->
            conn
            |> put_flash(:info, "Video successfully uploaded to TikTok")
            |> redirect(to: ~p"/tiktok")
          {:error, reason} ->
            conn
            |> put_flash(:error, "Failed to upload video: #{reason}")
            |> redirect(to: ~p"/tiktok/upload")
        end

      {:error, _reason} ->
        conn
        |> put_flash(:error, "You need to connect to TikTok before uploading videos")
        |> redirect(to: ~p"/tiktok")
    end
  end

  # Validates the video upload and returns the path to the temporary file
  defp validate_upload(%{"file" => %Plug.Upload{} = upload}) do
    if upload.content_type in ["video/mp4", "video/quicktime", "video/mov"] do
      {:ok, upload.path}
    else
      {:error, "Invalid file format. Only MP4, MOV, and QuickTime videos are supported."}
    end
  end
  defp validate_upload(%{file: %Plug.Upload{} = upload}) do
    if upload.content_type in ["video/mp4", "video/quicktime", "video/mov"] do
      {:ok, upload.path}
    else
      {:error, "Invalid file format. Only MP4, MOV, and QuickTime videos are supported."}
    end
  end
  defp validate_upload(%{"file" => nil}), do: {:error, "No video file uploaded"}
  defp validate_upload(%{file: nil}), do: {:error, "No video file uploaded"}
  defp validate_upload(_), do: {:error, "No video file uploaded or invalid format"}
end


