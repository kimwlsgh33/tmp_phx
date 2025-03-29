defmodule Myapp.Tokens.Common do
  @moduledoc """
  Common token functionality shared across all token systems.

  This module provides standardized functions for token operations:
  - Token generation
  - Encryption and decryption
  - Expiration management
  - Validation

  It serves as a central place for token-related utilities to ensure
  consistent patterns across the application.
  """

  @hash_algorithm :sha256
  @rand_size 32
  @default_token_lifetime 24 * 60 * 60 # 24 hours in seconds
  @default_refresh_token_lifetime 30 * 24 * 60 * 60 # 30 days in seconds

  @doc """
  Generates a secure random token of standard size.

  ## Examples

      iex> token = Myapp.Tokens.Common.generate_token()
      iex> byte_size(token)
      32
  """
  def generate_token do
    :crypto.strong_rand_bytes(@rand_size)
  end

  @doc """
  Generates a URL-safe token string.

  ## Examples

      iex> token = Myapp.Tokens.Common.generate_url_safe_token()
      iex> String.match?(token, ~r/^[A-Za-z0-9_-]+$/)
      true
  """
  def generate_url_safe_token do
    generate_token() |> Base.url_encode64(padding: false)
  end

  @doc """
  Creates a hash of the given token using SHA-256.

  ## Examples

      iex> token = :crypto.strong_rand_bytes(32)
      iex> hash = Myapp.Tokens.Common.hash_token(token)
      iex> byte_size(hash)
      32
  """
  def hash_token(token) do
    :crypto.hash(@hash_algorithm, token)
  end

  @doc """
  Encrypts a token using Phoenix.Token for secure storage.

  ## Parameters
    - `token` - The token to encrypt
    - `salt` - A string salt for the encryption
    - `endpoint` - The Phoenix endpoint (defaults to Myapp.Endpoint)

  ## Examples

      iex> encrypted = Myapp.Tokens.Common.encrypt_token("secret_token", "test_salt")
      iex> is_binary(encrypted)
      true
  """
  def encrypt_token(token, salt, endpoint \\ Myapp.Endpoint) do
    Phoenix.Token.sign(endpoint, salt, token)
    |> :erlang.term_to_binary()
  end

  @doc """
  Decrypts a token previously encrypted with `encrypt_token/3`.

  ## Parameters
    - `encrypted` - The encrypted token
    - `salt` - The same salt used for encryption
    - `max_age` - Maximum age in seconds (defaults to 30 days)
    - `endpoint` - The Phoenix endpoint (defaults to Myapp.Endpoint)

  ## Examples

      iex> encrypted = Myapp.Tokens.Common.encrypt_token("secret_token", "test_salt")
      iex> {:ok, "secret_token"} = Myapp.Tokens.Common.decrypt_token(encrypted, "test_salt")
  """
  def decrypt_token(encrypted, salt, max_age \\ @default_refresh_token_lifetime, endpoint \\ Myapp.Endpoint) do
    try do
      binary = :erlang.binary_to_term(encrypted)
      Phoenix.Token.verify(endpoint, salt, binary, max_age: max_age)
    rescue
      _ -> {:error, :invalid_token}
    end
  end

  @doc """
  Checks if a token is expired based on its expiration timestamp.

  ## Examples

      iex> expired_time = DateTime.add(DateTime.utc_now(), -3600, :second)
      iex> Myapp.Tokens.Common.expired?(expired_time)
      true

      iex> future_time = DateTime.add(DateTime.utc_now(), 3600, :second)
      iex> Myapp.Tokens.Common.expired?(future_time)
      false

      iex> Myapp.Tokens.Common.expired?(nil)
      false
  """
  def expired?(nil), do: false
  def expired?(expires_at) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :lt
  end

  @doc """
  Checks if a token needs to be refreshed, returning true if 
  it will expire within the given threshold.

  ## Parameters
    - `expires_at` - The expiration timestamp
    - `threshold_seconds` - Seconds before expiry to trigger refresh (default: 1 hour)

  ## Examples

      iex> almost_expired = DateTime.add(DateTime.utc_now(), 1800, :second) # 30 minutes
      iex> Myapp.Tokens.Common.needs_refresh?(almost_expired)
      true

      iex> future_time = DateTime.add(DateTime.utc_now(), 7200, :second) # 2 hours
      iex> Myapp.Tokens.Common.needs_refresh?(future_time)
      false
  """
  def needs_refresh?(expires_at, threshold_seconds \\ 3600)
  def needs_refresh?(nil, _), do: false
  def needs_refresh?(expires_at, threshold_seconds) do
    refresh_threshold = DateTime.add(DateTime.utc_now(), threshold_seconds, :second)
    DateTime.compare(expires_at, refresh_threshold) in [:lt, :eq]
  end

  @doc """
  Calculates an expiration timestamp based on a lifetime in seconds.

  ## Parameters
    - `lifetime_seconds` - How long the token should live (default: 24 hours)
    - `from` - The starting time (default: current time)

  ## Examples

      iex> expiry = Myapp.Tokens.Common.calculate_expiry(3600) # 1 hour
      iex> DateTime.diff(expiry, DateTime.utc_now()) >= 3590 # Allow small timing differences
      true
  """
  def calculate_expiry(lifetime_seconds \\ @default_token_lifetime, from \\ nil) do
    start_time = from || DateTime.utc_now()
    DateTime.add(start_time, lifetime_seconds, :second)
    |> DateTime.truncate(:second)
  end

  @doc """
  Extracts common token data from OAuth provider responses.
  Handles different formats and normalizes to a standard structure.

  ## Examples
      
      iex> response = %{
      ...>   "access_token" => "abc123",
      ...>   "refresh_token" => "xyz789",
      ...>   "expires_in" => 3600,
      ...>   "token_type" => "Bearer"
      ...> }
      iex> token_data = Myapp.Tokens.Common.normalize_oauth_response(response)
      iex> token_data.access_token
      "abc123"
      iex> token_data.refresh_token
      "xyz789"
      iex> token_data.expires_in
      3600
  """
  def normalize_oauth_response(response) do
    %{
      access_token: response["access_token"],
      refresh_token: response["refresh_token"],
      expires_in: response["expires_in"] || @default_token_lifetime,
      token_type: response["token_type"] || "Bearer",
      scope: response["scope"],
      provider_user_id: response["open_id"] || response["provider_user_id"] || response["user_id"],
      metadata: Map.drop(response, [
        "access_token", "refresh_token", "token_type",
        "scope", "expires_in", "refresh_expires_in",
        "open_id", "provider_user_id", "user_id"
      ])
    }
  end

  @doc false
  def default_token_lifetime, do: @default_token_lifetime

  @doc false
  def default_refresh_token_lifetime, do: @default_refresh_token_lifetime
end

