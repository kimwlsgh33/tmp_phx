defmodule Myapp.TwitterOauth do
  @moduledoc """
  Twitter OAuth 2.0 implementation for authentication and token management.
  """

  require Logger

  @doc """
  Generates an OAuth URL for Twitter authentication.
  """
  def generate_oauth_url(scope \\ "tweet.read tweet.write users.read offline.access") do
    query_params = URI.encode_query(%{
      "response_type" => "code",
      "client_id" => api_key(),
      "redirect_uri" => redirect_uri(),
      "scope" => scope,
      "state" => generate_state_param(),
      "code_challenge" => generate_code_challenge(),
      "code_challenge_method" => "S256"
    })

    "https://twitter.com/i/oauth2/authorize?#{query_params}"
  end

  @doc """
  Exchanges an authorization code for an access token.
  """
  def exchange_code_for_token(code) do
    url = "https://api.twitter.com/2/oauth2/token"
    
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
        {:ok, Jason.decode!(body)}
      
      {:ok, %{status_code: status_code, body: body}} ->
        Logger.error("Twitter OAuth token exchange failed: HTTP #{status_code}, #{body}")
        {:error, "Failed to exchange code for token: HTTP #{status_code}"}
      
      {:error, %{reason: reason}} ->
        Logger.error("Twitter OAuth token exchange error: #{inspect(reason)}")
        {:error, "Error communicating with Twitter API: #{inspect(reason)}"}
    end
  end

  @doc """
  Refreshes an expired access token using a refresh token.
  """
  def refresh_token(refresh_token) do
    url = "https://api.twitter.com/2/oauth2/token"
    
    form_data = [
      client_id: api_key(),
      client_secret: api_secret(),
      grant_type: "refresh_token",
      refresh_token: refresh_token
    ]

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    case HTTPoison.post(url, URI.encode_query(form_data), headers) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}
      
      {:ok, %{status_code: status_code, body: body}} ->
        Logger.error("Twitter OAuth token refresh failed: HTTP #{status_code}, #{body}")
        {:error, "Failed to refresh token: HTTP #{status_code}"}
      
      {:error, %{reason: reason}} ->
        Logger.error("Twitter OAuth token refresh error: #{inspect(reason)}")
        {:error, "Error communicating with Twitter API: #{inspect(reason)}"}
    end
  end

  @doc """
  Validates an access token by making a test request to the Twitter API.
  """
  def validate_token(access_token) do
    url = "https://api.twitter.com/2/users/me"
    
    headers = [
      {"Authorization", "Bearer #{access_token}"}
    ]

    case HTTPoison.get(url, headers) do
      {:ok, %{status_code: 200}} ->
        {:ok, "Token is valid"}
      
      {:ok, %{status_code: 401}} ->
        {:error, :token_invalid}
      
      {:ok, %{status_code: status_code, body: body}} ->
        Logger.warn("Twitter OAuth token validation failed: HTTP #{status_code}, #{body}")
        {:error, "Token validation failed: HTTP #{status_code}"}
      
      {:error, %{reason: reason}} ->
        Logger.error("Twitter OAuth token validation error: #{inspect(reason)}")
        {:error, "Error communicating with Twitter API: #{inspect(reason)}"}
    end
  end

  # Generate a random state parameter for CSRF protection
  defp generate_state_param do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end

  # Generate code challenge for PKCE
  defp generate_code_challenge do
    verifier = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    
    :crypto.hash(:sha256, verifier)
    |> Base.url_encode64(padding: false)
    |> String.replace("+", "-")
    |> String.replace("/", "_")
    |> String.replace("=", "")
  end

  # Get the API key from configuration
  defp api_key do
    Application.get_env(:myapp, :twitter_api)[:api_key]
  end

  # Get the API secret from configuration
  defp api_secret do
    Application.get_env(:myapp, :twitter_api)[:api_secret]
  end

  # Get the redirect URI from configuration
  defp redirect_uri do
    Application.get_env(:myapp, :twitter_api)[:redirect_uri]
  end
end

