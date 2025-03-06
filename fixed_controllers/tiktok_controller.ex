defmodule MyappWeb.TiktokController do
  @moduledoc """
  Controller for TikTok-related web interface.
  
  This controller handles web requests related to TikTok functionality,
  providing a user interface for interacting with the TikTok API and
  related features implemented in the Myapp.SocialMedia.Tiktok module.
  """
  use MyappWeb, :controller
  
  import MyappWeb.SocialMediaController, only: [
    validate_provider: 1,
    handle_connect: 3,
    handle_auth_callback: 3,
    handle_media_upload: 5,
    validate_media_upload: 1,
    get_current_user_id: 1,
    check_auth: 3,
    parse_hashtags: 1,
    get_expiry_datetime: 1,
    handle_post: 5
  ]
  
  alias Myapp.SocialMedia.Tiktok
  alias Myapp.SocialAuth.Tiktok, as: TiktokAuth

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
    user_id = get_current_user_id(conn)
    {connected, recent_videos} = case check_auth(conn, "tiktok", user_id) do
      {:ok, _status} ->
        case Tiktok.list_videos(user_id) do
          {:ok, %{"data" => %{"videos" => videos}}} ->
            {true, videos}
          _ ->
            {true, []}
        end
      _ ->
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
    user_id = get_current_user_id(conn)
    case check_auth(conn, "tiktok", user_id) do
      {:ok, _status} ->
        conn
        |> assign(:connected, true)
        |> render(:upload_form)
      _ ->
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
    user_id = get_current_user_id(conn)
    case check_auth(conn, "tiktok", user_id) do
      {:ok, _status} ->
        # Validate the video upload
        case validate_media_upload(video_params) do
          {:ok, video_path, media_type} ->
            # Prepare options for the upload
            options = [
              title: video_params["title"] || "",
              description: video_params["description"] || "",
              privacy_level: video_params["privacy_level"] || "public",
              disable_comments: video_params["allow_comment"] != "true",
              disable_stitch: video_params["allow_stitch"] != "true",
              disable_duet: video_params["allow_duet"] != "true"
            ]
            
            case handle_media_upload(conn, "tiktok", video_path, options, user_id) do
              {:ok, response} ->
                conn
                |> put_flash(:info, "Video successfully uploaded to TikTok")
                |> redirect(to: ~p"/tiktok")
              {:error, reason} ->
                conn
                |> put_flash(:error, "Failed to upload video: #{reason}")
                |> redirect(to: ~p"/tiktok/upload")
            end
            
          {:error, reason} ->
            conn
            |> put_flash(:error, "Failed to upload video: #{reason}")
            |> redirect(to: ~p"/tiktok/upload")
        end

      _ ->
        conn
        |> put_flash(:error, "You need to connect to TikTok before uploading videos")
        |> redirect(to: ~p"/tiktok")
    end
  end

  @doc """
  Initiates the OAuth flow to connect to TikTok.

  This action redirects the user to the TikTok OAuth consent page.
  """
  def connect(conn, params) do
    handle_connect(conn, "tiktok", params)
  end

  @doc """
  Handles the OAuth callback from TikTok.

  This action processes the OAuth callback, exchanges the code for tokens,
  and stores the tokens in the session.

  Params:
    * `code` - The authorization code returned by TikTok
  """
  def auth_callback(conn, params) do
    handle_auth_callback(conn, "tiktok", params)
  end
end
