defmodule MyappWeb.InstagramController do
  @moduledoc """
  Controller for Instagram-related web interface.
  
  This controller handles web requests related to Instagram functionality,
  providing a user interface for interacting with the Instagram API and
  related features implemented in the Myapp.Instagram module.
  """
  use MyappWeb, :controller
  
  alias Myapp.Instagram
  alias Myapp.InstagramOauth
  
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
    
    {connected, recent_media} = case Instagram.validate_access_token([]) do
      {:ok, _access_token} ->
        case Instagram.list_media() do
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
    case Instagram.validate_access_token([]) do
      {:ok, _access_token} ->
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
    
    case Instagram.validate_access_token([]) do
      {:ok, _access_token} ->
        # Validate the submitted form data
        changeset = UploadForm.changeset(%UploadForm{}, upload_params)
        
        if changeset.valid? do
          # First validate the upload to get the media path and type
          upload_result = 
            with {:ok, media_path, media_type} <- validate_upload(upload_params) do
              # Now that we have media_type, set up the options and function
              options = [
                caption: upload_params["caption"] || "",
                location: upload_params["location"] || "",
                hashtags: parse_hashtags(upload_params["hashtags"] || ""),
                media_type: media_type
              ]
              
              upload_func = case media_type do
                "image" -> 
                  if function_exported?(Instagram, :post_photo, 2) do
                    &Instagram.post_photo/2
                  else
                    &upload_media_fallback/2
                  end
                "video" ->
                  if function_exported?(Instagram, :post_video, 2) do
                    &Instagram.post_video/2
                  else
                    &upload_media_fallback/2
                  end
                _ ->
                  # This would handle the case where "upload_media" might exist as a generic function
                  if function_exported?(Instagram, :upload_media, 2) do
                    &Instagram.upload_media/2
                  else
                    &upload_media_fallback/2
                  end
              end
              
              # Call upload function with file path and options
              case upload_func.(media_path, options) do
                {:ok, response} -> {:ok, response}
                {:error, reason} -> {:error, reason}
              end
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
  def connect(conn, _params) do
    redirect_url = InstagramOauth.authorize_url()
    
    conn
    |> redirect(external: redirect_url)
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
  def auth_callback(conn, %{"code" => code}) do
    case InstagramOauth.get_token(code) do
      {:ok, token_info} ->
        # Store the token in the session or a more permanent storage
        # Include the expiration time for refresh token purposes
        conn = conn
          |> put_session(:instagram_token, token_info["access_token"])
          |> put_session(:instagram_token_expires_at, get_expiry_datetime(token_info["expires_in"]))
        
        # Save the token to application config for Instagram module to use
        Application.put_env(:myapp, Myapp.Instagram, 
          Keyword.put(Application.get_env(:myapp, Myapp.Instagram, []), 
                    :access_token, token_info["access_token"]))
        
        conn
        |> put_flash(:info, "Successfully connected to Instagram!")
        |> redirect(to: ~p"/instagram")
      
      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to connect to Instagram: #{reason}")
        |> redirect(to: ~p"/instagram")
    end
  end
  
  def auth_callback(conn, %{"error" => error, "error_description" => error_description}) do
    conn
    |> put_flash(:error, "Instagram authorization error: #{error} - #{error_description}")
    |> redirect(to: ~p"/instagram")
  end
  
  def auth_callback(conn, %{"error" => error}) do
    conn
    |> put_flash(:error, "Instagram authorization error: #{error}")
    |> redirect(to: ~p"/instagram")
  end
  
  def auth_callback(conn, _params) do
    conn
    |> put_flash(:error, "Invalid Instagram callback")
    |> redirect(to: ~p"/instagram")
  end
  
  # Calculates expiry datetime from seconds
  defp get_expiry_datetime(expires_in) when is_integer(expires_in) do
    DateTime.add(DateTime.utc_now(), expires_in, :second)
  end
  defp get_expiry_datetime(expires_in) when is_binary(expires_in) do
    case Integer.parse(expires_in) do
      {seconds, _} -> get_expiry_datetime(seconds)
      :error -> DateTime.add(DateTime.utc_now(), 30 * 24 * 60 * 60, :second) # Default to 30 days
    end
  end
  defp get_expiry_datetime(_), do: DateTime.add(DateTime.utc_now(), 30 * 24 * 60 * 60, :second)

  # Validates the media upload and returns the path to the temporary file and media type
  # Validates the media upload and returns the path to the temporary file and media type
  defp validate_upload(%{"media" => %Plug.Upload{} = upload}) do
    cond do
      upload.content_type in ["image/jpeg", "image/png", "image/jpg"] ->
        {:ok, upload.path, "image"}
      upload.content_type in ["video/mp4", "video/quicktime", "video/mov"] ->
        {:ok, upload.path, "video"}
      true ->
        {:error, "Invalid file format. Only JPEG, PNG images and MP4, MOV videos are supported."}
    end
  end
  defp validate_upload(%{media: %Plug.Upload{} = upload}) do
    cond do
      upload.content_type in ["image/jpeg", "image/png", "image/jpg"] ->
        {:ok, upload.path, "image"}
      upload.content_type in ["video/mp4", "video/quicktime", "video/mov"] ->
        {:ok, upload.path, "video"}
      true ->
        {:error, "Invalid file format. Only JPEG, PNG images and MP4, MOV videos are supported."}
    end
  end
  defp validate_upload(%{"media" => nil}), do: {:error, "No media file uploaded"}
  defp validate_upload(%{media: nil}), do: {:error, "No media file uploaded"}
  defp validate_upload(_), do: {:error, "No media file uploaded or invalid format"}
  # Parse hashtags from a comma-separated string
  defp parse_hashtags(hashtags_string) when is_binary(hashtags_string) do
    hashtags_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(String.length(&1) > 0))
  end
  defp parse_hashtags(_), do: []
  
  # Fallback function for upload_media when media type is unrecognized
  defp upload_media_fallback(media_path, options) do
    {:error, "Unsupported media type: #{options[:media_type]}"}
  end
  
end
