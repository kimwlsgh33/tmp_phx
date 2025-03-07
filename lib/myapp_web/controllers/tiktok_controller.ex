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
  # No need to import to_form since we're passing the changeset directly
  
  # Define the video upload form schema
  defmodule VideoUploadForm do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :video, :any, virtual: true
      field :title, :string
      field :description, :string
      field :privacy, :string, default: "public"
      field :schedule_time, :boolean, default: false
      field :scheduled_publish_time, :utc_datetime
      field :disable_comments, :boolean, default: false
      field :disable_duet, :boolean, default: false
      field :disable_stitch, :boolean, default: false
    end

    def changeset(form, attrs \\ %{}) do
      form
      |> cast(attrs, [:title, :description, :privacy, :schedule_time, 
                     :scheduled_publish_time, :disable_comments, 
                     :disable_duet, :disable_stitch])
      |> validate_required([:title, :privacy])
    end
  end

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
        # Create a new changeset for the upload form
        changeset = VideoUploadForm.changeset(%VideoUploadForm{})

        conn
        |> assign(:connected, true)
        |> assign(:changeset, changeset)
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
  def upload_video(conn, %{"video_upload_form" => video_params}) do
    case Tiktok.validate_access_token([]) do
      {:ok, _access_token} ->
        changeset = VideoUploadForm.changeset(%VideoUploadForm{}, video_params)

        if changeset.valid? do
          upload_params = %{"file" => video_params["video"]}
          
          upload_result = 
            with {:ok, video_path} <- validate_upload(upload_params),
                 # Configure options for the TikTok upload
                 options = [
                   title: video_params["title"] || "",
                   description: video_params["description"] || "",
                   privacy_level: video_params["privacy"] || "public",
                   disable_comments: video_params["disable_comments"] == "true",
                   disable_stitch: video_params["disable_stitch"] == "true",
                   disable_duet: video_params["disable_duet"] == "true"
                 ],
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
        else
          # If changeset is invalid, render the form with errors
          conn
          |> assign(:connected, true)
          |> assign(:changeset, changeset)
          |> put_flash(:error, "Please fix the errors in the form")
          |> render(:upload_form)
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

  @doc """
  Initiates the TikTok OAuth process by redirecting to TikTok's authorization page.

  This action starts the OAuth flow by generating the TikTok authorization URL
  and redirecting the user to it. Once the user authorizes the application,
  TikTok will redirect back to the callback URL configured in the TiktokOauth module.
  """
  def oauth_request(conn, _params) do
    # Generate the authorization URL using the TiktokOauth module
    authorize_url = Myapp.TiktokOauth.authorize_url()
    
    # Redirect the user to TikTok's authorization page
    conn
    |> redirect(external: authorize_url)
  end

  @doc """
  Handles the callback from TikTok after OAuth authorization.

  This action processes the callback from TikTok after the user has authorized
  the application. It exchanges the authorization code for an access token,
  stores the token, and then redirects the user back to the TikTok dashboard.

  Params:
    * `code` - The authorization code from TikTok
    * `error` - Error information if authorization failed
  """
  def oauth_callback(conn, %{"code" => code}) do
    case Myapp.TiktokOauth.get_token(code) do
      {:ok, %{token: %{access_token: access_token}}} ->
        # Store the access token in the application configuration for future use
        # In a production app, you would store this in a database associated with the user
        Application.put_env(:myapp, Myapp.Tiktok, 
          Application.get_env(:myapp, Myapp.Tiktok, []) 
          |> Keyword.put(:access_token, access_token))
        
        conn
        |> put_flash(:info, "Successfully connected to TikTok!")
        |> redirect(to: ~p"/tiktok")
        
      {:error, %{body: error_body}} ->
        error_message = case Jason.decode(error_body) do
          {:ok, %{"error" => %{"message" => message}}} -> message
          _ -> "Failed to obtain access token"
        end
        
        conn
        |> put_flash(:error, "TikTok authentication failed: #{error_message}")
        |> redirect(to: ~p"/tiktok")
        
      error ->
        conn
        |> put_flash(:error, "An unexpected error occurred during TikTok authentication")
        |> redirect(to: ~p"/tiktok")
    end
  end

  # Handle the case where TikTok returns an error
  def oauth_callback(conn, %{"error" => error, "error_description" => description}) do
    conn
    |> put_flash(:error, "TikTok authorization failed: #{error} - #{description}")
    |> redirect(to: ~p"/tiktok")
  end

  # Handle the case where TikTok returns an error without a description
  def oauth_callback(conn, %{"error" => error}) do
    conn
    |> put_flash(:error, "TikTok authorization failed: #{error}")
    |> redirect(to: ~p"/tiktok")
  end

  # Handle unexpected callback parameters
  def oauth_callback(conn, _params) do
    conn
    |> put_flash(:error, "Invalid TikTok authorization callback")
    |> redirect(to: ~p"/tiktok")
  end
end



