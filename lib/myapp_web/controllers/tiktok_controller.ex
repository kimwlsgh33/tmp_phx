defmodule MyappWeb.TiktokController do
  @moduledoc """
  Controller for TikTok-related web interface.
  
  This controller handles web requests related to TikTok functionality,
  providing a user interface for interacting with the TikTok API and
  related features implemented in the Myapp.SocialMedia.Tiktok module.
  """
  use MyappWeb, :controller
  
  alias Myapp.Tiktok
  alias Myapp.SocialMedia.Tiktok, as: SocialTiktok
  alias Myapp.Accounts.SocialMediaToken
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
    case Tiktok.validate_access_token([]) do
      {:ok, _access_token} ->
        # Create a new changeset for the upload form
        changeset = VideoUploadForm.changeset(%VideoUploadForm{})

        conn
        |> assign(:connected, true)
        |> assign(:changeset, changeset)
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
        
      _error ->
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

  @doc """
  Extracts the current user ID from the connection.
  
  This function retrieves the user ID from the session.
  
  ## Parameters
    * `conn` - The connection struct.
  
  ## Returns
    * The user ID as a string or integer.
  """
  def get_current_user_id(conn) do
    # In a real application, this would typically come from the session
    # For example: conn.assigns.current_user.id
    # Here we're using a simpler approach
    user_id = get_session(conn, :user_id) || 1
    user_id
  end

  @doc """
  Checks if the user is authenticated with the specified platform.
  
  This function verifies if the user has valid OAuth tokens for the platform.
  
  ## Parameters
    * `conn` - The connection struct.
    * `platform` - The social media platform (e.g., "tiktok").
    * `user_id` - The ID of the user to check.
  
  ## Returns
    * `{:ok, status}` - Status contains authentication information.
    * `{:error, reason}` - If an error occurs.
  """
  def check_auth(_conn, "tiktok", user_id) do
    SocialTiktok.authenticated?(user_id)
  end

  def check_auth(_conn, _platform, _user_id) do
    {:error, "Unsupported platform"}
  end

  @doc """
  Handles the OAuth connection for the specified platform.
  
  This function redirects the user to the platform's authorization page.
  
  ## Parameters
    * `conn` - The connection struct.
    * `platform` - The social media platform (e.g., "tiktok").
    * `params` - The parameters from the request.
  """
  def handle_connect(conn, "tiktok", _params) do
    # Store the current user ID in the session for later retrieval
    user_id = get_current_user_id(conn)
    conn = put_session(conn, :user_id, user_id)
    
    # Generate the authorization URL using the TiktokOauth module
    authorize_url = Myapp.TiktokOauth.authorize_url()
    
    # Redirect the user to TikTok's authorization page
    conn
    |> redirect(external: authorize_url)
  end

  def handle_connect(conn, platform, _params) do
    conn
    |> put_flash(:error, "Connection to #{platform} is not supported")
    |> redirect(to: ~p"/tiktok")
  end

  @doc """
  Handles the OAuth callback for the specified platform.
  
  This function processes the callback after authorization, exchanges the code
  for tokens, and stores the tokens in the database.
  
  ## Parameters
    * `conn` - The connection struct.
    * `platform` - The social media platform (e.g., "tiktok").
    * `params` - The parameters from the callback, including the code.
  """
  def handle_auth_callback(conn, "tiktok", %{"code" => code}) do
    user_id = get_current_user_id(conn)
    
    case Myapp.TiktokOauth.get_token(code) do
      {:ok, %{token: %{access_token: access_token, refresh_token: refresh_token, expires_in: expires_in}}} ->
        # Calculate when the token will expire
        expires_at = DateTime.add(DateTime.utc_now(), expires_in, :second)
        
        # Prepare token attributes
        token_attrs = %{
          access_token_text: access_token,
          refresh_token_text: refresh_token,
          expires_at: expires_at,
          platform: "tiktok",
          user_id: user_id,
          last_used_at: DateTime.utc_now(),
          metadata: %{} # Additional metadata can be stored here
        }
        
        # Check if a token already exists for this user and platform
        case SocialMediaToken.get_by_user_and_platform(user_id, "tiktok") |> Myapp.Repo.one() do
          nil ->
            # Create a new token
            %SocialMediaToken{}
            |> SocialMediaToken.changeset(token_attrs)
            |> Myapp.Repo.insert()
            
          existing_token ->
            # Update the existing token
            existing_token
            |> SocialMediaToken.update_changeset(token_attrs)
            |> Myapp.Repo.update()
        end
        
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
        
      _error ->
        conn
        |> put_flash(:error, "An unexpected error occurred during TikTok authentication")
        |> redirect(to: ~p"/tiktok")
    end
  end

  def handle_auth_callback(conn, "tiktok", %{"error" => error, "error_description" => description}) do
    conn
    |> put_flash(:error, "TikTok authorization failed: #{error} - #{description}")
    |> redirect(to: ~p"/tiktok")
  end

  def handle_auth_callback(conn, "tiktok", %{"error" => error}) do
    conn
    |> put_flash(:error, "TikTok authorization failed: #{error}")
    |> redirect(to: ~p"/tiktok")
  end

  def handle_auth_callback(conn, "tiktok", _params) do
    conn
    |> put_flash(:error, "Invalid TikTok authorization callback")
    |> redirect(to: ~p"/tiktok")
  end

  def handle_auth_callback(conn, platform, _params) do
    conn
    |> put_flash(:error, "Authentication callback for #{platform} is not supported")
    |> redirect(to: ~p"/tiktok")
  end
end

