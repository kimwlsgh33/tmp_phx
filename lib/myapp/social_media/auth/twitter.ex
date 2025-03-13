defmodule Myapp.SocialAuth.Twitter do
  @moduledoc """
  Twitter implementation of the SocialAuth behaviour.
  Handles OAuth 2.0 authentication flow for Twitter/X.
  """

  @behaviour Myapp.SocialAuth

  require Logger
  alias Myapp.HttpClient
  alias Myapp.Accounts.SocialMediaToken

  @impl Myapp.SocialAuth
  def generate_auth_url(params \\ %{}) do
    scope = Map.get(params, :scope, "tweet.read tweet.write users.read offline.access")
    
    try do
      query_params = URI.encode_query(%{
        "response_type" => "code",
        "client_id" => api_key(),
        "redirect_uri" => redirect_uri(),
        "scope" => scope,
        "state" => generate_state_param(),
        "code_challenge" => generate_code_challenge(),
        "code_challenge_method" => "S256"
      })

      {:ok, "https://twitter.com/i/oauth2/authorize?#{query_params}"}
    rescue
      e ->
        Logger.error("Failed to generate Twitter auth URL: #{inspect(e)}")
        {:error, {:auth_url_generation, "Failed to generate authorization URL"}}
    end
  end

  @impl Myapp.SocialAuth
  def exchange_code_for_token(code, _params \\ %{}) do
    url = "https://api.twitter.com/2/oauth2/token"
    
    body = [
      client_id: api_key(),
      client_secret: api_secret(),
      grant_type: "authorization_code",
      code: code,
      redirect_uri: redirect_uri()
    ]

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    case HttpClient.post(url, headers: headers, body: body) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, token_data} -> {:ok, token_data}
          {:error, _} -> {:error, {:token_parse, "Failed to parse token response"}}
        end
      
      {:ok, %{status_code: status_code, body: body}} ->
        Logger.error("Twitter OAuth token exchange failed: HTTP #{status_code}, #{body}")
        {:error, {:token_exchange, "Failed to exchange code for token: HTTP #{status_code}"}}
      
      {:error, %{reason: reason}} ->
        Logger.error("Twitter OAuth token exchange error: #{inspect(reason)}")
        {:error, {:network, "Error communicating with Twitter API"}}
    end
  end

  @impl Myapp.SocialAuth
  def refresh_token(refresh_token, _params \\ %{}) do
    url = "https://api.twitter.com/2/oauth2/token"
    
    body = [
      client_id: api_key(),
      client_secret: api_secret(),
      grant_type: "refresh_token",
      refresh_token: refresh_token
    ]

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    case HttpClient.post(url, headers: headers, body: body) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, token_data} -> {:ok, token_data}
          {:error, _} -> {:error, {:token_parse, "Failed to parse token response"}}
        end
      
      {:ok, %{status_code: status_code, body: body}} ->
        Logger.error("Twitter OAuth token refresh failed: HTTP #{status_code}, #{body}")
        {:error, {:token_refresh, "Failed to refresh token: HTTP #{status_code}"}}
      
      {:error, %{reason: reason}} ->
        Logger.error("Twitter OAuth token refresh error: #{inspect(reason)}")
        {:error, {:network, "Error communicating with Twitter API"}}
    end
  end

  @impl Myapp.SocialAuth
  def validate_token(access_token, _params \\ %{}) do
    url = "https://api.twitter.com/2/users/me"
    headers = [{"Authorization", "Bearer #{access_token}"}]

    case HttpClient.get(url, headers: headers) do
      {:ok, %{status_code: 200}} ->
        {:ok, true}
      
      {:ok, %{status_code: 401}} ->
        {:ok, false}
      
      {:ok, %{status_code: status_code, body: body}} ->
        Logger.warning(fn -> "Twitter OAuth token validation failed: HTTP #{status_code}, #{body}" end)
        {:error, {:validation, "Token validation failed: HTTP #{status_code}"}}
      
      {:error, %{reason: reason}} ->
        Logger.error("Twitter OAuth token validation error: #{inspect(reason)}")
        {:error, {:network, "Error communicating with Twitter API"}}
    end
  end

  @impl Myapp.SocialAuth
  def store_tokens(user_id, tokens, _params \\ %{}) do
    case SocialMediaToken.store_tokens(user_id, :twitter, tokens) do
      {:ok, _token} -> :ok
      {:error, changeset} ->
        Logger.error("Failed to store Twitter tokens: #{inspect(changeset.errors)}")
        {:error, {:storage, "Failed to store tokens"}}
    end
  end

  @impl Myapp.SocialAuth
  def get_tokens(user_id, _params \\ %{}) do
    case SocialMediaToken.get_active_tokens(user_id, :twitter) do
      {:ok, token} -> 
        {:ok, %{
          "access_token" => token.access_token_text,
          "refresh_token" => token.refresh_token_text,
          "scope" => token.scope,
          "expires_at" => token.expires_at
        }}
      {:error, _} = error -> error
    end
  end

  @impl Myapp.SocialAuth
  def revoke_tokens(access_token, _params \\ %{}) do
    url = "https://api.twitter.com/2/oauth2/revoke"
    
    body = [
      client_id: api_key(),
      client_secret: api_secret(),
      token: access_token,
      token_type_hint: "access_token"
    ]

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    case HttpClient.post(url, headers: headers, body: body) do
      {:ok, %{status_code: 200}} ->
        :ok
      
      {:ok, %{status_code: status_code, body: body}} ->
        Logger.error("Twitter OAuth token revocation failed: HTTP #{status_code}, #{body}")
        {:error, {:revocation, "Failed to revoke token: HTTP #{status_code}"}}
      
      {:error, %{reason: reason}} ->
        Logger.error("Twitter OAuth token revocation error: #{inspect(reason)}")
        {:error, {:network, "Error communicating with Twitter API"}}
    end
  end

  @impl Myapp.SocialAuth
  def get_provider_config do
    # TODO: Move configuration retrieval to SocialMediaConfig module
    %{
      api_key: api_key(),
      api_secret: api_secret(),
      redirect_uri: redirect_uri()
    }
  end

  @impl Myapp.SocialAuth
  def get_provider_name, do: :twitter

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

  # TODO: Move these config getters to SocialMediaConfig module
  defp api_key do
    Application.get_env(:myapp, :twitter_api)[:api_key]
  end

  defp api_secret do
    Application.get_env(:myapp, :twitter_api)[:api_secret]
  end

  defp redirect_uri do
    Application.get_env(:myapp, :twitter_api)[:redirect_uri]
  end
end

