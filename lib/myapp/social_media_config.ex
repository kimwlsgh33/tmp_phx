defmodule Myapp.SocialMediaConfig do
  @moduledoc """
  Centralized configuration management for social media integrations.
  
  This module provides a standardized interface for retrieving and validating
  social media platform configurations and credentials.
  """

  @doc """
  Returns the configuration for a specific provider.
  
  ## Examples
      
      iex> SocialMediaConfig.get_provider_config(:twitter)
      %{
        auth_module: Myapp.SocialAuth.Twitter,
        api_module: Myapp.SocialMedia.Twitter,
        api_key: "your_api_key",
        api_secret: "your_api_secret",
        redirect_uri: "your_redirect_uri"
      }
  """
  def get_provider_config(provider) when provider in [:twitter, :tiktok, :instagram, :youtube, :thread] do
    Application.get_env(:myapp, :social_media)[provider] ||
      raise "Configuration for provider #{provider} not found"
  end

  @doc """
  Returns credentials for a specific provider.
  
  ## Examples
      
      iex> SocialMediaConfig.get_credentials(:twitter)
      %{
        api_key: "your_api_key",
        api_secret: "your_api_secret",
        redirect_uri: "your_redirect_uri"
      }
  """
  def get_credentials(provider) do
    config = get_provider_config(provider)
    
    %{
      api_key: config[:api_key],
      api_secret: config[:api_secret],
      redirect_uri: config[:redirect_uri]
    }
  end

  @doc """
  Returns the auth module for a specific provider.
  
  ## Examples
      
      iex> SocialMediaConfig.get_auth_module(:twitter)
      Myapp.SocialAuth.Twitter
  """
  def get_auth_module(provider) do
    get_provider_config(provider)[:auth_module]
  end

  @doc """
  Returns the API module for a specific provider.
  
  ## Examples
      
      iex> SocialMediaConfig.get_api_module(:twitter)
      Myapp.SocialMedia.Twitter
  """
  def get_api_module(provider) do
    get_provider_config(provider)[:api_module]
  end

  @doc """
  Validates the configuration for a specific provider.
  Returns :ok if the configuration is valid, or {:error, reason} if invalid.
  
  ## Examples
      
      iex> SocialMediaConfig.validate_config(:twitter)
      :ok
      
      iex> SocialMediaConfig.validate_config(:unknown_provider)
      {:error, "Provider :unknown_provider is not supported"}
  """
  def validate_config(provider) do
    try do
      config = get_provider_config(provider)
      
      # Check required keys
      required_keys = [:auth_module, :api_module, :api_key, :api_secret, :redirect_uri]
      missing_keys = Enum.filter(required_keys, fn key -> is_nil(config[key]) end)
      
      if Enum.empty?(missing_keys) do
        :ok
      else
        {:error, "Missing required configuration keys: #{inspect(missing_keys)}"}
      end
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  @doc """
  Validates the configuration for all providers.
  Returns a map with the validation result for each provider.
  
  ## Examples
      
      iex> SocialMediaConfig.validate_all_configs()
      %{
        twitter: :ok,
        tiktok: :ok,
        instagram: {:error, "Missing required configuration keys: [:api_secret]"}
      }
  """
  def validate_all_configs do
    [:twitter, :tiktok, :instagram, :youtube, :thread]
    |> Enum.map(fn provider -> {provider, validate_config(provider)} end)
    |> Enum.into(%{})
  end

  @doc """
  Lists all configured providers.
  
  ## Examples
      
      iex> SocialMediaConfig.list_providers()
      [:twitter, :tiktok, :instagram, :youtube, :thread]
  """
  def list_providers do
    (Application.get_env(:myapp, :social_media) || %{})
    |> Map.keys()
  end

  @doc """
  Checks if a provider is configured and available.
  
  ## Examples
      
      iex> SocialMediaConfig.provider_available?(:twitter)
      true
      
      iex> SocialMediaConfig.provider_available?(:unknown_provider)
      false
  """
  def provider_available?(provider) do
    case validate_config(provider) do
      :ok -> true
      _ -> false
    end
  end
  @doc """
  Returns both auth and API modules for a specific provider.
  
  This function handles both string and atom inputs for the provider name.
  
  ## Examples
      
      iex> SocialMediaConfig.get_provider_modules(:twitter)
      {:ok, %{auth_module: Myapp.SocialAuth.Twitter, api_module: Myapp.SocialMedia.Twitter}}
      
      iex> SocialMediaConfig.get_provider_modules("instagram")
      {:ok, %{auth_module: Myapp.SocialAuth.Instagram, api_module: Myapp.SocialMedia.Instagram}}
      
      iex> SocialMediaConfig.get_provider_modules(:unknown)
      {:error, "Provider :unknown is not supported"}
  """
  def get_provider_modules(provider) when is_binary(provider) do
    # Convert string to atom for internal functions
    provider_atom = String.to_existing_atom(provider)
    get_provider_modules(provider_atom)
  rescue
    # Handle case where string cannot be converted to an existing atom
    ArgumentError -> {:error, "Provider #{provider} is not supported"}
  end

  def get_provider_modules(provider) when is_atom(provider) do
    try do
      auth_module = get_auth_module(provider)
      api_module = get_api_module(provider)

      {:ok, %{auth_module: auth_module, api_module: api_module}}
    rescue
      # Handle case where provider is not configured
      e -> {:error, Exception.message(e)}
    end
  end
end

