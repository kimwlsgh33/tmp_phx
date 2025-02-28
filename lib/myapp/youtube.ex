defmodule Myapp.Youtube do
  @moduledoc """
  YouTube API integration using the YouTube Data API v3.
  Handles video searches, playlist management, and quota tracking.

  ## API Key Usage

  All functions accept an `:api_key` parameter in their options. The API key can be provided in two ways:

  1. Server Configuration:
     Configure a default API key in your application config:
     ```elixir
     config :myapp, Myapp.Youtube,
       api_key: System.get_env("YOUTUBE_API_KEY")
     ```

  2. Per-Request Key:
     Provide an API key directly in the function call:
     ```elixir
     Youtube.search_videos("query", api_key: "your_youtube_api_key")
     ```

  At least one of these methods must be used - either configure a server-side API key
  or provide one in the function call. If neither is provided, an error will be raised.

  The per-request API key takes precedence over the server configuration when both are present.
  This allows users to use their own API keys and quotas instead of the server's.
  """

  use GenServer
  require Logger

  @quota_limit 10_000

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{quota_used: 0}}
  end

  @doc """
  Search for YouTube videos with quota tracking.
  Returns videos matching the query with pagination support.

  ## Options
    * `:max_results` - Maximum number of results to return (default: 25)
    * `:page_token` - Token for getting the next page of results
    * `:api_key` - Optional YouTube API key to use instead of server's key
  """
  def search_videos(query, opts \\ []) do
    case validate_api_key(opts) do
      {:ok, api_key} ->
        url =
          "https://www.googleapis.com/youtube/v3/search?" <>
            URI.encode_query(%{
              "part" => "snippet",
              "q" => query,
              "type" => "video",
              "key" => api_key,
              "maxResults" => "9"
            })

        case HTTPoison.get(url, [], []) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            case Jason.decode(body) do
              {:ok, response} ->
                videos =
                  Enum.map(response["items"], fn item ->
                    %{
                      id: item["id"]["videoId"],
                      title: item["snippet"]["title"],
                      description: item["snippet"]["description"],
                      thumbnail: item["snippet"]["thumbnails"]["high"]["url"],
                      channel_title: item["snippet"]["channelTitle"],
                      published_at: item["snippet"]["publishedAt"]
                    }
                  end)

                {:ok, videos}

              _ ->
                {:error, "Failed to parse YouTube response"}
            end

          {:ok, %HTTPoison.Response{status_code: 400}} ->
            {:error, "Invalid request. Please check your search query."}

          {:ok, %HTTPoison.Response{status_code: 401}} ->
            {:error, "Invalid API key. Please check your API key and try again."}

          {:ok, %HTTPoison.Response{status_code: 403}} ->
            {:error, "API quota exceeded. Please try again later."}

          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("YouTube API error: #{inspect(reason)}")
            {:error, "Failed to connect to YouTube. Please check your internet connection."}

          _ ->
            {:error, "An unexpected error occurred. Please try again later."}
        end

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Get detailed information about a specific video.
  Includes statistics and content details.

  ## Options
    * `:api_key` - Optional YouTube API key to use instead of server's key
  """
  def get_video_details(video_id, opts \\ []) do
    case validate_api_key(opts) do
      {:ok, api_key} ->
        url =
          "https://www.googleapis.com/youtube/v3/videos?" <>
            URI.encode_query(%{
              "part" => "snippet,contentDetails,statistics",
              "id" => video_id,
              "key" => api_key
            })

        case HTTPoison.get(url, [], []) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            case Jason.decode(body) do
              {:ok, response} ->
                case response["items"] do
                  [item | _] ->
                    {:ok,
                     %{
                       id: video_id,
                       title: item["snippet"]["title"],
                       description: item["snippet"]["description"],
                       duration: item["contentDetails"]["duration"],
                       view_count: String.to_integer(item["statistics"]["viewCount"]),
                       published_at: item["snippet"]["publishedAt"],
                       tags: Map.get(item["snippet"], "tags", [])
                     }}

                  [] ->
                    {:error, "Video not found"}
                end

              _ ->
                {:error, "Failed to parse YouTube response"}
            end

          {:ok, %HTTPoison.Response{status_code: 400}} ->
            {:error, "Invalid request. Please check the video ID."}

          {:ok, %HTTPoison.Response{status_code: 401}} ->
            {:error, "Invalid API key. Please check your API key and try again."}

          {:ok, %HTTPoison.Response{status_code: 403}} ->
            {:error, "API quota exceeded. Please try again later."}

          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("YouTube API error: #{inspect(reason)}")
            {:error, "Failed to connect to YouTube. Please check your internet connection."}

          _ ->
            {:error, "An unexpected error occurred. Please try again later."}
        end

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Create a new playlist for the authenticated user.
  Requires OAuth2 authentication.

  ## Options
    * `:privacy_status` - Privacy status of the playlist (default: "private")
    * `:api_key` - Optional YouTube API key to use instead of server's key
  """
  def create_playlist(title, description, opts \\ []) do
    case validate_api_key(opts) do
      {:ok, api_key} ->
        case get_connection(api_key) do
          nil ->
            {:error,
             "No YouTube API key provided. Either configure server API key or provide a user API key."}

          connection ->
            GenServer.call(__MODULE__, {:track_quota, 50}, :infinity)
            |> case do
              :ok ->
                case GoogleApi.YouTube.V3.Api.Playlists.youtube_playlists_insert(
                       connection,
                       ["snippet,status"],
                       body: %GoogleApi.YouTube.V3.Model.Playlist{
                         snippet: %GoogleApi.YouTube.V3.Model.PlaylistSnippet{
                           title: title,
                           description: description
                         },
                         status: %GoogleApi.YouTube.V3.Model.PlaylistStatus{
                           privacyStatus: Keyword.get(opts, :privacy_status, "private")
                         }
                       }
                     ) do
                  {:ok, response} -> {:ok, response}
                  {:error, %{body: body}} -> {:error, body}
                  error -> {:error, "API request failed: #{inspect(error)}"}
                end

              {:error, :quota_exceeded} ->
                {:error, "Daily quota exceeded"}
            end
        end

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  List playlists for the authenticated user or a specific channel.

  ## Options
    * `:api_key` - Optional YouTube API key to use instead of server's key
  """
  def list_playlists(channel_id \\ "mine", opts \\ []) do
    case validate_api_key(opts) do
      {:ok, api_key} ->
        case get_connection(api_key) do
          nil ->
            {:error,
             "No YouTube API key provided. Either configure server API key or provide a user API key."}

          connection ->
            GenServer.call(__MODULE__, {:track_quota, 1}, :infinity)
            |> case do
              :ok ->
                case GoogleApi.YouTube.V3.Api.Playlists.youtube_playlists_list(
                       connection,
                       ["snippet,contentDetails"],
                       channelId: channel_id,
                       maxResults: 50
                     ) do
                  {:ok, response} ->
                    playlists =
                      Enum.map(response.items, fn item ->
                        %{
                          id: item.id,
                          title: item.snippet.title,
                          description: item.snippet.description,
                          thumbnail: item.snippet.thumbnails.default.url,
                          item_count: item.contentDetails.itemCount
                        }
                      end)

                    {:ok, playlists}

                  {:error, %{body: body}} ->
                    {:error, body}

                  error ->
                    {:error, "API request failed: #{inspect(error)}"}
                end

              {:error, :quota_exceeded} ->
                {:error, "Daily quota exceeded"}
            end
        end

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Add a video to a playlist.

  ## Options
    * `:api_key` - Optional YouTube API key to use instead of server's key
  """
  def add_to_playlist(playlist_id, video_id, opts \\ []) do
    case validate_api_key(opts) do
      {:ok, api_key} ->
        case get_connection(api_key) do
          nil ->
            {:error,
             "No YouTube API key provided. Either configure server API key or provide a user API key."}

          connection ->
            GenServer.call(__MODULE__, {:track_quota, 50}, :infinity)
            |> case do
              :ok ->
                playlist_item = %GoogleApi.YouTube.V3.Model.PlaylistItem{
                  snippet: %GoogleApi.YouTube.V3.Model.PlaylistItemSnippet{
                    playlistId: playlist_id,
                    resourceId: %GoogleApi.YouTube.V3.Model.ResourceId{
                      kind: "youtube#video",
                      videoId: video_id
                    }
                  }
                }

                case GoogleApi.YouTube.V3.Api.PlaylistItems.youtube_playlist_items_insert(
                       connection,
                       ["snippet"],
                       body: playlist_item
                     ) do
                  {:ok, response} -> {:ok, response}
                  {:error, %{body: body}} -> {:error, body}
                  error -> {:error, "API request failed: #{inspect(error)}"}
                end

              {:error, :quota_exceeded} ->
                {:error, "Daily quota exceeded"}
            end
        end

      {:error, message} ->
        {:error, message}
    end
  end

  # Server Callbacks

  @impl true
  def handle_call({:track_quota, cost}, _from, state) do
    today = Date.utc_today()

    state =
      if today != state.last_reset, do: %{state | quota_used: 0, last_reset: today}, else: state

    new_quota = state.quota_used + cost

    if new_quota > @quota_limit do
      {:reply, {:error, :quota_exceeded}, state}
    else
      {:reply, :ok, %{state | quota_used: new_quota}}
    end
  end

  @impl true
  def handle_call(:get_connection, _from, %{connection: connection} = state) do
    {:reply, connection, state}
  end

  # Private Functions

  defp get_connection(nil) do
    # When no user API key is provided, try server's key
    case GenServer.call(__MODULE__, :get_connection) do
      nil -> nil
      connection -> connection
    end
  end

  defp get_connection("") do
    # Return nil for empty string API key (initial page load)
    nil
  end

  defp get_connection(api_key) when is_binary(api_key) do
    # Create a new connection with user-provided API key
    GoogleApi.YouTube.V3.Connection.new(api_key)
  end

  defp get_connection(_) do
    # Return nil for any other invalid input
    nil
  end

  defp validate_api_key(opts) when is_list(opts) do
    case Keyword.get(opts, :api_key) do
      nil -> {:error, "Please enter your YouTube API key"}
      "" -> {:error, "Please enter your YouTube API key"}
      key -> validate_api_key_format(key)
    end
  end

  defp validate_api_key(_), do: {:error, "Invalid options provided"}

  defp validate_api_key_format(key) do
    # YouTube API keys are typically 39 characters long
    case String.length(key) do
      39 -> {:ok, key}
      _ -> {:error, "Invalid API key format. Please check your API key."}
    end
  end

  # Removed the unused parse_duration function
  # If needed in the future, you can add it back
end
