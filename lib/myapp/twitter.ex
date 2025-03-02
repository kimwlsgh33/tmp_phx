defmodule Myapp.Twitter do
  @moduledoc """
  Module for interacting with the Twitter/X API.
  Provides functions for posting tweets, retrieving timeline, and deleting tweets.
  """

  require Logger
  alias Myapp.TwitterOauth

  @base_url "https://api.twitter.com/2"

  @doc """
  Posts a new tweet with the given text content.
  
  ## Parameters
  
    * `conn` - The connection struct
    * `text` - The text content of the tweet
    
  ## Returns
  
    * `{:ok, response}` - If the tweet was successfully posted
    * `{:error, reason}` - If there was an error posting the tweet
  """
  def post_tweet(conn, text) when is_binary(text) do
    with {:ok, token} <- TwitterOauth.get_access_token(conn),
         {:ok, response} <- make_api_call(:post, "/tweets", token, %{text: text}) do
      {:ok, response}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Posts a new tweet with media attachments.
  
  ## Parameters
  
    * `conn` - The connection struct
    * `text` - The text content of the tweet
    * `media_ids` - List of media IDs to attach to the tweet
    
  ## Returns
  
    * `{:ok, response}` - If the tweet was successfully posted
    * `{:error, reason}` - If there was an error posting the tweet
  """
  def post_tweet_with_media(conn, text, media_ids) when is_binary(text) and is_list(media_ids) do
    payload = %{
      text: text,
      media: %{
        media_ids: media_ids
      }
    }

    with {:ok, token} <- TwitterOauth.get_access_token(conn),
         {:ok, response} <- make_api_call(:post, "/tweets", token, payload) do
      {:ok, response}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Uploads media to Twitter for later use in tweets.
  
  ## Parameters
  
    * `conn` - The connection struct
    * `media_binary` - Binary data of the media to upload
    * `mime_type` - MIME type of the media
    
  ## Returns
  
    * `{:ok, media_id}` - If the media was successfully uploaded
    * `{:error, reason}` - If there was an error uploading the media
  """
  def upload_media(conn, media_binary, mime_type) do
    with {:ok, token} <- TwitterOauth.get_access_token(conn),
         {:ok, response} <- do_upload_media(token, media_binary, mime_type) do
      {:ok, response["media_id_string"]}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_upload_media(token, media_binary, mime_type) do
    # Twitter has a separate upload API endpoint
    url = "https://upload.twitter.com/1.1/media/upload.json"
    
    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "multipart/form-data"}
    ]

    # This is simplified - actual implementation would use proper multipart handling
    body = %{
      media: media_binary,
      media_type: mime_type
    }

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: status, body: body}} when status in 200..299 ->
        {:ok, Jason.decode!(body)}
      
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        {:error, "HTTP Error #{status}: #{body}"}
      
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Network Error: #{reason}"}
    end
  end

  @doc """
  Retrieves the user's timeline (recent tweets).
  
  ## Parameters
  
    * `conn` - The connection struct
    * `opts` - Optional parameters such as count, max_id, etc.
    
  ## Returns
  
    * `{:ok, tweets}` - If the timeline was successfully retrieved
    * `{:error, reason}` - If there was an error retrieving the timeline
  """
  def get_user_timeline(conn, opts \\ %{}) do
    with {:ok, token} <- TwitterOauth.get_access_token(conn),
         {:ok, user_id} <- get_authenticated_user_id(token),
         {:ok, response} <- make_api_call(:get, "/users/#{user_id}/tweets", token, opts) do
      {:ok, response["data"] || []}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Gets the authenticated user's ID.
  
  ## Parameters
  
    * `token` - The access token
    
  ## Returns
  
    * `{:ok, user_id}` - If the user ID was successfully retrieved
    * `{:error, reason}` - If there was an error retrieving the user ID
  """
  def get_authenticated_user_id(token) do
    with {:ok, response} <- make_api_call(:get, "/users/me", token, %{}) do
      {:ok, response["data"]["id"]}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Deletes a tweet by its ID.
  
  ## Parameters
  
    * `conn` - The connection struct
    * `tweet_id` - The ID of the tweet to delete
    
  ## Returns
  
    * `{:ok, response}` - If the tweet was successfully deleted
    * `{:error, reason}` - If there was an error deleting the tweet
  """
  def delete_tweet(conn, tweet_id) when is_binary(tweet_id) do
    with {:ok, token} <- TwitterOauth.get_access_token(conn),
         {:ok, response} <- make_api_call(:delete, "/tweets/#{tweet_id}", token) do
      {:ok, response}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Validates if the current access token is still valid.
  
  ## Parameters
  
    * `conn` - The connection struct
    
  ## Returns
  
    * `{:ok, is_valid}` - If the validation was successful
    * `{:error, reason}` - If there was an error validating the token
  """
  def validate_token(conn) do
    with {:ok, token} <- TwitterOauth.get_access_token(conn),
         {:ok, _response} <- make_api_call(:get, "/users/me", token, %{}) do
      {:ok, true}
    else
      {:error, _reason} -> {:ok, false}
    end
  end

  @doc """
  Makes an API call to the Twitter/X API.
  
  ## Parameters
  
    * `method` - HTTP method (:get, :post, :delete, etc.)
    * `endpoint` - API endpoint (e.g., "/tweets")
    * `token` - Access token
    * `params` - Parameters to include in the request
    
  ## Returns
  
    * `{:ok, response}` - If the API call was successful
    * `{:error, reason}` - If there was an error with the API call
  """
  def make_api_call(method, endpoint, token, params \\ %{}) do
    url = @base_url <> endpoint
    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    request_body = if method in [:post, :put, :patch], do: Jason.encode!(params), else: ""
    
    query_params = if method == :get, do: URI.encode_query(params), else: ""
    full_url = if query_params != "", do: "#{url}?#{query_params}", else: url

    request_fun = case method do
      :get -> &HTTPoison.get/3
      :post -> &HTTPoison.post/3
      :put -> &HTTPoison.put/3
      :delete -> &HTTPoison.delete/3
      :patch -> &HTTPoison.patch/3
    end

    case request_fun.(full_url, request_body, headers) do
      {:ok, %HTTPoison.Response{status_code: status, body: body}} when status in 200..299 ->
        {:ok, Jason.decode!(body)}
      
      {:ok, %HTTPoison.Response{status_code: 401}} ->
        # Handle token refresh here if needed
        {:error, :unauthorized}
      
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        error_msg = case Jason.decode(body) do
          {:ok, decoded} -> Map.get(decoded, "errors", "Unknown error")
          _ -> "Error parsing response: #{body}"
        end
        Logger.error("Twitter API error: #{status} - #{error_msg}")
        {:error, error_msg}
      
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Twitter API network error: #{inspect(reason)}")
        {:error, "Network error: #{inspect(reason)}"}
    end
  end
end

