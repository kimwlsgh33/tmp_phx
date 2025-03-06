#!/bin/bash

# Create a directory to store the fixed files
mkdir -p fixed_controllers

# Copy the fixed controller files to the target directory
cp youtube_controller_fixed.ex fixed_controllers/youtube_controller.ex
cp twitter_controller_fixed.ex fixed_controllers/twitter_controller.ex
cp tiktok_controller_fixed.ex fixed_controllers/tiktok_controller.ex

# Add final changes to the YouTube controller - add the upload_form action if missing
cat > fixed_controllers/youtube_controller_updated.ex << 'EOF_YOUTUBE'
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
EOF_YOUTUBE

# Add a router update to ensure all routes are consistent
cat > fixed_controllers/router_updates.ex << 'EOF_ROUTER'
# Updated routes for social media controllers

# YouTube routes
get "/youtube", YoutubeController, :show
get "/youtube/upload", YoutubeController, :upload_form
post "/youtube/upload", YoutubeController, :upload_video
post "/youtube/search", YoutubeController, :search
get "/youtube/connect", YoutubeController, :connect
get "/youtube/auth/callback", YoutubeController, :auth_callback

# Twitter routes
get "/twitter", TwitterController, :show
get "/twitter/tweet", TwitterController, :tweet_form
post "/twitter/tweet", TwitterController, :post_tweet
get "/twitter/connect", TwitterController, :connect
get "/twitter/auth/callback", TwitterController, :auth_callback
delete "/twitter/tweet/:id", TwitterController, :delete_tweet

# Instagram routes
get "/instagram", InstagramController, :show
get "/instagram/upload", InstagramController, :upload_form
post "/instagram/upload", InstagramController, :upload_media
get "/instagram/connect", InstagramController, :connect
get "/instagram/auth/callback", InstagramController, :auth_callback

# TikTok routes
get "/tiktok", TiktokController, :show
get "/tiktok/upload", TiktokController, :upload_form
post "/tiktok/upload", TiktokController, :upload_video
get "/tiktok/connect", TiktokController, :connect
get "/tiktok/auth/callback", TiktokController, :auth_callback
EOF_ROUTER

# Create a summary of all the changes
cat > fixed_controllers/summary.md << 'EOF_SUMMARY'
# Social Media Controller Refactoring

## Standardized Changes Across Controllers

1. **Import Consistency**:
   - All controllers now consistently import the same set of functions from SocialMediaController
   - Added missing imports like check_auth, parse_hashtags, and get_expiry_datetime where needed

2. **Authentication Check**:
   - Standardized authentication verification using check_auth instead of direct API calls
   - Uniform pattern matching for authentication responses

3. **Media Upload Process**:
   - All controllers now follow the same process for validating and uploading media
   - Used consistent parameter handling and error handling patterns

4. **Controller Actions**:
   - Standardized the implementation of show, connect, auth_callback actions
   - Made upload_form and upload_media/upload_video actions consistent across platforms
   
5. **Error Handling**:
   - Consistent error handling patterns for authentication failures
   - Standardized error messages and redirects

6. **Route Structure**:
   - Updated router for consistency across all social media providers
   - Ensured action names match functionality (upload_media vs upload_video)

## Controller-Specific Fixes

1. **YoutubeController**:
   - Fixed handle_media_upload import to use 5 parameters (was 4)
   - Added upload_form action for consistency
   - Implemented proper media validation

2. **TwitterController**:
   - Switched from direct Twitter.authenticated? calls to check_auth
   - Added missing imports for full functionality
   - Standardized auth response handling

3. **TiktokController**:
   - Added missing imports for parse_hashtags, handle_post, etc.
   - Updated auth handling to match other controllers

4. **InstagramController**:
   - No major changes as it was already using check_auth and had all proper imports

## Benefits of Refactoring

1. **Maintainability**: Code is more consistent and follows the same patterns
2. **Extensibility**: Easier to add new social media platforms
3. **Bug Prevention**: Standardized error handling prevents platform-specific bugs
4. **Code Reuse**: Leveraging the shared SocialMediaController functionality
EOF_SUMMARY

echo "Fixed controllers and documentation created in the fixed_controllers directory"
