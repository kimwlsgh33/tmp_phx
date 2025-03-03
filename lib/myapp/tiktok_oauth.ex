defmodule Myapp.TiktokOauth do
  @moduledoc """
  TikTok OAuth2 strategy for authorization and token handling.
  Used for authenticating with TikTok API for video uploads.
  """
  use OAuth2.Strategy

  def client do
    OAuth2.Client.new(
      strategy: __MODULE__,
      client_id: System.get_env("TIKTOK_CLIENT_ID"),
      client_secret: System.get_env("TIKTOK_CLIENT_SECRET"),
      redirect_uri: System.get_env("TIKTOK_REDIRECT_URI"),
      site: "https://open-api.tiktok.com",
      authorize_url: "/platform/oauth/connect/",
      token_url: "/oauth/access_token/"
    )
  end

  def authorize_url do
    OAuth2.Client.authorize_url!(client(),
      scope: "video.upload,video.publish,user.info.basic"
    )
  end

  def get_token(code) do
    OAuth2.Client.get_token(client(), code: code)
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

