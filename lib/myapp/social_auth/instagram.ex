defmodule Myapp.SocialAuth.Instagram do
  @moduledoc """
  Instagram implementation of the SocialAuth behaviour.
  Handles OAuth 2.0 authentication flow for Instagram.
  """

  @behaviour Myapp.SocialAuth

  require Logger

  @impl Myapp.SocialAuth
  def generate_auth_url(params \\ %{}) do
    scope = Map.get(params, :scope, "user_profile,user_media")
    
    try do
      query_params = URI.encode_query(%{
        "response_type" => "code",
        "client_id" => api_key(),
        "redirect_uri" => redirect_uri(),
        "scope" => scope
      })

      {:ok, "https://api.instagram.com/oauth/authorize?#{query_params}"}
    rescue
      e ->
        Logger.error("Failed to generate Instagram auth URL: #{inspect(e)}")
        {:error, "Failed to generate authorization URL"}
    end
  end

  @impl Myapp.SocialAuth
  def exchange_code_for_token(code, _params \\ %{}) do
    url = "https://api.instagram.com/oauth/access_token"
    
    form_data = [
      client_id: api_key(),
      client_secret: api_secret(),
      grant_type: "authorization_code",
      code: code,
      redirect_uri: redirect_uri()
    ]

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    case HTTPoison.post(url, URI.encode_query(form_data), headers) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, token_data} ->
            # For Instagram, we need to exchange for a long-lived token
            exchange_for_long_lived_token(token_data["access_token"])
          
          {:error, _} ->
            Logger.error("Failed to parse Instagram token response")
            {:error, "Failed to parse token response"}
        end
      
      {:ok, %{status_code: status_code, body: body}} ->
        Logger.error("Instagram OAuth token exchange failed: HTTP #{status_code}, #{body}")
        {:error, "Failed to exchange code for token: HTTP #{status_code}"}
      
      {:error, %{reason: reason}} ->
        Logger.error("Instagram OAuth token exchange error: #{inspect(reason)}")
        {:error, "Error communicating with Instagram API: #{inspect(reason)}"}
    end
  end

  @impl Myapp.SocialAuth
  def refresh_token(refresh_token, _params \\ %{}) do
    url = "https://graph.instagram.com/refresh_access_token"
    
    params = [
      grant_type: "ig_refresh_token",
      access_token: refresh_token
    ]
    
    url_with_params = "#{url}?#{URI.encode_query(params)}"
    
    case HTTPoison.get(url_with_params) do
      {:ok, %{status_code: status_code, body: body}} when status_code in 200..299 ->
        case Jason.decode(body) do
          {:ok, %{"access_token" => access_token, "expires_in" => expires_in}} ->
            {:ok, %{
              "access_token" => access_token,
              "expires_in" => expires_in,
              "token_type" => "bearer"
            }}
          
          {:ok, error} ->
            Logger.error("Instagram API error during token refresh: #{inspect(error)}")
            {:error, "Instagram API error: #{inspect(error)}"}
          
          {:error, _} ->
            Logger.error("Failed to parse Instagram response during token refresh")
            {:error, "Failed to parse Instagram response"}
        end
      
      {:ok, %{status_code: status_code, body: body}} ->
        Logger.error("Instagram OAuth token refresh failed: HTTP #{status_code}, #{body}")
        {:error, "Failed to refresh token: HTTP #{status_code}"}
      
      {:error, %{reason: reason}} ->
        Logger.error("Instagram OAuth token refresh error: #{inspect(reason)}")
        {:error, "Error communicating with Instagram API: #{inspect(reason)}"}
    end
  end

  @impl Myapp.SocialAuth
  def validate_token(access_token, _params \\ %{}) do
    url = "https://graph.instagram.com/me"
    
    params = [
      access_token: access_token,
      fields: "id,username"
    ]
    
    url_with_params = "#{url}?#{URI.encode_query(params)}"
    
    case HTTPoison.get(url_with_params) do
      {:ok, %{status_code: 200}} ->
        {:ok, true}
      
      {:ok, %{status_code: 401}} ->
        {:ok, false}
      
      {:ok, %{status_code: status_code, body: body}} ->
        Logger.warn("Instagram OAuth token validation failed: HTTP #{status_code}, #{body}")
        {:error, "Token validation failed: HTTP #{status_code}"}
      
      {:error, %{reason: reason}} ->
        Logger.error("Instagram OAuth token validation error: #{inspect(reason)}")
        {:error, "Error communicating with Instagram API: #{inspect(reason)}"}
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
      :ets.insert(:instagram_tokens, {user_id, tokens})
      :ok
    rescue
      e ->
        Logger.error("Failed to store Instagram tokens: #{inspect(e)}")
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
      case :ets.lookup(:instagram_tokens, user_id) do
        [{^user_id, tokens}] -> {:ok, tokens}
        [] -> {:error, :not_found}
      end
    rescue
      e ->
        Logger.error("Failed to retrieve Instagram tokens: #{inspect(e)}")
        {:error, "Failed to retrieve tokens"}
    end
  end

  @impl Myapp.SocialAuth
  def revoke_tokens(_access_token, _params \\ %{}) do
    # Instagram's API doesn't provide a straightforward way to revoke tokens
    # However, we can implement this as a placeholder for API consistency
    # In a real application, you might want to delete the tokens from your database
    # or mark them as revoked
    
    Logger.warn("Instagram API doesn't support direct token revocation. Tokens will expire naturally.")
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
  def get_provider_name, do: :instagram

  # Helper function to exchange a short-lived token for a long-lived token
  defp exchange_for_long_lived_token(token) do
    url = "https://graph.instagram.com/access_token"
    params = [
      grant_type: "ig_exchange_token",
      client_secret: api_secret(),
      access_token: token
    ]
    
    url_with_params = "#{url}?#{URI.encode_query(params)}"
    
    case HTTPoison.get(url_with_params) do
      {:ok, %{status_code: status_code, body: body}} when status_code in 200..299 ->
        case Jason.decode(body) do
          {:ok, %{"access_token" => access_token, "expires_in" => expires_in}} ->
            {:ok, %{
              "access_token" => access_token,
              "expires_in" => expires_in,
              "token_type" => "bearer"
            }}
          
          {:ok, error} ->
            Logger.error("Instagram API error during token exchange: #{inspect(error)}")
            {:error, "Instagram API error: #{inspect(error)}"}
          
          {:error, _} ->
            Logger.error("Failed to parse Instagram response during token exchange")
            {:error, "Failed to parse Instagram response"}
        end
      
      {:ok, %{status_code: status_code, body: body}} ->
        Logger.error("Instagram long-lived token exchange failed: HTTP #{status_code}, #{body}")
        {:error, "Failed to exchange for long-lived token: HTTP #{status_code}"}
      
      {:error, %{reason: reason}} ->
        Logger.error("Instagram long-lived token exchange error: #{inspect(reason)}")
        {:error, "Error communicating with Instagram API: #{inspect(reason)}"}
    end
  end

  # Get the API key from configuration
  defp api_key do
    Application.get_env(:myapp, :instagram_api)[:api_key] || 
    System.get_env("INSTAGRAM_CLIENT_ID")
  end

  # Get the API secret from configuration
  defp api_secret do
    Application.get_env(:myapp, :instagram_api)[:api_secret] || 
    System.get_env("INSTAGRAM_CLIENT_SECRET")
  end

  # Get the redirect URI from configuration
  defp redirect_uri do
    Application.get_env(:myapp, :instagram_api)[:redirect_uri] || 
    System.get_env("INSTAGRAM_REDIRECT_URI")
  end
end

