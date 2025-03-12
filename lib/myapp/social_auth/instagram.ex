defmodule Myapp.SocialAuth.Instagram do
  @moduledoc """
  Instagram implementation of the SocialAuth behaviour.
  Handles OAuth 2.0 authentication flow for Instagram.
  """

  @behaviour Myapp.SocialAuth

  require Logger
  alias Myapp.SocialMediaToken

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
        Logger.warning(fn -> "Instagram OAuth token validation failed: HTTP #{status_code}, #{body}" end)
        {:error, "Token validation failed: HTTP #{status_code}"}
      
      {:error, %{reason: reason}} ->
        Logger.error("Instagram OAuth token validation error: #{inspect(reason)}")
        {:error, "Error communicating with Instagram API: #{inspect(reason)}"}
    end
  end

  @impl Myapp.SocialAuth
  def store_tokens(user_id, tokens, _params \\ %{}) do
    # Convert user_id to integer if it's a binary
    user_id = if is_binary(user_id), do: String.to_integer(user_id), else: user_id
    
    # Prepare token data for SocialMediaToken
    token_info = %{
      access_token: tokens["access_token"],
      refresh_token: tokens["refresh_token"],
      expires_at: case tokens["expires_in"] do
        nil -> nil
        expires_in -> Myapp.SocialMediaToken.calculate_expiry(expires_in)
      end,
      metadata: %{
        token_type: tokens["token_type"] || "bearer"
      }
    }
    
    case SocialMediaToken.store_token(user_id, :instagram, token_info) do
      {:ok, _} -> :ok
      {:error, reason} ->
        Logger.error("Failed to store Instagram tokens: #{inspect(reason)}")
        {:error, "Failed to store tokens"}
    end
  end

  @impl Myapp.SocialAuth
  def get_tokens(user_id, _params \\ %{}) do
    # Convert user_id to integer if it's a binary
    user_id = if is_binary(user_id), do: String.to_integer(user_id), else: user_id
    
    # Get the access token
    case SocialMediaToken.get_token(user_id, :instagram, :access) do
      {:ok, access_token} ->
        # Try to get the refresh token if available
        refresh_token = case SocialMediaToken.get_token(user_id, :instagram, :refresh) do
          {:ok, token} -> token
          _ -> nil
        end
        
        # Check if the token is valid
        is_valid = case SocialMediaToken.valid_token?(user_id, :instagram) do
          {:ok, valid} -> valid
          _ -> false
        end
        
        if is_valid do
          {:ok, %{
            "access_token" => access_token,
            "refresh_token" => refresh_token,
            "token_type" => "bearer"
          }}
        else
          # If token is not valid, try to refresh it
          case SocialMediaToken.refresh_token(user_id, :instagram) do
            {:ok, _} ->
              # Get the new access token after refresh
              case SocialMediaToken.get_token(user_id, :instagram, :access) do
                {:ok, new_access_token} ->
                  {:ok, %{
                    "access_token" => new_access_token,
                    "refresh_token" => refresh_token,
                    "token_type" => "bearer"
                  }}
                error -> error
              end
            
            {:error, _reason} ->
              # Return the possibly expired token with a warning
              Logger.warning("Using potentially expired Instagram token for user #{user_id}")
              {:ok, %{
                "access_token" => access_token,
                "refresh_token" => refresh_token,
                "token_type" => "bearer"
              }}
          end
        end
      
      {:error, :token_not_found} ->
        {:error, :not_found}
      
      {:error, reason} ->
        Logger.error("Failed to retrieve Instagram tokens: #{inspect(reason)}")
        {:error, "Failed to retrieve tokens"}
    end
  end

  @impl Myapp.SocialAuth
  def revoke_tokens(user_id, _params \\ %{}) do
    # Instagram's API doesn't provide a straightforward way to revoke tokens
    # However, we can delete the token from our database
    
    # Convert user_id to integer if it's a binary
    user_id = if is_binary(user_id), do: String.to_integer(user_id), else: user_id
    
    # Delete the token from our database
    case SocialMediaToken.delete_token(user_id, :instagram) do
      :ok ->
        Logger.info("Removed Instagram token for user #{user_id}")
        :ok
      
      {:error, _reason} ->
        Logger.warning(fn -> "Failed to remove Instagram token for user #{user_id}, but Instagram API doesn't support direct token revocation anyway. Tokens will expire naturally." end)
        :ok  # Return :ok even if delete failed since Instagram doesn't support revocation
    end
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

