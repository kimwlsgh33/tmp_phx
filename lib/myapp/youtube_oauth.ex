defmodule Myapp.YoutubeOauth do
  @moduledoc """
  YouTube OAuth2 strategy for authorization and token handling.
  """
  use OAuth2.Strategy

  def client do
    OAuth2.Client.new(
      strategy: __MODULE__,
      client_id: System.get_env("YOUTUBE_CLIENT_ID"),
      client_secret: System.get_env("YOUTUBE_CLIENT_SECRET"),
      redirect_uri: System.get_env("YOUTUBE_REDIRECT_URI"),
      site: "https://accounts.google.com",
      authorize_url: "/o/oauth2/auth",
      token_url: "/o/oauth2/token"
    )
  end

  def authorize_url do
    OAuth2.Client.authorize_url!(client(),
      scope: "https://www.googleapis.com/auth/youtube.readonly"
    )
  end

  def get_token(code) do
    OAuth2.Client.get_token(client(), code: code)
  end

  @doc """
  Creates an OAuth2 client with the provided access token.
  
  This function is useful when you already have an access token and need to
  create a connection to the YouTube API without going through the authorization flow again.
  
  ## Parameters
    - access_token: The OAuth2 access token for YouTube API

  ## Returns
    An OAuth2.Client struct configured with the access token
  """
  def client_with_token(access_token) do
    client()
    |> OAuth2.Client.put_param(:client_secret, client().client_secret)
    |> OAuth2.Client.put_header("Authorization", "Bearer #{access_token}")
    |> OAuth2.Client.put_header("Accept", "application/json")
    |> Map.put(:token, %OAuth2.AccessToken{
      access_token: access_token,
      token_type: "Bearer"
    })
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
