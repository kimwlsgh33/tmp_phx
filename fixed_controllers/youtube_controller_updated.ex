defmodule MyappWeb.YoutubeController do
  @moduledoc """
  Controller for YouTube-related web interface.
  
  This controller handles web requests related to YouTube functionality,
  providing a user interface for interacting with the YouTube API and
  related features.
  """
  use MyappWeb, :controller
  
  import MyappWeb.SocialMediaController, only: [
    validate_provider: 1,
    handle_connect: 3,
    handle_auth_callback: 3,
    handle_media_upload: 5,
    validate_media_upload: 1,
    check_auth: 3,
    parse_hashtags: 1,
    get_current_user_id: 1,
    get_expiry_datetime: 1,
    handle_post: 5
  ]
  
  alias Myapp.SocialMedia.Youtube
  alias Myapp.SocialAuth.Youtube, as: YoutubeAuth

  @doc """
  Renders the YouTube page.
  
  This action displays the main YouTube interface where users can interact
  with YouTube-related features such as searching videos, uploading videos,
  and viewing account details.
  
  Assigns:
    * `connected` - Boolean indicating whether the user is connected to YouTube
    * `videos` - List of videos if search was performed
    * `video_details` - Details of the first video if available
  """
  def show(conn, params) do
    user_id = get_current_user_id(conn)
    api_key = get_youtube_api_key(conn)
    query = Map.get(params, "query", "")
    
    {connected, _tokens} = case check_auth(conn, "youtube", user_id) do
      {:ok, status} -> {true, status}
      _ -> {false, nil}
    end

    conn = assign(conn, :connected, connected)
    
    cond do
      connected == false && api_key == "" ->
        # Not connected and no API key
        conn
        |> assign(:videos, [])
        |> assign(:video_details, nil)
        |> assign(:api_key, "")
        |> render(:show)

      query == "" ->
        # No search query
        conn
        |> assign(:videos, [])
        |> assign(:video_details, nil) 
        |> assign(:api_key, api_key)
        |> render(:show)

      true ->
        # Perform search
        case Youtube.search_videos(query, api_key: api_key, user_id: user_id) do
          {:ok, videos} ->
            video_details = get_first_video_details(videos, api_key, user_id)

            conn
            |> assign(:videos, videos)
            |> assign(:video_details, video_details)
            |> assign(:api_key, api_key)
            |> render(:show)

          {:error, message} ->
            conn
            |> put_flash(:error, "YouTube API Error: #{message}")
            |> assign(:videos, [])
            |> assign(:video_details, nil)
            |> assign(:api_key, api_key)
            |> render(:show)
        end
    end
  end

  @doc """
  Handles the search form submission.
  
  Redirects to the show action with search parameters.
  """
  def search(conn, params) do
    redirect(conn, to: ~p"/youtube?#{%{query: params["query"]}}")
  end
  
  @doc """
  Renders the video upload form.
  
  This action displays a form where users can upload videos to YouTube.
  It first checks if the user is connected to YouTube (authenticated)
  before rendering the form.
  
  Assigns:
    * `connected` - Boolean indicating whether the user is connected to YouTube
  """
  def upload_form(conn, _params) do
    user_id = get_current_user_id(conn)
    case check_auth(conn, "youtube", user_id) do
      {:ok, _status} ->
        conn
        |> assign(:connected, true)
        |> render(:upload_form)
      _ ->
        conn
        |> put_flash(:error, "You need to connect to YouTube before uploading videos")
        |> redirect(to: ~p"/youtube")
    end
  end
  
  @doc """
  Processes the video upload form submission.
  
  This action handles the video uploading by:
  1. Validating the submitted content and video file
  2. Uploading the video to YouTube via the Youtube module
  3. Redirecting back with appropriate success/error messages
  """
  def upload_video(conn, %{"video" => video_params}) do
    user_id = get_current_user_id(conn)
    case check_auth(conn, "youtube", user_id) do
      {:ok, _status} ->
        # Validate the uploaded file
        case validate_media_upload(video_params) do
          {:ok, video_path, media_type} ->
            title = video_params["title"] || ""
            description = video_params["description"] || ""
            category_id = video_params["category_id"] || "22" # Default to 'People & Blogs'
            
            case handle_media_upload(conn, "youtube", video_path, [
              title: title,
              description: description,
              category_id: category_id,
              privacy_status: video_params["privacy_status"] || "private"
            ], user_id) do
              {:ok, response} ->
                conn
                |> put_flash(:info, "Video successfully uploaded to YouTube")
                |> redirect(to: ~p"/youtube")
              {:error, reason} ->
                conn
                |> put_flash(:error, "Failed to upload video: #{reason}")
                |> redirect(to: ~p"/youtube/upload")
            end
            
          {:error, reason} ->
            conn
            |> put_flash(:error, "Failed to validate video: #{reason}")
            |> redirect(to: ~p"/youtube/upload")
        end
      _ ->
        conn
        |> put_flash(:error, "You need to connect to YouTube before uploading videos")
        |> redirect(to: ~p"/youtube")
    end
  end
  
  @doc """
  Initiates the OAuth flow to connect to YouTube.
  
  This action redirects the user to the YouTube OAuth consent page.
  """
  def connect(conn, params) do
    handle_connect(conn, "youtube", params)
  end
  
  @doc """
  Handles the OAuth callback from YouTube.
  
  This action processes the OAuth callback, exchanges the code for tokens,
  and stores the tokens in the session.
  """
  def auth_callback(conn, params) do
    handle_auth_callback(conn, "youtube", params)
  end

  # Private functions
  
  defp get_youtube_api_key(conn) do
    # First try to get from session, then fallback to environment
    get_session(conn, :youtube_api_key) ||
      Application.get_env(:myapp, :youtube_api_key, "")
  end

  defp get_first_video_details([], _api_key, _user_id), do: nil

  defp get_first_video_details([%{id: video_id} | _], api_key, user_id) do
    case Youtube.get_video_details(video_id, api_key: api_key, user_id: user_id) do
      {:ok, details} -> details
      {:error, _message} -> nil
    end
  end
end
