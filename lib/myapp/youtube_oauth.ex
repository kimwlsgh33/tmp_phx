defmodule Myapp.YoutubeOauth do
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
    OAuth2.Client.get_token(code: code)
  end
end
