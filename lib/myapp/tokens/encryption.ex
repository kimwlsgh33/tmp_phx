defmodule Myapp.Tokens.Encryption do
  @moduledoc """
  Provides encryption and decryption functionality for tokens.
  
  This module standardizes the encryption approach across all token types,
  ensuring consistent security practices.
  """
  
  @hash_algorithm :sha256
  @encryption_salt "token_encryption_salt"
  
  @doc """
  Encrypts a token using a standardized approach.
  
  ## Examples
  
      iex> encrypted = Myapp.Tokens.Encryption.encrypt("my_token")
      iex> is_binary(encrypted)
      true
  """
  def encrypt(token, salt \\ @encryption_salt) do
    Phoenix.Token.sign(Myapp.Endpoint, salt, token)
  end
  
  @doc """
  Decrypts a token that was encrypted with `encrypt/2`.
  
  ## Examples
  
      iex> token = "my_token"
      iex> encrypted = Myapp.Tokens.Encryption.encrypt(token)
      iex> {:ok, ^token} = Myapp.Tokens.Encryption.decrypt(encrypted)
      {:ok, "my_token"}
  """
  def decrypt(encrypted_token, salt \\ @encryption_salt, max_age \\ 86400) do
    Phoenix.Token.verify(Myapp.Endpoint, salt, encrypted_token, max_age: max_age)
  end
  
  @doc """
  Hashes a token using SHA-256.
  
  ## Examples
  
      iex> hashed = Myapp.Tokens.Encryption.hash("my_token")
      iex> byte_size(hashed)
      32
  """
  def hash(token) do
    :crypto.hash(@hash_algorithm, token)
  end
  
  @doc """
  Generates a secure random token.
  
  ## Examples
  
      iex> token = Myapp.Tokens.Encryption.generate_token()
      iex> byte_size(token)
      32
  """
  def generate_token(size \\ 32) do
    :crypto.strong_rand_bytes(size)
  end
  
  @doc """
  Generates a secure random token and encodes it as URL-safe base64.
  
  ## Examples
  
      iex> token = Myapp.Tokens.Encryption.generate_url_token()
      iex> String.match?(token, ~r/^[A-Za-z0-9_-]+$/)
      true
  """
  def generate_url_token(size \\ 32) do
    generate_token(size)
    |> Base.url_encode64(padding: false)
  end
end
