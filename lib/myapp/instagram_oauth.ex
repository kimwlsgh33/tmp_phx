defmodule Myapp.InstagramOauth do
  @moduledoc """
  Instagram OAuth2 strategy for authorization and token handling.
  Used for authenticating with Instagram Graph API for media management.
  
  This module implements the OAuth2 flow for Instagram, including
  authorization URL generation, token retrieval, and refresh token handling.
  """
  use OAuth2.Strategy

  @doc """
  Returns a new OAuth2 client for Instagram authentication.
  
  Configure your application with the following environment variables:
  - INSTAGRAM_CLIENT_ID
  - INSTAGRAM_CLIENT_SECRET
  - INSTAGRAM_REDIRECT_URI
  """
  def client do
    OAuth2.Client.new(
      strategy: __MODULE__,
      client_id: System.get_env("INSTAGRAM_CLIENT_ID"),
      client_secret: System.get_env("INSTAGRAM_CLIENT_SECRET"),
      redirect_uri: System.get_env("INSTAGRAM_REDIRECT_URI"),
      site: "https://api.instagram.com",
      authorize_url: "https://api.instagram.com/oauth/authorize",
      token_url: "https://api.instagram.com/oauth/access_token"
    )
    |> IO.inspect(label: "Instagram OAuth Client")
  end

  @doc """
  Generates the authorization URL for Instagram OAuth.
  
  This URL should be used to redirect users to the Instagram permission screen.
  Default scope includes permissions for basic profile info, media management, 
  and publishing capabilities.
  """
  def authorize_url do
    # Using correct scopes for Instagram Basic Display
    OAuth2.Client.authorize_url!(client(),
      scope: "user_profile,user_media",
      response_type: "code"
    )
    |> IO.inspect(label: "Instagram Auth URL")
  end

  @doc """
  Retrieves an access token using the provided authorization code.
  
  ## Parameters
    * `code` - The authorization code returned by Instagram after user approves permissions
  
  ## Returns
    * `{:ok, %OAuth2.AccessToken{}}` - Token retrieved successfully
    * `{:error, reason}` - Failed to retrieve token
  """
  def get_token(code) do
    case OAuth2.Client.get_token(client(), code: code) do
      {:ok, %{token: token} = client} ->
        # For Instagram, we need to make a second request to get the long-lived token
        case exchange_for_long_lived_token(token.access_token) do
          {:ok, long_lived_token} -> {:ok, long_lived_token}
          error -> error
        end
      
      {:error, %OAuth2.Error{reason: reason}} ->
        {:error, reason}
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Exchanges a short-lived access token for a long-lived access token.
  
  Instagram's short-lived tokens are valid for 1 hour.
  Long-lived tokens are valid for 60 days.
  
  ## Parameters
    * `token` - The short-lived access token
  
  ## Returns
    * `{:ok, %{"access_token" => token, "expires_in" => expires_in}}` - Token exchanged successfully
    * `{:error, reason}` - Failed to exchange token
  """
  def exchange_for_long_lived_token(token) do
    url = "https://graph.instagram.com/access_token"
    params = [
      grant_type: "ig_exchange_token",
      client_secret: client().client_secret,
      access_token: token
    ]
    
    url_with_params = "#{url}?#{URI.encode_query(params)}"
    
    case HTTPoison.get(url_with_params) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} when status_code in 200..299 ->
        case Jason.decode(body) do
          {:ok, %{"access_token" => access_token, "expires_in" => expires_in}} ->
            {:ok, %{
              "access_token" => access_token,
              "expires_in" => expires_in,
              "token_type" => "bearer"
            }}
          
          {:ok, error} ->
            {:error, "Instagram API error: #{inspect(error)}"}
          
          {:error, _} ->
            {:error, "Failed to parse Instagram response"}
        end
      
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "Instagram API error: Status #{status_code}, #{body}"}
      
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Failed to connect to Instagram API: #{inspect(reason)}"}
    end
  end

  @doc """
  Refreshes a long-lived access token.
  
  Long-lived access tokens can be refreshed within 60 days to get a new
  long-lived token with a new 60-day expiration.
  
  ## Parameters
    * `token` - The long-lived access token to refresh
  
  ## Returns
    * `{:ok, %{"access_token" => token, "expires_in" => expires_in}}` - Token refreshed successfully
    * `{:error, reason}` - Failed to refresh token
  """
  def refresh_long_lived_token(token) do
    url = "https://graph.instagram.com/refresh_access_token"
    params = [
      grant_type: "ig_refresh_token",
      access_token: token
    ]
    
    url_with_params = "#{url}?#{URI.encode_query(params)}"
    
    case HTTPoison.get(url_with_params) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} when status_code in 200..299 ->
        case Jason.decode(body) do
          {:ok, %{"access_token" => access_token, "expires_in" => expires_in}} ->
            {:ok, %{
              "access_token" => access_token,
              "expires_in" => expires_in,
              "token_type" => "bearer"
            }}
          
          {:ok, error} ->
            {:error, "Instagram API error: #{inspect(error)}"}
          
          {:error, _} ->
            {:error, "Failed to parse Instagram response"}
        end
      
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "Instagram API error: Status #{status_code}, #{body}"}
      
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Failed to connect to Instagram API: #{inspect(reason)}"}
    end
  end

  # OAuth2.Strategy implementation
  @impl OAuth2.Strategy
  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  @impl OAuth2.Strategy
  def get_token(client, params, headers) do
    client
    |> OAuth2.Client.put_param(:client_secret, client.client_secret)
    |> OAuth2.Client.put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
