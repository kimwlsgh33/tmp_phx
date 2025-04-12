defmodule Myapp.Tokens.API do
  @moduledoc """
  Defines the public interface for the token management system.
  
  This module specifies the contract that all token implementations must follow,
  ensuring consistent behavior across different token types and storage mechanisms.
  
  ## Token Types
  
  The system handles several types of tokens:
  
  - **Session tokens**: Used for user authentication sessions
  - **Email tokens**: Used for email verification, password reset, etc.
  - **Social media tokens**: Used for OAuth authentication with external platforms
  
  ## Storage Mechanisms
  
  Tokens can be stored in different backends:
  
  - **Database**: For persistent storage (default)
  - **Cache**: For high-performance, short-lived storage
  - **Hybrid**: Combining database and cache for optimal performance
  
  ## Usage
  
  This module is not meant to be used directly. Instead, use the `Myapp.Tokens` 
  module which implements this interface.
  """
  
  @doc """
  Creates a session token for a user.
  
  ## Parameters
  
  - `user`: The user for whom to create the token
  - `opts`: Optional parameters for token creation
  
  ## Returns
  
  - `{:ok, token, metadata}`: If the token was created successfully
  - `{:error, reason}`: If there was an error creating the token
  """
  @callback create_session_token(user :: struct(), opts :: keyword()) ::
              {:ok, binary(), map()} | {:error, term()}
  
  @doc """
  Verifies a session token and returns the associated user.
  
  ## Parameters
  
  - `token`: The token to verify
  - `opts`: Optional parameters for token verification
  
  ## Returns
  
  - `{:ok, user}`: If the token is valid
  - `{:error, reason}`: If the token is invalid
  """
  @callback verify_session_token(token :: binary(), opts :: keyword()) ::
              {:ok, struct()} | {:error, term()}
  
  @doc """
  Revokes a session token.
  
  ## Parameters
  
  - `token`: The token to revoke
  - `opts`: Optional parameters for token revocation
  
  ## Returns
  
  - `:ok`: If the token was revoked successfully
  - `{:error, reason}`: If there was an error revoking the token
  """
  @callback revoke_session_token(token :: binary(), opts :: keyword()) ::
              :ok | {:error, term()}
  
  @doc """
  Revokes all session tokens for a user except the given token.
  
  ## Parameters
  
  - `user`: The user whose tokens should be revoked
  - `current_token`: The token to keep
  - `opts`: Optional parameters for token revocation
  
  ## Returns
  
  - `:ok`: If the tokens were revoked successfully
  - `{:error, reason}`: If there was an error revoking the tokens
  """
  @callback revoke_other_session_tokens(user :: struct(), current_token :: binary(), opts :: keyword()) ::
              :ok | {:error, term()}
  
  @doc """
  Creates an email token for the given user and context.
  
  ## Parameters
  
  - `user`: The user for whom to create the token
  - `context`: The context for the token (e.g., "confirm", "reset_password")
  - `opts`: Optional parameters for token creation
  
  ## Returns
  
  - `{:ok, token}`: If the token was created successfully
  - `{:error, reason}`: If there was an error creating the token
  """
  @callback create_email_token(user :: struct(), context :: binary(), opts :: keyword()) ::
              {:ok, binary()} | {:error, term()}
  
  @doc """
  Verifies an email token for the given context.
  
  ## Parameters
  
  - `token`: The token to verify
  - `context`: The context for the token (e.g., "confirm", "reset_password")
  - `opts`: Optional parameters for token verification
  
  ## Returns
  
  - `{:ok, user}`: If the token is valid
  - `{:error, reason}`: If the token is invalid
  """
  @callback verify_email_token(token :: binary(), context :: binary(), opts :: keyword()) ::
              {:ok, struct()} | {:error, term()}
  
  @doc """
  Stores social media tokens for a user and platform.
  
  ## Parameters
  
  - `user_id`: The ID of the user
  - `provider`: The social media platform (e.g., :twitter, :facebook)
  - `token_data`: The token data to store
  - `opts`: Optional parameters for token storage
  
  ## Returns
  
  - `{:ok, token_data}`: If the tokens were stored successfully
  - `{:error, reason}`: If there was an error storing the tokens
  """
  @callback store_social_token(user_id :: integer(), provider :: atom(), token_data :: map(), opts :: keyword()) ::
              {:ok, map()} | {:error, term()}
  
  @doc """
  Gets social media tokens for a user and platform.
  
  ## Parameters
  
  - `user_id`: The ID of the user
  - `provider`: The social media platform (e.g., :twitter, :facebook)
  - `opts`: Optional parameters for token retrieval
  
  ## Returns
  
  - `{:ok, token_data}`: If the tokens were found
  - `{:error, reason}`: If the tokens were not found or there was an error
  """
  @callback get_social_token(user_id :: integer(), provider :: atom(), opts :: keyword()) ::
              {:ok, map()} | {:error, term()}
  
  @doc """
  Refreshes social media tokens for a user and platform.
  
  ## Parameters
  
  - `user_id`: The ID of the user
  - `provider`: The social media platform (e.g., :twitter, :facebook)
  - `opts`: Optional parameters for token refresh
  
  ## Returns
  
  - `{:ok, new_token_data}`: If the tokens were refreshed successfully
  - `{:error, reason}`: If there was an error refreshing the tokens
  """
  @callback refresh_social_token(user_id :: integer(), provider :: atom(), opts :: keyword()) ::
              {:ok, map()} | {:error, term()}
  
  @doc """
  Revokes social media tokens for a user and platform.
  
  ## Parameters
  
  - `user_id`: The ID of the user
  - `provider`: The social media platform (e.g., :twitter, :facebook)
  - `opts`: Optional parameters for token revocation
  
  ## Returns
  
  - `:ok`: If the tokens were revoked successfully
  - `{:error, reason}`: If there was an error revoking the tokens
  """
  @callback revoke_social_token(user_id :: integer(), provider :: atom(), opts :: keyword()) ::
              :ok | {:error, term()}
end
