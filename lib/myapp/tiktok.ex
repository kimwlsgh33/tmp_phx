defmodule Myapp.Tiktok do
  @moduledoc """
  TikTok API integration for video uploads and management.
  
  This module provides functions for authenticating with TikTok,
  uploading videos, checking video status, and managing uploads.
  
  ## API Token Usage
  
  All functions accept an `:access_token` parameter in their options. The token can be provided in two ways:
  
  1. Server Configuration:
     Configure a default access token in your application config:
     ```elixir
     config :myapp, Myapp.Tiktok,
       access_token: System.get_env("TIKTOK_ACCESS_TOKEN"),
       client_key: System.get_env("TIKTOK_CLIENT_KEY"),
       client_secret: System.get_env("TIKTOK_CLIENT_SECRET")
     ```
  
  2. Per-Request Token:
     Provide an access token directly in the function call:
     ```elixir
     Tiktok.upload_video("path/to/video.mp4", access_token: "your_tiktok_token")
     ```
  
  At least one of these methods must be used. If neither is provided, an error will be raised.
  The per-request token takes precedence over the server configuration when both are present.
  """
  
  require Logger
  
  @base_url "https://open-api.tiktok.com/v2"
  
  @doc """
  Uploads a video to TikTok.
  
  ## Parameters
    * `video_path` - Path to the video file to upload
    * `opts` - Optional parameters:
        * `:access_token` - TikTok access token
        * `:title` - Video title/caption (default: "")
        * `:privacy_level` - Privacy level ("public", "friends", "private") (default: "private")
        * `:disable_comments` - Whether to disable comments (default: false)
        * `:disable_duet` - Whether to disable duets (default: false)
        * `:disable_stitch` - Whether to disable stitches (default: false)
  
  ## Returns
    * `{:ok, video_id}` - Successfully uploaded
    * `{:error, reason}` - Upload failed
  """
  def upload_video(video_path, opts \\ []) do
    case validate_access_token(opts) do
      {:ok, access_token} ->
        if File.exists?(video_path) do
          # First initialize the upload with TikTok to get an upload_id
          case init_upload(access_token) do
            {:ok, %{"data" => %{"upload_id" => upload_id}}} ->
              # Prepare video file for upload
              video_data = File.read!(video_path)
              
              # Upload the video data
              case upload_video_chunks(upload_id, video_data, access_token) do
                :ok ->
                  # Once upload is complete, finalize the video post
                  finalize_upload(
                    upload_id, 
                    Keyword.get(opts, :title, ""),
                    Keyword.get(opts, :privacy_level, "private"),
                    Keyword.get(opts, :disable_comments, false),
                    Keyword.get(opts, :disable_duet, false),
                    Keyword.get(opts, :disable_stitch, false),
                    access_token
                  )
                  
                error -> error
              end
              
            error -> error
          end
        else
          {:error, "Video file not found: #{video_path}"}
        end
        
      {:error, message} ->
        {:error, message}
    end
  end
  
  @doc """
  Initializes a video upload to get an upload_id.
  
  ## Parameters
    * `access_token` - TikTok access token
  
  ## Returns
    * `{:ok, response}` - Successfully initialized upload
    * `{:error, reason}` - Initialization failed
  """
  def init_upload(access_token) do
    url = "#{@base_url}/video/upload/"
    
    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"}
    ]
    
    case HTTPoison.post(url, "{}", headers) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} when status_code in 200..299 ->
        case Jason.decode(body) do
          {:ok, response} -> {:ok, response}
          {:error, _} -> {:error, "Failed to parse TikTok response"}
        end
        
      {:ok, %HTTPoison.Response{status_code: 401}} ->
        {:error, "Invalid access token. Please check your credentials."}
        
      {:ok, %HTTPoison.Response{status_code: 403}} ->
        {:error, "Permission denied. Your app may not have video upload permission."}
        
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("TikTok API error: Status #{status_code}, Body: #{body}")
        {:error, "TikTok API error: #{status_code}"}
        
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("TikTok API connection error: #{inspect(reason)}")
        {:error, "Failed to connect to TikTok API. Please check your internet connection."}
    end
  end
  
  @doc """
  Uploads video data in chunks.
  
  This is an internal function that handles chunking of large video files.
  
  ## Parameters
    * `upload_id` - Upload ID from init_upload
    * `video_data` - Binary data of the video file
    * `access_token` - TikTok access token
  
  ## Returns
    * `:ok` - Successfully uploaded all chunks
    * `{:error, reason}` - Upload failed
  """
  def upload_video_chunks(upload_id, video_data, access_token) do
    # TikTok recommends 5MB chunks, so we'll use that size
    chunk_size = 5 * 1024 * 1024
    total_size = byte_size(video_data)
    
    # Split the video into chunks and upload each
    Enum.reduce_while(0..(div(total_size - 1, chunk_size)), {:ok, 0}, fn chunk_index, {:ok, offset} ->
      chunk_start = chunk_index * chunk_size
      chunk_end = min(chunk_start + chunk_size, total_size)
      chunk = binary_part(video_data, chunk_start, chunk_end - chunk_start)
      
      case upload_chunk(upload_id, chunk, chunk_index, chunk_start, chunk_end, total_size, access_token) do
        :ok -> {:cont, {:ok, chunk_end}}
        error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, _} -> :ok
      error -> error
    end
  end
  
  @doc """
  Uploads a single chunk of a video file.
  
  ## Parameters
    * Various chunk parameters and the access token
  
  ## Returns
    * `:ok` - Chunk uploaded successfully
    * `{:error, reason}` - Chunk upload failed
  """
  def upload_chunk(upload_id, chunk_data, chunk_index, chunk_start, chunk_end, total_size, access_token) do
    url = "#{@base_url}/video/upload/#{upload_id}/"
    
    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/octet-stream"},
      {"Content-Range", "bytes #{chunk_start}-#{chunk_end-1}/#{total_size}"}
    ]
    
    case HTTPoison.post(url, chunk_data, headers) do
      {:ok, %HTTPoison.Response{status_code: status_code}} when status_code in 200..299 ->
        :ok
        
      {:ok, %HTTPoison.Response{status_code: 401}} ->
        {:error, "Invalid access token. Please check your credentials."}
        
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("TikTok chunk upload error: Status #{status_code}, Body: #{body}")
        {:error, "Chunk upload failed: #{status_code}"}
        
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("TikTok API connection error: #{inspect(reason)}")
        {:error, "Failed to connect to TikTok API. Please check your internet connection."}
    end
  end
  
  @doc """
  Finalizes a video upload, making it visible on TikTok.
  
  ## Parameters
    * `upload_id` - Upload ID from init_upload
    * `title` - Video caption/title
    * `privacy_level` - Privacy level ("public", "friends", "private")
    * `disable_comments` - Whether to disable comments
    * `disable_duet` - Whether to disable duets
    * `disable_stitch` - Whether to disable stitches
    * `access_token` - TikTok access token
  
  ## Returns
    * `{:ok, %{"data" => %{"video_id" => video_id}}}` - Successfully finalized
    * `{:error, reason}` - Finalization failed
  """
  def finalize_upload(upload_id, title, privacy_level, disable_comments, disable_duet, disable_stitch, access_token) do
    url = "#{@base_url}/video/publish/"
    
    payload = %{
      upload_id: upload_id,
      title: title,
      privacy_level: privacy_level,
      disable_comments: disable_comments,
      disable_duet: disable_duet,
      disable_stitch: disable_stitch
    }
    
    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"}
    ]
    
    body = Jason.encode!(payload)
    
    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} when status_code in 200..299 ->
        case Jason.decode(response_body) do
          {:ok, response} -> {:ok, response}
          {:error, _} -> {:error, "Failed to parse TikTok response"}
        end
        
      {:ok, %HTTPoison.Response{status_code: 401}} ->
        {:error, "Invalid access token. Please check your credentials."}
        
      {:ok, %HTTPoison.Response{status_code: 403}} ->
        {:error, "Permission denied. Your app may not have video publish permission."}
        
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("TikTok video publish error: Status #{status_code}, Body: #{body}")
        {:error, "TikTok API error: #{status_code}"}
        
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("TikTok API connection error: #{inspect(reason)}")
        {:error, "Failed to connect to TikTok API. Please check your internet connection."}
    end
  end
  
  @doc """
  Gets information about a specific video.
  
  ## Parameters
    * `video_id` - ID of the video to get information about
    * `opts` - Optional parameters:
        * `:access_token` - TikTok access token
  
  ## Returns
    * `{:ok, video_info}` - Successfully retrieved video info
    * `{:error, reason}` - Retrieval failed
  """
  def get_video(video_id, opts \\ []) do
    case validate_access_token(opts) do
      {:ok, access_token} ->
        url = "#{@base_url}/video/info/?video_id=#{video_id}"
        
        headers = [
          {"Authorization", "Bearer #{access_token}"},
          {"Content-Type", "application/json"}
        ]
        
        case HTTPoison.get(url, headers) do
          {:ok, %HTTPoison.Response{status_code: status_code, body: body}} when status_code in 200..299 ->
            case Jason.decode(body) do
              {:ok, response} -> {:ok, response}
              {:error, _} -> {:error, "Failed to parse TikTok response"}
            end
            
          {:ok, %HTTPoison.Response{status_code: 401}} ->
            {:error, "Invalid access token. Please check your credentials."}
            
          {:ok, %HTTPoison.Response{status_code: 404}} ->
            {:error, "Video not found"}
            
          {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
            Logger.error("TikTok API error: Status #{status_code}, Body: #{response_body}")
            {:error, "TikTok API error: #{status_code}"}
            
          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("TikTok API connection error: #{inspect(reason)}")
            {:error, "Failed to connect to TikTok API. Please check your internet connection."}
        end
        
      {:error, message} ->
        {:error, message}
    end
  end
  
  @doc """
  Lists videos for the authenticated user.
  
  ## Parameters
    * `opts` - Optional parameters:
        * `:access_token` - TikTok access token
        * `:cursor` - Pagination cursor
        * `:max_count` - Maximum number of videos to return (default: 20)
  
  ## Returns
    * `{:ok, %{"data" => %{"videos" => [...], "cursor" => cursor}}}` - Successfully retrieved videos
    * `{:error, reason}` - Retrieval failed
  """
  def list_videos(opts \\ []) do
    case validate_access_token(opts) do
      {:ok, access_token} ->
        cursor = Keyword.get(opts, :cursor, "0")
        max_count = Keyword.get(opts, :max_count, 20)
        
        url = "#{@base_url}/video/list/?cursor=#{cursor}&max_count=#{max_count}"
        
        headers = [
          {"Authorization", "Bearer #{access_token}"},
          {"Content-Type", "application/json"}
        ]
        
        case HTTPoison.get(url, headers) do
          {:ok, %HTTPoison.Response{status_code: status_code, body: body}} when status_code in 200..299 ->
            case Jason.decode(body) do
              {:ok, response} -> {:ok, response}
              {:error, _} -> {:error, "Failed to parse TikTok response"}
            end
            
          {:ok, %HTTPoison.Response{status_code: 401}} ->
            {:error, "Invalid access token. Please check your credentials."}
            
          {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
            Logger.error("TikTok API error: Status #{status_code}, Body: #{response_body}")
            {:error, "TikTok API error: #{status_code}"}
            
          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("TikTok API connection error: #{inspect(reason)}")
            {:error, "Failed to connect to TikTok API. Please check your internet connection."}
        end
        
      {:error, message} ->
        {:error, message}
    end
  end
  
  @doc """
  Validates the access token from options or application config.
  
  Checks for a token in the following order:
  1. The `:access_token` option passed to the function
  2. The application configuration
  
  ## Parameters
    * `opts` - Options keyword list which may contain `:access_token`
  
  ## Returns
    * `{:ok, access_token}` - Valid access token found
    * `{:error, reason}` - No valid token found
  """
  def validate_access_token(opts) do
    # First check if token was provided in function options
    case Keyword.get(opts, :access_token) do
      nil ->
        # If not in options, check application config
        case Application.get_env(:myapp, __MODULE__) do
          nil ->
            {:error, "TikTok access token not configured. Please provide an access token."}
            
          config ->
            case Keyword.get(config, :access_token) do
              nil -> 
                {:error, "TikTok access token not configured. Please provide an access token."}
              
              "" -> 
                {:error, "TikTok access token is empty. Please provide a valid access token."}
              
              access_token -> 
                {:ok, access_token}
            end
        end
        
      "" ->
        {:error, "TikTok access token is empty. Please provide a valid access token."}
        
      access_token ->
        {:ok, access_token}
    end
  end
  
  @doc """
  Deletes a video from TikTok.
  
  ## Parameters
    * `video_id` - ID of the video to delete
    * `opts` - Optional parameters:
        * `:access_token` - TikTok access token
  
  ## Returns
    * `{:ok, response}` - Successfully deleted
    * `{:error, reason}` - Deletion failed
  """
  def delete_video(video_id, opts \\ []) do
    case validate_access_token(opts) do
      {:ok, access_token} ->
        url = "#{@base_url}/video/delete/"
        
        payload = %{
          video_id: video_id
        }
        
        headers = [
          {"Authorization", "Bearer #{access_token}"},
          {"Content-Type", "application/json"}
        ]
        
        body = Jason.encode!(payload)
        
        case HTTPoison.post(url, body, headers) do
          {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} when status_code in 200..299 ->
            case Jason.decode(response_body) do
              {:ok, response} -> {:ok, response}
              {:error, _} -> {:error, "Failed to parse TikTok response"}
            end
            
          {:ok, %HTTPoison.Response{status_code: 401}} ->
            {:error, "Invalid access token. Please check your credentials."}
            
          {:ok, %HTTPoison.Response{status_code: 404}} ->
            {:error, "Video not found"}
            
          {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
            Logger.error("TikTok video deletion error: Status #{status_code}, Body: #{body}")
            {:error, "TikTok API error: #{status_code}"}
            
          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("TikTok API connection error: #{inspect(reason)}")
            {:error, "Failed to connect to TikTok API. Please check your internet connection."}
        end
        
      {:error, message} ->
        {:error, message}
    end
  end
  
  @doc """
  Checks if TikTok API credentials are configured and valid.
  
  ## Parameters
    * `opts` - Optional parameters:
        * `:access_token` - TikTok access token to validate
  
  ## Returns
    * `{:ok, "TikTok API credentials are valid"}` - Credentials are valid
    * `{:error, reason}` - Credentials are invalid or missing
  """
  def check_credentials(opts \\ []) do
    case validate_access_token(opts) do
      {:ok, access_token} ->
        # Make a simple API call to verify the token is working
        url = "#{@base_url}/user/info/"
        
        headers = [
          {"Authorization", "Bearer #{access_token}"},
          {"Content-Type", "application/json"}
        ]
        
        case HTTPoison.get(url, headers) do
          {:ok, %HTTPoison.Response{status_code: status_code}} when status_code in 200..299 ->
            {:ok, "TikTok API credentials are valid"}
            
          {:ok, %HTTPoison.Response{status_code: 401}} ->
            {:error, "Invalid access token. Please check your credentials."}
            
          {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
            Logger.error("TikTok API credential check error: Status #{status_code}, Body: #{body}")
            {:error, "TikTok API error: #{status_code}"}
            
          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("TikTok API connection error: #{inspect(reason)}")
            {:error, "Failed to connect to TikTok API. Please check your internet connection."}
        end
        
      {:error, message} ->
        {:error, message}
    end
  end
end
