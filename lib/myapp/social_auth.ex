defmodule Myapp.SocialAuth do
  @moduledoc """
  Behaviour module that defines a standard interface for OAuth authentication
  across different social media platforms.

  This module provides a consistent API for:
  - Generating authorization URLs
  - Exchanging authorization codes for access tokens
  - Refreshing access tokens
  - Validating tokens
  - Managing token storage
  """

  @type auth_params :: map()
  @type token_response :: {:ok, map()} | {:error, any()}
  @type auth_url_response :: {:ok, String.t()} | {:error, any()}
  @type validation_response :: {:ok, boolean()} | {:error, any()}
  @type provider :: atom()

  @doc """
  Generates an authorization URL for the OAuth flow.
  """
  @callback generate_auth_url(params :: auth_params()) :: auth_url_response()

  @doc """
  Exchanges an authorization code for an access token.
  """
  @callback exchange_code_for_token(code :: String.t(), params :: auth_params()) :: token_response()

  @doc """
  Refreshes an expired access token using a refresh token.
  """
  @callback refresh_token(refresh_token :: String.t(), params :: auth_params()) :: token_response()

  @doc """
  Validates if a token is still valid and not expired.
  """
  @callback validate_token(access_token :: String.t(), params :: auth_params()) :: validation_response()

  @doc """
  Stores authentication tokens securely.
  """
  @callback store_tokens(user_id :: any(), tokens :: map(), params :: auth_params()) :: :ok | {:error, any()}

  @doc """
  Retrieves stored authentication tokens for a user.
  """
  @callback get_tokens(user_id :: any(), params :: auth_params()) :: {:ok, map()} | {:error, any()}

  @doc """
  Revokes authentication tokens, typically used during logout or disconnection.
  """
  @callback revoke_tokens(access_token :: String.t(), params :: auth_params()) :: :ok | {:error, any()}

  @doc """
  Returns the provider-specific configuration.
  """
  @callback get_provider_config() :: map()

  @doc """
  Returns the name of the provider as an atom (e.g., :twitter, :tiktok).
  """
  @callback get_provider_name() :: provider()

  @doc """
  Helper function to get a provider module by name
  """
  @spec get_provider(provider()) :: module() | nil
  def get_provider(provider) do
    case provider do
      :twitter -> Myapp.SocialAuth.Twitter
      :tiktok -> Myapp.SocialAuth.TikTok
      :instagram -> Myapp.SocialAuth.Instagram
      :youtube -> Myapp.SocialAuth.YouTube
      _ -> nil
    end
  end

  @doc """
  Helper function to ensure a provider exists
  """
  @spec provider_exists?(provider()) :: boolean()
  def provider_exists?(provider) do
    get_provider(provider) != nil
  end

  @doc """
  Helper function to list all available providers
  """
  @spec list_providers() :: [provider()]
  def list_providers() do
    [:twitter, :tiktok, :instagram, :youtube]
  end
end

