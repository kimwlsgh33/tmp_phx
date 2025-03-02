defmodule MyappWeb.SocialMediaController do
  @moduledoc """
  Base controller module for social media integrations.
  Provides common controller logic and functions that can be used by
  platform-specific controllers (Twitter, TikTok, Instagram, etc.).
  """
  use MyappWeb, :controller

  alias Myapp.SocialMediaConfig
  
  @doc """
  Validates the requested provider and returns the corresponding modules
  for social auth and social media API interactions.
  """
  def validate_provider(provider) when is_binary(provider) do
    case SocialMediaConfig.get_provider_modules(provider) do
      {:ok, %{auth_module: auth_module, api_module: api_module}} -> 
        {:ok, auth_module, api_module}
      {:error, reason} -> 
        {:error, reason}
    end
  end
  
  def validate_provider(_), do: {:error, :invalid_provider}

  @doc """
  Common function to handle OAuth connection initiation.
  Generates an authorization URL and redirects the user to it.
  """
  def handle_connect(conn, provider, params \\ %{}) do
    with {:ok, auth_module, _} <- validate_provider(provider),
         {:ok, auth_url} <- auth_module.authorization_url(params) do
      redirect(conn, external: auth_url)
    else
      {:error, :invalid_provider} ->
        conn
        |> put_flash(:error, "Invalid social media provider")
        |> redirect(to: ~p"/")
      
      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to connect to #{provider}: #{inspect(reason)}")
        |> redirect(to: ~p"/")
    end
  end

  @doc """
  Common function to handle OAuth callback.
  Exchanges the authorization code for access tokens and stores them.
  """
  def handle_auth_callback(conn, provider, params) do
    with {:ok, auth_module, api_module} <- validate_provider(provider),
         {:ok, tokens} <- auth_module.exchange_token(params),
         :ok <- store_tokens(conn, provider, tokens) do
      conn
      |> put_flash(:info, "Successfully connected to #{provider}")
      |> redirect(to: ~p"/social/#{provider}")
    else
      {:error, :invalid_provider} ->
        conn
        |> put_flash(:error, "Invalid social media provider")
        |> redirect(to: ~p"/")
      
      {:error, reason} ->
        conn
        |> put_flash(:error, "Authentication failed with #{provider}: #{inspect(reason)}")
        |> redirect(to: ~p"/social/#{provider}")
    end
  end

  @doc """
  Common function to check if a user is authenticated with a provider.
  """
  def check_auth(conn, provider) do
    with {:ok, _, api_module} <- validate_provider(provider),
         {:ok, tokens} <- get_tokens(conn, provider),
         {:ok, _} <- api_module.verify_auth(tokens) do
      {:ok, tokens}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Common function to handle post creation across social media platforms.
  """
  def handle_post(conn, provider, params) do
    with {:ok, _, api_module} <- validate_provider(provider),
         {:ok, tokens} <- get_tokens(conn, provider),
         {:ok, post_result} <- api_module.create_post(tokens, params) do
      {:ok, post_result}
    else
      {:error, :not_authenticated} ->
        conn
        |> put_flash(:error, "You need to connect your #{provider} account first")
        |> redirect(to: ~p"/social/#{provider}")
        |> halt()
      
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Common function to handle media uploads across social media platforms.
  """
  def handle_media_upload(conn, provider, params) do
    with {:ok, _, api_module} <- validate_provider(provider),
         {:ok, tokens} <- get_tokens(conn, provider),
         {:ok, media_result} <- api_module.upload_media(tokens, params) do
      {:ok, media_result}
    else
      {:error, :not_authenticated} ->
        conn
        |> put_flash(:error, "You need to connect your #{provider} account first")
        |> redirect(to: ~p"/social/#{provider}")
        |> halt()
      
      {:error, reason} -> {:error, reason}
    end
  end

  # Private functions

  defp store_tokens(conn, provider, tokens) do
    # This implementation can be adapted based on whether you're using
    # sessions or database storage for tokens
    conn = put_session(conn, "#{provider}_tokens", tokens)
    {:ok, conn}
  end

  defp get_tokens(conn, provider) do
    case get_session(conn, "#{provider}_tokens") do
      nil -> {:error, :not_authenticated}
      tokens -> {:ok, tokens}
    end
  end
end

