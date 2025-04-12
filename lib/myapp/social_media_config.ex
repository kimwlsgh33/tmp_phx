defmodule Myapp.SocialMediaConfig do
  @moduledoc """
  Configuration for social media providers.

  This module provides configuration and utility functions for social media providers.
  """

  alias Myapp.SocialMedia.{
    Instagram,
    Twitter,
    Youtube,
    Tiktok
  }

  @doc """
  Gets the module for a provider.

  ## Parameters
    * `provider` - The provider name as an atom or string

  ## Returns
    * `{:ok, module}` - If the provider is supported
    * `{:error, :unsupported_provider}` - If the provider is not supported
  """
  def get_provider_module(provider) when is_binary(provider) do
    provider
    |> String.to_existing_atom()
    |> get_provider_module()
  rescue
    ArgumentError -> {:error, :unsupported_provider}
  end

  def get_provider_module(provider) when is_atom(provider) do
    case provider do
      :instagram -> {:ok, Instagram}
      :twitter -> {:ok, Twitter}
      :youtube -> {:ok, Youtube}
      :tiktok -> {:ok, Tiktok}
      _ -> {:error, :unsupported_provider}
    end
  end

  @doc """
  Gets all modules for a provider.

  This includes the main module and any auxiliary modules.

  ## Parameters
    * `provider` - The provider name as an atom or string

  ## Returns
    * `{:ok, modules}` - If the provider is supported
    * `{:error, :unsupported_provider}` - If the provider is not supported
  """
  def get_provider_modules(provider) when is_binary(provider) do
    provider
    |> String.to_existing_atom()
    |> get_provider_modules()
  rescue
    ArgumentError -> {:error, :unsupported_provider}
  end

  def get_provider_modules(provider) when is_atom(provider) do
    case provider do
      :instagram ->
        {:ok, %{
          main: Instagram,
          auth: Myapp.SocialAuth.Instagram
        }}
      :twitter ->
        {:ok, %{
          main: Twitter,
          auth: Myapp.SocialAuth.Twitter
        }}
      :youtube ->
        {:ok, %{
          main: Youtube,
          auth: Myapp.SocialAuth.YouTube
        }}
      :tiktok ->
        {:ok, %{
          main: Tiktok,
          auth: Myapp.SocialAuth.TikTok
        }}
      _ ->
        {:error, :unsupported_provider}
    end
  end

  @doc """
  Gets the supported providers.

  ## Returns
    * `list` - A list of supported provider atoms
  """
  def supported_providers do
    [:instagram, :twitter, :youtube, :tiktok]
  end

  @doc """
  Checks if a provider is supported.

  ## Parameters
    * `provider` - The provider name as an atom or string

  ## Returns
    * `boolean` - True if the provider is supported, false otherwise
  """
  def supported_provider?(provider) when is_binary(provider) do
    provider
    |> String.to_existing_atom()
    |> supported_provider?()
  rescue
    ArgumentError -> false
  end

  def supported_provider?(provider) when is_atom(provider) do
    provider in supported_providers()
  end

  @doc """
  Gets the configuration for a provider.

  ## Parameters
    * `provider` - The provider name as an atom

  ## Returns
    * `{:ok, config}` - If the provider is supported
    * `{:error, :unsupported_provider}` - If the provider is not supported
  """
  def get_provider_config(provider) when is_atom(provider) do
    if supported_provider?(provider) do
      {:ok, Application.get_env(:myapp, provider, %{})}
    else
      {:error, :unsupported_provider}
    end
  end

  @doc """
  Gets a specific configuration value for a provider.

  ## Parameters
    * `provider` - The provider name as an atom or string
    * `key` - The configuration key to get
    * `default` - The default value to return if the key is not found

  ## Returns
    * `value` - The configuration value or the default
    * `{:error, :unsupported_provider}` - If the provider is not supported
  """
  def get(provider, key, default \\ nil)

  def get(provider, key, default) when is_atom(provider) and is_atom(key) do
    case get_provider_config(provider) do
      {:ok, config} -> Map.get(config, key, default)
      error -> error
    end
  end

  def get(provider, key, default) when is_binary(provider) and is_atom(key) do
    provider
    |> String.to_existing_atom()
    |> get(key, default)
  rescue
    ArgumentError -> {:error, :unsupported_provider}
  end
end
