defmodule MyappWeb.InstagramController do
  @moduledoc """
  Controller for Instagram-related web interface.
  
  This controller handles web requests related to Instagram functionality,
  providing a user interface for interacting with the Instagram API and
  related features implemented in the Myapp.SocialMedia.Instagram module.
  """
  use MyappWeb, :controller
  
  import MyappWeb.SocialMediaController, only: [
    handle_connect: 3,
    handle_auth_callback: 3,
    handle_media_upload: 5,
    validate_media_upload: 1,
    parse_hashtags: 1,
    get_current_user_id: 1,
    check_auth: 3
  ]
  
  alias Myapp.SocialMedia.Instagram
  
  # Define a struct for Instagram uploads for form handling
  defmodule UploadForm do
    use Ecto.Schema
    import Ecto.Changeset
    
    embedded_schema do
      field :media_type, :string, default: "IMAGE"
      field :media, :any, virtual: true
      field :caption, :string
      field :location, :string
      field :hashtags, :string
      field :share_to_feed, :boolean, default: true
    end
    
    @doc """
    Creates a changeset for Instagram media uploads.
    """
    def changeset(upload_form, attrs \\ %{}) do
      upload_form
      |> cast(attrs, [:media_type, :caption, :location, :hashtags, :share_to_feed])
      |> validate_required([:media_type])
      |> validate_inclusion(:media_type, ["IMAGE", "VIDEO", "CAROUSEL_ALBUM"])
      |> validate_length(:caption, max: 2200, message: "Caption must be 2200 characters or less")
    end
  end

  @doc """
  Renders the Instagram page with both dashboard and upload form.
  
  This action displays the main Instagram interface where users can interact
  with Instagram-related features such as media uploads, account management,
  and other Instagram API functionality.
  
  Assigns:
    * `connected` - Boolean indicating whether the user is connected to Instagram
    * `recent_media` - List of recent Instagram posts if connected
    * `changeset` - Form changeset for media uploads
    * `error` - Any error messages from previous upload attempts
    * `success` - Boolean indicating if an upload was successful
  """
  def show(conn, params) do
    # Create a changeset for the upload form
    changeset = UploadForm.changeset(%UploadForm{}, params["upload_form"] || %{})
    
    # Get error and success flash messages if present
    error = get_flash(conn, :error)
    success = get_flash(conn, :info) != nil
    
    user_id = get_current_user_id(conn)
    {connected, recent_media} = case check_auth(conn, "instagram", user_id) do
      {:ok, _status} ->
        case Instagram.list_media(user_id) do
          {:ok, %{"data" => media}} ->
            {true, media}
          _ ->
            {true, []}
        end
      {:error, _reason} ->
        {false, []}
    end
    
    conn
    |> assign(:connected, connected)
    |> assign(:recent_media, recent_media)
    |> assign(:changeset, changeset)
    |> assign(:error, error)
    |> assign(:success, success)
    |> render(:show)
  end

  @doc """
  Renders the Instagram media upload form.

  This action displays a form where users can upload photos or videos to Instagram.
  It first checks if the user is connected to Instagram (authenticated)
  before rendering the form.

  Assigns:
    * `connected` - Boolean indicating whether the user is connected to Instagram
  """
  def upload_form(conn, params) do
    user_id = get_current_user_id(conn)
    case check_auth(conn, "instagram", user_id) do
      {:ok, _status} ->
        # Create a new changeset for the form
        changeset = UploadForm.changeset(%UploadForm{}, params["upload"] || %{})
        
        conn
        |> assign(:connected, true)
        |> assign(:changeset, changeset)
        |> assign(:error, nil)
        |> assign(:success, false)
        |> render(:upload_form)
      {:error, reason} ->
        conn
        |> put_flash(:error, "You need to connect to Instagram before uploading media: #{reason}")
        |> redirect(to: ~p"/instagram")
    end
  end

  @doc """
  Processes the Instagram media upload form submission.

  This action handles the media upload processing by:
  1. Validating the uploaded file (image or video)
  2. Uploading the media to Instagram via the Instagram module
  3. Redirecting back with appropriate success/error messages

  Params:
    * `media` - The media file upload params
    * `caption` - Caption for the post
    * `location` - Optional location information
  """
  def upload_media(conn, params) do
    upload_params = params["upload_form"] || %{}
    user_id = get_current_user_id(conn)
    
    case check_auth(conn, "instagram", user_id) do
      {:ok, _status} ->
        # Validate the submitted form data
        changeset = UploadForm.changeset(%UploadForm{}, upload_params)
        
        if changeset.valid? do
          # First validate the upload to get the media path and type
          upload_result = 
            with {:ok, media_path, media_type} <- validate_media_upload(upload_params) do
              # Now that we have media_type, set up the options and function
              options = [
                caption: upload_params["caption"] || "",
                location: upload_params["location"] || "",
                hashtags: parse_hashtags(upload_params["hashtags"] || ""),
                media_type: media_type,
                share_to_feed: upload_params["share_to_feed"] == "true"
              ]
              
              # Use the shared media upload handler
              handle_media_upload(conn, "instagram", media_path, options, user_id)
            else
              {:error, reason} -> {:error, reason}
            end
          case upload_result do
            {:ok, _response} ->
              conn
              |> put_flash(:info, "Media successfully uploaded to Instagram")
              |> redirect(to: ~p"/instagram")
            {:error, reason} ->
              # Redirect back to the main Instagram page with error
              conn
              |> put_flash(:error, "Failed to upload media: #{reason}")
              |> redirect(to: ~p"/instagram")
          end
        else
          # Redirect back to the main Instagram page with validation errors
          conn
          |> put_flash(:error, "Please fix the errors in the form")
          |> redirect(to: ~p"/instagram")
        end

      {:error, reason} ->
        conn
        |> put_flash(:error, "You need to connect to Instagram before uploading media: #{reason}")
        |> redirect(to: ~p"/instagram")
    end
  end

  @doc """
  Initiates the Instagram OAuth flow.
  
  Redirects the user to Instagram's authorization page where they will be asked
  to grant permission to access their Instagram account and media.
  """
  def connect(conn, params) do
    handle_connect(conn, "instagram", params)
  end

  @doc """
  Handles the OAuth callback from Instagram.
  
  This action processes the OAuth callback after a user authorizes the application
  on Instagram. It exchanges the authorization code for an access token and
  stores it for future requests.
  
  Params:
    * `code` - The authorization code returned by Instagram
    * `error` - Any error returned by Instagram
  """
  def auth_callback(conn, params) do
    handle_auth_callback(conn, "instagram", params)
  end
  

  
end
