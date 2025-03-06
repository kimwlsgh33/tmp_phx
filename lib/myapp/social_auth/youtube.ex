defmodule Myapp.SocialAuth.YouTube do
  @moduledoc """
  YouTube OAuth2 authentication implementation following the SocialAuth behavior.
  
  This module provides standardized OAuth2 functionality for YouTube, including:
  - Authorization URL generation
  - Token exchange and refresh
  - Token validation and storage
  """
  @behaviour Myapp.SocialAuth
  
  alias OAuth2.Client
  
  @doc """
  Returns the provider name as an atom.
  """
  @impl Myapp.SocialAuth
  def get_provider_name, do: :youtube
  
  @doc """
  Returns the provider-specific configuration.
  """
  @impl Myapp.SocialAuth
  def get_provider_config do
    %{
      client_id: System.get_env("YOUTUBE_CLIENT_ID"),
      client_secret: System.get_env("YOUTUBE_CLIENT_SECRET"),
      redirect_uri: System.get_env("YOUTUBE_REDIRECT_URI"),
      site: "https://accounts.google.com",
      authorize_url: "/o/oauth2/auth",
      token_url: "/o/oauth2/token",
      scope: "https://www.googleapis.com/auth/youtube.readonly"
    }
  end
  
  @doc """
  Generates an authorization URL for the YouTube OAuth flow.
  """
  @impl Myapp.SocialAuth
  def generate_auth_url(_params \\ %{}) do
    config = get_provider_config()
    
    client = OAuth2.Client.new([
      strategy: OAuth2.Strategy.AuthCode,
      client_id: config.client_id,
      client_secret: config.client_secret,
      redirect_uri: config.redirect_uri,
      site: config.site,
      authorize_url: config.authorize_url,
      token_url: config.token_url
    ])
    
    auth_url = OAuth2.Client.authorize_url!(client, scope: config.scope)
    {:ok, auth_url}
  rescue
    error ->
      {:error, "Failed to generate authorization URL: #{inspect(error)}"}
  end
  
  @doc """
  Exchanges an authorization code for an access token.
  """
  @impl Myapp.SocialAuth
  def exchange_code_for_token(code, _params \\ %{}) do
    config = get_provider_config()
    
    client = OAuth2.Client.new([
      strategy: OAuth2.Strategy.AuthCode,
      client_id: config.client_id,
      client_secret: config.client_secret,
      redirect_uri: config.redirect_uri,
      site: config.site,
      authorize_url: config.authorize_url,
      token_url: config.token_url
    ])
    
    case OAuth2.Client.get_token(client, code: code) do
      {:ok, %{token: token}} ->
        {:ok, %{
          access_token: token.access_token,
          refresh_token: token.refresh_token,
          expires_at: token.expires_at,
          token_type: token.token_type
        }}
      {:error, %{reason: reason}} ->
        {:error, "Failed to exchange code for token: #{inspect(reason)}"}
      error ->
        {:error, "Unexpected error during token exchange: #{inspect(error)}"}
    end
  rescue
    error ->
      {:error, "Failed to exchange code for token: #{inspect(error)}"}
  end
  
  @doc """
  Refreshes an expired access token using a refresh token.
  """
  @impl Myapp.SocialAuth
  def refresh_token(refresh_token, _params \\ %{}) do
    config = get_provider_config()
    
    client = OAuth2.Client.new([
      strategy: OAuth2.Strategy.Refresh,
      client_id: config.client_id,
      client_secret: config.client_secret,
      redirect_uri: config.redirect_uri,
      site: config.site,
      authorize_url: config.authorize_url,
      token_url: config.token_url
    ])
    
    client = Map.put(client, :refresh_token, refresh_token)
    
    case OAuth2.Client.refresh_token(client) do
      {:ok, %{token: token}} ->
        {:ok, %{
          access_token: token.access_token,
          refresh_token: token.refresh_token || refresh_token,
          expires_at: token.expires_at,
          token_type: token.token_type
        }}
      {:error, %{reason: reason}} ->
        {:error, "Failed to refresh token: #{inspect(reason)}"}
      error ->
        {:error, "Unexpected error during token refresh: #{inspect(error)}"}
    end
  rescue
    error ->
      {:error, "Failed to refresh token: #{inspect(error)}"}
  end
  
  @doc """
  Validates if a token is still valid and not expired.
  """
  @impl Myapp.SocialAuth
  def validate_token(access_token, _params \\ %{}) do
    url = "https://www.googleapis.com/oauth2/v3/tokeninfo?access_token=#{access_token}"
    
    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} ->
        response = Jason.decode!(body)
        # Check if token belongs to our app (aud field should match client_id)
        config = get_provider_config()
        
        if response["aud"] == config.client_id do
          {:ok, true}
        else
          {:ok, false}
        end
      
      {:ok, %{status_code: 400}} ->
        # Invalid token
        {:ok, false}
      
      {:error, reason} ->
        {:error, "Failed to validate token: #{inspect(reason)}"}
    end
  rescue
    error ->
      {:error, "Failed to validate token: #{inspect(error)}"}
  end
  
  @doc """
  Stores authentication tokens securely.
  """
  @impl Myapp.SocialAuth
  def store_tokens(user_id, tokens, _params \\ %{}) do
    # This would typically store tokens in a database
    # For now, we'll implement a basic version
    try do
      Myapp.SocialMediaToken.store_token(
        user_id,
        :youtube,
        tokens.access_token,
        tokens.refresh_token,
        tokens.expires_at
      )
      :ok
    rescue
      error ->
        {:error, "Failed to store tokens: #{inspect(error)}"}
    end
  end
  
  @doc """
  Retrieves stored authentication tokens for a user.
  """
  @impl Myapp.SocialAuth
  def get_tokens(user_id, _params \\ %{}) do
    # This would typically retrieve tokens from a database
    # For now, we'll implement a basic version
    try do
      case Myapp.SocialMediaToken.get_token(user_id, :youtube) do
        nil ->
          {:error, "No tokens found for this user"}
        token ->
          {:ok, %{
            access_token: token.access_token,
            refresh_token: token.refresh_token,
            expires_at: token.expires_at,
            token_type: "Bearer"
          }}
      end
    rescue
      error ->
        {:error, "Failed to retrieve tokens: #{inspect(error)}"}
    end
  end
  
  @doc """
  Revokes authentication tokens, typically used during logout or disconnection.
  """
  @impl Myapp.SocialAuth
  def revoke_tokens(access_token, _params \\ %{}) do
    url = "https://accounts.google.com/o/oauth2/revoke?token=#{access_token}"
    
    case HTTPoison.get(url) do
      {:ok, %{status_code: 200}} ->
        :ok
      
      {:ok, %{status_code: status, body: body}} ->
        {:error, "Failed to revoke token (status #{status}): #{body}"}
      
      {:error, reason} ->
        {:error, "Failed to revoke token: #{inspect(reason)}"}
    end
  rescue
    error ->
      {:error, "Failed to revoke token: #{inspect(error)}"}
  end
end

