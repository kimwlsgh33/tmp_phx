defmodule Myapp.SocialMediaToken do
  @moduledoc """
  Module for handling social media access tokens.
  
  This module provides functions to store, retrieve, validate and refresh OAuth tokens
  for various social media platforms. It uses the Myapp.Accounts.SocialMediaToken schema
  for database persistence.
  """
  
  alias Myapp.Repo
  alias Myapp.Accounts.SocialMediaToken
  alias Myapp.Accounts.User
  alias Ecto.Changeset
  import Ecto.Query
  require Logger

  @type platform :: :twitter | :instagram | :youtube | :tiktok
  @type token_type :: :access | :refresh
  @type token_info :: %{
    access_token: String.t(),
    refresh_token: String.t() | nil,
    expires_at: DateTime.t() | nil,
    platform: platform()
  }

  @doc """
  Stores social media tokens for a specific user and platform.
  
  ## Parameters
    - user_id: The ID of the user to store the token for
    - platform: The social media platform (:twitter, :instagram, :youtube, :tiktok)
    - token_info: A map containing token information
      - access_token: The access token string
      - refresh_token: The refresh token string (optional)
      - expires_at: The expiration datetime (optional)
      - metadata: Optional metadata about the token (default: %{})
  
  ## Returns
    - {:ok, token_info} on success
    - {:error, reason} on failure
  """
  @spec store_token(integer(), platform(), map()) :: {:ok, token_info()} | {:error, term()}
  def store_token(user_id, platform, %{access_token: _} = token_info) when is_integer(user_id) do
    user = Repo.get(User, user_id)

    if is_nil(user) do
      {:error, :user_not_found}
    else
      platform_str = Atom.to_string(platform)
      
      # Prepare token data for the changeset
      token_attrs = %{
        user_id: user_id,
        platform: platform_str,
        access_token_text: token_info.access_token,
        refresh_token_text: Map.get(token_info, :refresh_token),
        expires_at: Map.get(token_info, :expires_at),
        metadata: Map.get(token_info, :metadata, %{}),
        last_used_at: DateTime.utc_now()
      }

      # Check if a token for this user and platform already exists
      query = SocialMediaToken.get_by_user_and_platform(user_id, platform_str)
      existing_token = Repo.one(query)

      result =
        if existing_token do
          # Update the existing token
          existing_token
          |> SocialMediaToken.update_changeset(token_attrs)
          |> Repo.update()
        else
          # Create a new token
          %SocialMediaToken{}
          |> SocialMediaToken.changeset(token_attrs)
          |> Repo.insert()
        end

      case result do
        {:ok, token} ->
          # Return the token in the expected format
          {:ok, %{
            access_token: token_info.access_token,
            refresh_token: Map.get(token_info, :refresh_token),
            expires_at: Map.get(token_info, :expires_at),
            platform: platform
          }}
        {:error, changeset} ->
          Logger.error("Failed to store social media token: #{inspect(changeset.errors)}")
          {:error, changeset}
      end
    end
  end

  @doc """
  Retrieves a token for a user and platform.
  
  ## Parameters
    - user_id: The ID of the user
    - platform: The social media platform
    - token_type: The type of token to retrieve (:access or :refresh)
  
  ## Returns
    - {:ok, token} on success
    - {:error, reason} on failure
  """
  @spec get_token(integer(), platform(), token_type()) :: {:ok, String.t()} | {:error, term()}
  def get_token(user_id, platform, token_type \\ :access) when is_integer(user_id) do
    platform_str = Atom.to_string(platform)
    
    # Retrieve token from database
    query = SocialMediaToken.get_by_user_and_platform(user_id, platform_str)
    token = Repo.one(query)
    
    if is_nil(token) do
      {:error, :token_not_found}
    else
      # Update last_used_at timestamp
      token
      |> SocialMediaToken.mark_as_used()
      |> Repo.update()
      
      case token_type do
        :access -> 
          case SocialMediaToken.decrypt_access_token(token) do
            {:ok, access_token} -> {:ok, access_token}
            error -> error
          end
        :refresh ->
          case SocialMediaToken.decrypt_refresh_token(token) do
            {:ok, refresh_token} -> {:ok, refresh_token}
            {:error, :no_token} -> {:error, :refresh_token_not_available}
            error -> error
          end
      end
    end
  end

  @doc """
  Checks if a token is valid (not expired).
  
  ## Parameters
    - user_id: The ID of the user
    - platform: The social media platform (:twitter, :instagram, :youtube, :tiktok)
  
  ## Returns
    - {:ok, is_valid} on success
    - {:error, reason} on failure
  """
  @spec valid_token?(integer(), platform()) :: {:ok, boolean()} | {:error, term()}
  def valid_token?(user_id, platform) when is_integer(user_id) do
    platform_str = Atom.to_string(platform)
    
    # Retrieve token from database
    query = SocialMediaToken.get_by_user_and_platform(user_id, platform_str)
    token = Repo.one(query)
    
    if is_nil(token) do
      {:error, :token_not_found}
    else
      # Check if token is valid using the schemas valid? function
      is_valid = SocialMediaToken.valid?(token)
      {:ok, is_valid}
    end
  end

  @doc """
  Refreshes an access token using the refresh token.
  
  ## Parameters
    - user_id: The ID of the user
    - platform: The social media platform (:twitter, :instagram, :youtube, :tiktok)
  
  ## Returns
    - {:ok, new_token_info} on success
    - {:error, reason} on failure
  """
  @spec refresh_token(integer(), platform()) :: {:ok, token_info()} | {:error, term()}
  def refresh_token(user_id, platform) when is_integer(user_id) do
    platform_str = Atom.to_string(platform)
    
    # Retrieve token from database
    query = SocialMediaToken.get_by_user_and_platform(user_id, platform_str)
    token = Repo.one(query)
    
    if is_nil(token) do
      {:error, :token_not_found}
    else
      # Decrypt refresh token
      with {:ok, refresh_token} <- SocialMediaToken.decrypt_refresh_token(token),
          {:ok, new_token_info} <- do_refresh_token(platform, refresh_token) do
        # Store the new token
        store_token(user_id, platform, new_token_info)
      else
        {:error, :no_token} -> {:error, :refresh_token_not_available}
        error -> error
      end
    end
  end

  @doc """
  Deletes tokens for a specific user and platform.
  
  ## Parameters
    - user_id: The ID of the user
    - platform: The social media platform (:twitter, :instagram, :youtube, :tiktok)
  
  ## Returns
    - :ok on success
    - {:error, reason} on failure
  """
  @spec delete_token(integer(), platform()) :: :ok | {:error, term()}
  def delete_token(user_id, platform) when is_integer(user_id) do
    platform_str = Atom.to_string(platform)
    
    # Delete token from database
    query = SocialMediaToken.get_by_user_and_platform(user_id, platform_str)
    case Repo.delete_all(query) do
      {count, _} when count > 0 -> :ok
      {0, _} -> {:error, :token_not_found}
    end
  end

  @doc """
  Gets all tokens for a user.
  
  ## Parameters
    - user_id: The ID of the user
  
  ## Returns
    - List of SocialMediaToken structs
  """
  @spec list_user_tokens(integer()) :: [SocialMediaToken.t()]
  def list_user_tokens(user_id) do
    query = from t in SocialMediaToken, where: t.user_id == ^user_id
    Repo.all(query)
  end

  # Private functions

  defp do_refresh_token(platform, refresh_token) do
    # This function calls the appropriate OAuth endpoint to refresh the token
    # The implementation varies based on the platform
    
    case platform do
      :twitter -> refresh_twitter_token(refresh_token)
      :instagram -> refresh_instagram_token(refresh_token)
      :youtube -> refresh_youtube_token(refresh_token)
      :tiktok -> refresh_tiktok_token(refresh_token)
      _ -> {:error, :unsupported_platform}
    end
  end

  defp refresh_twitter_token(refresh_token) do
    # Implementation for refreshing Twitter tokens
    # This makes an HTTP request to Twitter's OAuth endpoint
    
    case Myapp.TwitterOauth.refresh_token(refresh_token) do
      {:ok, token_data} ->
        # Format the response to match our expected token_info structure
        {:ok, %{
          access_token: token_data["access_token"],
          refresh_token: token_data["refresh_token"],
          expires_at: calculate_expiry(token_data["expires_in"])
        }}
      
      {:error, reason} ->
        Logger.error("Failed to refresh Twitter token: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp refresh_instagram_token(refresh_token) do
    # Implementation for refreshing Instagram tokens
    # This makes an HTTP request to Instagram OAuth endpoint
    
    case Myapp.InstagramOauth.refresh_long_lived_token(refresh_token) do
      {:ok, token_data} ->
        # Format the response to match our expected token_info structure
        {:ok, %{
          access_token: token_data["access_token"],
          refresh_token: nil, # Instagram doesn't return a new refresh token
          expires_at: calculate_expiry(token_data["expires_in"])
        }}
      
      {:error, reason} ->
        Logger.error("Failed to refresh Instagram token: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp refresh_youtube_token(refresh_token) do
    # Implementation for refreshing YouTube tokens
    # This makes an HTTP request to Google's OAuth endpoint
    
    # Setup the parameters for token refresh
    url = "https://accounts.google.com/o/oauth2/token"
    form_data = [
      client_id: System.get_env("YOUTUBE_CLIENT_ID"),
      client_secret: System.get_env("YOUTUBE_CLIENT_SECRET"),
      grant_type: "refresh_token",
      refresh_token: refresh_token
    ]
    
    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]
    
    case HTTPoison.post(url, URI.encode_query(form_data), headers) do
      {:ok, %{status_code: 200, body: body}} ->
        token_data = Jason.decode!(body)
        # Format the response to match our expected token_info structure
        {:ok, %{
          access_token: token_data["access_token"],
          refresh_token: token_data["refresh_token"] || refresh_token, # Use old refresh token if not returned
          expires_at: calculate_expiry(token_data["expires_in"])
        }}
      
      {:ok, %{status_code: status_code, body: body}} ->
        Logger.error("YouTube OAuth token refresh failed: HTTP #{status_code}, #{body}")
        {:error, "Failed to refresh YouTube token: HTTP #{status_code}"}
      
      {:error, %{reason: reason}} ->
        Logger.error("YouTube OAuth token refresh error: #{inspect(reason)}")
        {:error, "Error communicating with YouTube API: #{inspect(reason)}"}
    end
  end

  defp refresh_tiktok_token(refresh_token) do
    # Implementation for refreshing TikTok tokens
    # This makes an HTTP request to TikTok's OAuth endpoint
    
    url = "https://open-api.tiktok.com/oauth/refresh_token/"
    form_data = [
      client_key: System.get_env("TIKTOK_CLIENT_ID"),
      client_secret: System.get_env("TIKTOK_CLIENT_SECRET"),
      grant_type: "refresh_token",
      refresh_token: refresh_token
    ]
    
    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]
    
    case HTTPoison.post(url, URI.encode_query(form_data), headers) do
      {:ok, %{status_code: 200, body: body}} ->
        token_data = Jason.decode!(body)
        
        # Check if the API call was successful according to TikTok's response format
        case token_data do
          %{"data" => data, "message" => "success"} ->
            # Format the response to match our expected token_info structure
            {:ok, %{
              access_token: data["access_token"],
              refresh_token: data["refresh_token"] || refresh_token, # Use old refresh token if not returned
              expires_at: calculate_expiry(data["expires_in"])
            }}
            
          _ ->
            Logger.error("TikTok OAuth token refresh failed: #{inspect(token_data)}")
            {:error, "Failed to refresh TikTok token: #{token_data["message"] || "Unknown error"}"}
        end
      
      {:ok, %{status_code: status_code, body: body}} ->
        Logger.error("TikTok OAuth token refresh failed: HTTP #{status_code}, #{body}")
        {:error, "Failed to refresh TikTok token: HTTP #{status_code}"}
      
      {:error, %{reason: reason}} ->
        Logger.error("TikTok OAuth token refresh error: #{inspect(reason)}")
        {:error, "Error communicating with TikTok API: #{inspect(reason)}"}
    end
  end
  
  # Helper function to calculate token expiration date
  @doc """
  Calculates the expiration datetime based on an expires_in value in seconds.
  
  ## Parameters
    - expires_in: Time in seconds until the token expires
    
  ## Returns
    - DateTime representing when the token will expire or nil if expires_in is invalid
  """
  def calculate_expiry(expires_in) when is_binary(expires_in) do
    case Integer.parse(expires_in) do
      {seconds, _} -> calculate_expiry(seconds)
      :error -> nil
    end
  end
  
  def calculate_expiry(expires_in) when is_integer(expires_in) do
    DateTime.add(DateTime.utc_now(), expires_in, :second)
  end
  
  def calculate_expiry(_), do: nil

  @doc """
  Finds tokens that are about to expire within the specified time window.
  
  ## Parameters
    - window_in_seconds: Time window in seconds before token expiration (default: 1 hour)
    
  ## Returns
    - List of SocialMediaToken structs that will expire soon
  """
  @spec find_expiring_tokens(integer()) :: [SocialMediaToken.t()]
  def find_expiring_tokens(window_in_seconds \\ 3600) do
    now = DateTime.utc_now()
    cutoff_time = DateTime.add(now, window_in_seconds, :second)
    
    query = from t in SocialMediaToken,
            where: t.expires_at <= ^cutoff_time and t.expires_at > ^now,
            preload: [:user]
            
    Repo.all(query)
  end
  
  @doc """
  Refreshes tokens that are about to expire.
  
  ## Parameters
    - window_in_seconds: Time window in seconds before token expiration (default: 1 hour)
    
  ## Returns
    - {:ok, results} where results is a map with success and failure counts
  """
  @spec refresh_expiring_tokens(integer()) :: {:ok, %{success: integer(), failures: integer()}}
  def refresh_expiring_tokens(window_in_seconds \\ 3600) do
    tokens = find_expiring_tokens(window_in_seconds)
    
    # Process each token and track results
    results = Enum.reduce(tokens, %{success: 0, failures: 0}, fn token, acc ->
      platform = String.to_existing_atom(token.platform)
      
      case refresh_token(token.user_id, platform) do
        {:ok, _} ->
          Logger.info("Successfully refreshed #{platform} token for user #{token.user_id}")
          Map.update!(acc, :success, &(&1 + 1))
          
        {:error, reason} ->
          Logger.error("Failed to refresh #{platform} token for user #{token.user_id}: #{inspect(reason)}")
          Map.update!(acc, :failures, &(&1 + 1))
      end
    end)
    
    {:ok, results}
  end
  
  @doc """
  Starts a token monitoring process that periodically checks for tokens
  that are about to expire and refreshes them.
  
  ## Parameters
    - check_interval_ms: Interval between checks in milliseconds (default: 1 hour)
    - window_in_seconds: Time window in seconds before token expiration (default: 2 hours)
    
  ## Returns
    - :ok on success
  """
  @spec start_token_monitor(integer(), integer()) :: :ok
  def start_token_monitor(check_interval_ms \\ 3_600_000, window_in_seconds \\ 7_200) do
    # Schedule the first check
    Process.send_after(self(), {:check_expiring_tokens, window_in_seconds}, check_interval_ms)
    :ok
  end
  
  @doc """
  Handles the periodic token expiration check and schedules the next check.
  
  This function is meant to be called by the process that started the token monitor.
  """
  def handle_token_monitor(window_in_seconds, check_interval_ms) do
    # Refresh expiring tokens
    {:ok, results} = refresh_expiring_tokens(window_in_seconds)
    
    # Log the results
    Logger.info("Token refresh result: #{results.success} succeeded, #{results.failures} failed")
    
    # Schedule the next check
    Process.send_after(self(), {:check_expiring_tokens, window_in_seconds}, check_interval_ms)
    :ok
  end
  
  @doc """
  Sends notifications to users with tokens that are about to expire but cannot be automatically refreshed.
  
  ## Parameters
    - window_in_seconds: Time window in seconds before token expiration
    
  ## Returns
    - {:ok, notification_count} on success
  """
  @spec notify_users_of_expiring_tokens(integer()) :: {:ok, integer()}
  def notify_users_of_expiring_tokens(window_in_seconds \\ 86_400) do
    tokens = find_expiring_tokens(window_in_seconds)
    
    # Filter tokens that cannot be refreshed automatically (no refresh token)
    non_refreshable_tokens = Enum.filter(tokens, fn token ->
      # Check if the token has a refresh token
      case SocialMediaToken.decrypt_refresh_token(token) do
        {:ok, _} -> false  # Has refresh token, can be automatically refreshed
        _ -> true  # No refresh token, needs user intervention
      end
    end)
    
    # Send notifications (placeholder for actual notification logic)
    Enum.each(non_refreshable_tokens, fn token ->
      Logger.info("Would notify user #{token.user_id} about expiring #{token.platform} token")
      # Here you would implement the actual notification logic
      # e.g., Myapp.Notifications.send_token_expiration_notice(token.user, token.platform)
    end)
    
    {:ok, length(non_refreshable_tokens)}
  end
end
