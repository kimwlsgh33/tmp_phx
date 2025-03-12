defmodule Myapp.SocialAuth.TikTok do
  @moduledoc """
  TikTok implementation of the SocialAuth behaviour.
  Handles OAuth 2.0 authentication flow for TikTok.
  """

  @behaviour Myapp.SocialAuth

  require Logger

  @impl Myapp.SocialAuth
  def generate_auth_url(params \\ %{}) do
    scope = Map.get(params, :scope, "user.info.basic,video.upload,video.list")
    state = Map.get(params, :state, generate_state_param())
    
    try do
      query_params = URI.encode_query(%{
        "client_key" => api_key(),
        "response_type" => "code",
        "redirect_uri" => redirect_uri(),
        "scope" => scope,
        "state" => state
      })

      {:ok, "https://www.tiktok.com/auth/authorize?#{query_params}"}
    rescue
      e ->
        Logger.error("Failed to generate TikTok auth URL: #{inspect(e)}")
        {:error, "Failed to generate authorization URL"}
    end
  end

  @impl Myapp.SocialAuth
  def exchange_code_for_token(code, _params \\ %{}) do
    url = "https://open-api.tiktok.com/oauth/access_token/"
    
    form_data = [
      client_key: api_key(),
      client_secret: api_secret(),
      code: code,
      grant_type: "authorization_code",
      redirect_uri: redirect_uri()
    ]

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    case HTTPoison.post(url, URI.encode_query(form_data), headers) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"data" => token_data, "message" => "success"}} ->
            {:ok, %{
              "access_token" => token_data["access_token"],
              "expires_in" => token_data["expires_in"],
              "refresh_token" => token_data["refresh_token"],
              "refresh_expires_in" => token_data["refresh_expires_in"],
              "open_id" => token_data["open_id"],
              "scope" => token_data["scope"]
            }}
          
          {:ok, %{"data" => %{"description" => error_msg}}} ->
            Logger.error("TikTok OAuth token exchange failed: #{error_msg}")
            {:error, "Failed to exchange code for token: #{error_msg}"}
          
          {:error, _} ->
            Logger.error("Failed to parse TikTok token response")
            {:error, "Failed to parse token response"}
        end
      
      {:ok, %{status_code: status_code, body: body}} ->
        Logger.error("TikTok OAuth token exchange failed: HTTP #{status_code}, #{body}")
        {:error, "Failed to exchange code for token: HTTP #{status_code}"}
      
      {:error, %{reason: reason}} ->
        Logger.error("TikTok OAuth token exchange error: #{inspect(reason)}")
        {:error, "Error communicating with TikTok API: #{inspect(reason)}"}
    end
  end

  @impl Myapp.SocialAuth
  def refresh_token(refresh_token, _params \\ %{}) do
    url = "https://open-api.tiktok.com/oauth/refresh_token/"
    
    form_data = [
      client_key: api_key(),
      client_secret: api_secret(),
      grant_type: "refresh_token",
      refresh_token: refresh_token
    ]

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    case HTTPoison.post(url, URI.encode_query(form_data), headers) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"data" => token_data, "message" => "success"}} ->
            {:ok, %{
              "access_token" => token_data["access_token"],
              "expires_in" => token_data["expires_in"],
              "refresh_token" => token_data["refresh_token"],
              "refresh_expires_in" => token_data["refresh_expires_in"]
            }}
          
          {:ok, %{"data" => %{"description" => error_msg}}} ->
            Logger.error("TikTok OAuth token refresh failed: #{error_msg}")
            {:error, "Failed to refresh token: #{error_msg}"}
          
          {:error, _} ->
            Logger.error("Failed to parse TikTok token refresh response")
            {:error, "Failed to parse token refresh response"}
        end
      
      {:ok, %{status_code: status_code, body: body}} ->
        Logger.error("TikTok OAuth token refresh failed: HTTP #{status_code}, #{body}")
        {:error, "Failed to refresh token: HTTP #{status_code}"}
      
      {:error, %{reason: reason}} ->
        Logger.error("TikTok OAuth token refresh error: #{inspect(reason)}")
        {:error, "Error communicating with TikTok API: #{inspect(reason)}"}
    end
  end

  @impl Myapp.SocialAuth
  def validate_token(access_token, params \\ %{}) do
    open_id = Map.get(params, :open_id)
    
    # TikTok doesn't have a dedicated token validation endpoint
    # We'll use the user info endpoint to verify if the token is valid
    url = "https://open-api.tiktok.com/user/info/"
    
    query_params = %{
      "access_token" => access_token
    }
    |> maybe_add_open_id(open_id)
    |> URI.encode_query()
    
    url_with_params = "#{url}?#{query_params}"
    
    case HTTPoison.get(url_with_params) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"message" => "success"}} ->
            {:ok, true}
          
          {:ok, %{"data" => %{"description" => _error_msg}}} ->
            {:ok, false}
          
          {:error, _} ->
            Logger.error("Failed to parse TikTok API response during token validation")
            {:error, "Failed to parse API response"}
        end
      
      {:ok, %{status_code: 401}} ->
        {:ok, false}
      
      {:ok, %{status_code: status_code, body: body}} ->
        Logger.warning(fn -> "TikTok OAuth token validation failed: HTTP #{status_code}, #{body}" end)
        {:error, "Token validation failed: HTTP #{status_code}"}
      
      {:error, %{reason: reason}} ->
        Logger.error("TikTok OAuth token validation error: #{inspect(reason)}")
        {:error, "Error communicating with TikTok API: #{inspect(reason)}"}
    end
  end

  @impl Myapp.SocialAuth
  def store_tokens(user_id, tokens, _params \\ %{}) do
    # This is a placeholder implementation.
    # In a real application, you would:
    # 1. Encrypt sensitive tokens
    # 2. Store tokens in a database
    # 3. Associate them with the user_id
    
    try do
      # Example implementation using ETS for demonstration purposes.
      # In a real app, you would use your database of choice.
      :ets.insert(:tiktok_tokens, {user_id, tokens})
      :ok
    rescue
      e ->
        Logger.error("Failed to store TikTok tokens: #{inspect(e)}")
        {:error, "Failed to store tokens"}
    end
  end

  @impl Myapp.SocialAuth
  def get_tokens(user_id, _params \\ %{}) do
    # This is a placeholder implementation.
    # In a real application, you would:
    # 1. Fetch tokens from database
    # 2. Decrypt sensitive tokens
    # 3. Return them in a standardized format
    
    try do
      # Example implementation using ETS for demonstration purposes
      case :ets.lookup(:tiktok_tokens, user_id) do
        [{^user_id, tokens}] -> {:ok, tokens}
        [] -> {:error, :not_found}
      end
    rescue
      e ->
        Logger.error("Failed to retrieve TikTok tokens: #{inspect(e)}")
        {:error, "Failed to retrieve tokens"}
    end
  end

  @impl Myapp.SocialAuth
  def revoke_tokens(_access_token, params \\ %{}) do
    open_id = Map.get(params, :open_id)
    
    # TikTok doesn't provide a dedicated token revocation endpoint
    # In a real application, you might want to delete the tokens from your database
    # or mark them as revoked
    
    if open_id do
      Logger.info("Marking TikTok tokens as revoked for user with open_id: #{open_id}")
    else
      Logger.info("Marking TikTok tokens as revoked")
    end
    
    # Return :ok to maintain API consistency with other providers
    :ok
  end

  @impl Myapp.SocialAuth
  def get_provider_config do
    %{
      api_key: api_key(),
      api_secret: api_secret(),
      redirect_uri: redirect_uri()
    }
  end

  @impl Myapp.SocialAuth
  def get_provider_name, do: :tiktok

  # Generate a random state parameter for CSRF protection
  defp generate_state_param do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end

  # Helper function to conditionally add open_id to params if present
  defp maybe_add_open_id(params, nil), do: params
  defp maybe_add_open_id(params, open_id), do: Map.put(params, "open_id", open_id)

  # Get the API key (client key) from configuration
  defp api_key do
    Application.get_env(:myapp, :tiktok_api)[:api_key] || 
    System.get_env("TIKTOK_CLIENT_KEY")
  end

  # Get the API secret (client secret) from configuration
  defp api_secret do
    Application.get_env(:myapp, :tiktok_api)[:api_secret] || 
    System.get_env("TIKTOK_CLIENT_SECRET")
  end

  # Get the redirect URI from configuration
  defp redirect_uri do
    Application.get_env(:myapp, :tiktok_api)[:redirect_uri] || 
    System.get_env("TIKTOK_REDIRECT_URI")
  end
end

