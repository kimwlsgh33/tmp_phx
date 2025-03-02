defmodule Myapp.Instagram do
  @moduledoc """
  Instagram API integration for media uploads and management.
  
  This module provides functions for authenticating with Instagram,
  uploading photos/videos, fetching media, and managing posts.
  
  ## API Token Usage
  
  All functions accept an `:access_token` parameter in their options. The token can be provided in two ways:
  
  1. Server Configuration:
     Configure a default access token in your application config:
     ```elixir
     config :myapp, Myapp.Instagram,
       access_token: System.get_env("INSTAGRAM_ACCESS_TOKEN"),
       client_id: System.get_env("INSTAGRAM_CLIENT_ID"),
       client_secret: System.get_env("INSTAGRAM_CLIENT_SECRET")
     ```
  
  2. Per-Request Token:
     Provide an access token directly in the function call:
     ```elixir
     Instagram.post_media("path/to/image.jpg", access_token: "your_instagram_token")
     ```
  
  At least one of these methods must be used. If neither is provided, an error will be raised.
  The per-request token takes precedence over the server configuration when both are present.
  """
  
  require Logger
  
  @base_url "https://graph.instagram.com/v18.0"
  
  @doc """
  Posts a photo to Instagram.
  
  ## Parameters
    * `image_path` - Path to the image file to upload
    * `opts` - Optional parameters:
        * `:access_token` - Instagram access token
        * `:caption` - Image caption (default: "")
        * `:location_id` - Location ID for the post (default: nil)
        * `:user_tags` - List of user tags (default: [])
  
  ## Returns
    * `{:ok, media_id}` - Successfully uploaded
    * `{:error, reason}` - Upload failed
  """
  def post_photo(image_path, opts \\ []) do
    case validate_access_token(opts) do
      {:ok, access_token} ->
        if File.exists?(image_path) do
          caption = Keyword.get(opts, :caption, "")
          location_id = Keyword.get(opts, :location_id)
          user_tags = Keyword.get(opts, :user_tags, [])
          
          # First create a container for the media
          case create_media_container("IMAGE", image_path, caption, location_id, user_tags, access_token) do
            {:ok, %{"id" => creation_id}} ->
              # Then publish the container
              publish_media(creation_id, access_token)
            
            error -> error
          end
        else
          {:error, "Image file not found: #{image_path}"}
        end
        
      {:error, message} ->
        {:error, message}
    end
  end
  
  @doc """
  Posts a video to Instagram.
  
  ## Parameters
    * `video_path` - Path to the video file to upload
    * `opts` - Optional parameters:
        * `:access_token` - Instagram access token
        * `:caption` - Video caption (default: "")
        * `:location_id` - Location ID for the post (default: nil)
        * `:user_tags` - List of user tags (default: [])
        * `:cover_image_path` - Path to cover image (default: nil)
  
  ## Returns
    * `{:ok, media_id}` - Successfully uploaded
    * `{:error, reason}` - Upload failed
  """
  def post_video(video_path, opts \\ []) do
    case validate_access_token(opts) do
      {:ok, access_token} ->
        if File.exists?(video_path) do
          caption = Keyword.get(opts, :caption, "")
          location_id = Keyword.get(opts, :location_id)
          user_tags = Keyword.get(opts, :user_tags, [])
          cover_image_path = Keyword.get(opts, :cover_image_path)
          
          # Additional check for the cover image if provided
          if cover_image_path && !File.exists?(cover_image_path) do
            {:error, "Cover image file not found: #{cover_image_path}"}
          else
            # First create a container for the media
            case create_media_container("VIDEO", video_path, caption, location_id, user_tags, access_token, cover_image_path) do
              {:ok, %{"id" => creation_id}} ->
                # Then publish the container
                publish_media(creation_id, access_token)
              
              error -> error
            end
          end
        else
          {:error, "Video file not found: #{video_path}"}
        end
        
      {:error, message} ->
        {:error, message}
    end
  end
  
  @doc """
  Creates a media container for Instagram media upload.
  
  ## Parameters
    * `media_type` - Type of media ("IMAGE" or "VIDEO")
    * `media_path` - Path to the media file
    * `caption` - Caption for the media
    * `location_id` - Location ID (optional)
    * `user_tags` - List of user tags (optional)
    * `access_token` - Instagram access token
    * `cover_image_path` - Path to cover image for videos (optional)
  
  ## Returns
    * `{:ok, %{"id" => creation_id}}` - Successfully created container
    * `{:error, reason}` - Container creation failed
  """
  def create_media_container(media_type, media_path, caption, location_id, user_tags, access_token, cover_image_path \\ nil) do
    url = "#{@base_url}/me/media"
    
    # Create the base payload
    payload = %{
      "media_type" => media_type,
      "image_url" => media_path,
      "caption" => caption
    }
    
    # Add optional fields if provided
    payload = if location_id, do: Map.put(payload, "location_id", location_id), else: payload
    payload = if user_tags && user_tags != [], do: Map.put(payload, "user_tags", user_tags), else: payload
    
    # For videos, we need to change image_url to video_url and add thumbnail_url if provided
    payload = if media_type == "VIDEO" do
      payload
      |> Map.delete("image_url")
      |> Map.put("video_url", media_path)
      |> (fn p -> if cover_image_path, do: Map.put(p, "thumbnail_url", cover_image_path), else: p end).()
    else
      payload
    end
    
    headers = [
      {"Content-Type", "application/json"}
    ]
    
    query_params = [
      access_token: access_token
    ]
    
    url_with_params = "#{url}?#{URI.encode_query(query_params)}"
    body = Jason.encode!(payload)
    
    case HTTPoison.post(url_with_params, body, headers) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} when status_code in 200..299 ->
        case Jason.decode(response_body) do
          {:ok, response} -> {:ok, response}
          {:error, _} -> {:error, "Failed to parse Instagram response"}
        end
        
      {:ok, %HTTPoison.Response{status_code: 401}} ->
        {:error, "Invalid access token. Please check your credentials."}
        
      {:ok, %HTTPoison.Response{status_code: 403}} ->
        {:error, "Permission denied. Your app may not have media publishing permission."}
        
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Instagram media container creation error: Status #{status_code}, Body: #{body}")
        {:error, "Instagram API error: #{status_code}"}
        
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Instagram API connection error: #{inspect(reason)}")
        {:error, "Failed to connect to Instagram API. Please check your internet connection."}
    end
  end
  
  @doc """
  Publishes a media container to make it visible on Instagram.
  
  ## Parameters
    * `creation_id` - ID from create_media_container
    * `access_token` - Instagram access token
  
  ## Returns
    * `{:ok, %{"id" => media_id}}` - Successfully published
    * `{:error, reason}` - Publishing failed
  """
  def publish_media(creation_id, access_token) do
    url = "#{@base_url}/me/media_publish"
    
    query_params = [
      creation_id: creation_id,
      access_token: access_token
    ]
    
    url_with_params = "#{url}?#{URI.encode_query(query_params)}"
    
    headers = [
      {"Content-Type", "application/json"}
    ]
    
    case HTTPoison.post(url_with_params, "", headers) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} when status_code in 200..299 ->
        case Jason.decode(response_body) do
          {:ok, response} -> {:ok, response}
          {:error, _} -> {:error, "Failed to parse Instagram response"}
        end
        
      {:ok, %HTTPoison.Response{status_code: 401}} ->
        {:error, "Invalid access token. Please check your credentials."}
        
      {:ok, %HTTPoison.Response{status_code: 403}} ->
        {:error, "Permission denied. Your app may not have media publishing permission."}
        
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Instagram media publish error: Status #{status_code}, Body: #{body}")
        {:error, "Instagram API error: #{status_code}"}
        
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Instagram API connection error: #{inspect(reason)}")
        {:error, "Failed to connect to Instagram API. Please check your internet connection."}
    end
  end
  
  @doc """
  Gets information about a specific media post.
  
  ## Parameters
    * `media_id` - ID of the media to get information about
    * `opts` - Optional parameters:
        * `:access_token` - Instagram access token
        * `:fields` - Fields to retrieve (default: "id,caption,media_type,media_url,permalink,thumbnail_url,timestamp,username")
  
  ## Returns
    * `{:ok, media_info}` - Successfully retrieved media info
    * `{:error, reason}` - Retrieval failed
  """
  def get_media(media_id, opts \\ []) do
    case validate_access_token(opts) do
      {:ok, access_token} ->
        fields = Keyword.get(opts, :fields, "id,caption,media_type,media_url,permalink,thumbnail_url,timestamp,username")
        
        url = "#{@base_url}/#{media_id}"
        
        query_params = [
          fields: fields,
          access_token: access_token
        ]
        
        url_with_params = "#{url}?#{URI.encode_query(query_params)}"
        
        headers = [
          {"Content-Type", "application/json"}
        ]
        
        case HTTPoison.get(url_with_params, headers) do
          {:ok, %HTTPoison.Response{status_code: status_code, body: body}} when status_code in 200..299 ->
            case Jason.decode(body) do
              {:ok, response} -> {:ok, response}
              {:error, _} -> {:error, "Failed to parse Instagram response"}
            end
            
          {:ok, %HTTPoison.Response{status_code: 401}} ->
            {:error, "Invalid access token. Please check your credentials."}
            
          {:ok, %HTTPoison.Response{status_code: 404}} ->
            {:error, "Media not found"}
            
          {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
            Logger.error("Instagram API error: Status #{status_code}, Body: #{response_body}")
            {:error, "Instagram API error: #{status_code}"}
            
          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("Instagram API connection error: #{inspect(reason)}")
            {:error, "Failed to connect to Instagram API. Please check your internet connection."}
        end
        
      {:error, message} ->
        {:error, message}
    end
  end
  
  @doc """
  Lists media for the authenticated user.
  
  ## Parameters
    * `opts` - Optional parameters:
        * `:access_token` - Instagram access token
        * `:limit` - Maximum number of media to return (default: 25)
        * `:after` - Pagination cursor for getting the next page
        * `:fields` - Fields to retrieve (default: "id,caption,media_type,media_url,permalink,thumbnail_url,timestamp,username")
  
  ## Returns
    * `{:ok, %{"data" => [...], "paging" => %{"cursors" => %{"after" => cursor}}}}` - Successfully retrieved media
    * `{:error, reason}` - Retrieval failed
  """
  def list_media(opts \\ []) do
    case validate_access_token(opts) do
      {:ok, access_token} ->
        limit = Keyword.get(opts, :limit, 25)
        after_cursor = Keyword.get(opts, :after)
        fields = Keyword.get(opts, :fields, "id,caption,media_type,media_url,permalink,thumbnail_url,timestamp,username")
        
        url = "#{@base_url}/me/media"
        
        query_params = [
          fields: fields,
          limit: limit,
          access_token: access_token
        ]
        
        # Add after cursor if provided
        query_params = if after_cursor, do: Keyword.put(query_params, :after, after_cursor), else: query_params
        
        url_with_params = "#{url}?#{URI.encode_query(query_params)}"
        
        headers = [
          {"Content-Type", "application/json"}
        ]
        
        case HTTPoison.get(url_with_params, headers) do
          {:ok, %HTTPoison.Response{status_code: status_code, body: body}} when status_code in 200..299 ->
            case Jason.decode(body) do
              {:ok, response} -> {:ok, response}
              {:error, _} -> {:error, "Failed to parse Instagram response"}
            end
            
          {:ok, %HTTPoison.Response{status_code: 401}} ->
            {:error, "Invalid access token. Please check your credentials."}
            
          {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
            Logger.error("Instagram API error: Status #{status_code}, Body: #{response_body}")
            {:error, "Instagram API error: #{status_code}"}
            
          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("Instagram API connection error: #{inspect(reason)}")
            {:error, "Failed to connect to Instagram API. Please check your internet connection."}
        end
        
      {:error, message} ->
        {:error, message}
    end
  end
  
  @doc """
  Validates the access token from options or application config.
  
  ## Parameters
    * `opts` - Options containing potential access_token key
  
  ## Returns
    * `{:ok, access_token}` - Valid token found
    * `{:error, reason}` - No valid token found
  """
  def validate_access_token(opts) do
    case Keyword.get(opts, :access_token) do
      nil ->
        # Try to get from config
        case Application.get_env(:myapp, Myapp.Instagram) do
          nil ->
            {:error, "No Instagram access token provided and no configuration found"}
          
          config ->
            case Keyword.get(config, :access_token) do
              nil -> {:error, "No Instagram access token found in configuration"}
              token -> {:ok, token}
            end
        end
        
      token ->
        {:ok, token}
    end
  end
end
