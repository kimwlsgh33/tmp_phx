defmodule Myapp.Tokens.Storage.Adapter do
  @moduledoc """
  Defines the interface for token storage adapters.
  
  This module specifies the contract that all token storage implementations must follow,
  allowing the token system to work with different storage backends.
  
  ## Storage Backends
  
  The system supports different storage backends:
  
  - **Database**: For persistent storage
  - **Cache**: For high-performance, short-lived storage
  - **Hybrid**: Combining database and cache for optimal performance
  
  ## Implementing an Adapter
  
  To create a new storage adapter, implement this behaviour and provide
  implementations for all the required callbacks.
  
  Example:
  
  ```elixir
  defmodule Myapp.Tokens.Storage.MyAdapter do
    @behaviour Myapp.Tokens.Storage.Adapter
    
    # Implement all the required callbacks
  end
  ```
  """
  
  @doc """
  Stores a session token.
  
  ## Parameters
  
  - `token`: The token to store
  - `user_id`: The ID of the user associated with the token
  - `metadata`: Additional metadata about the token
  
  ## Returns
  
  - `{:ok, stored_token}`: If the token was stored successfully
  - `{:error, reason}`: If there was an error storing the token
  """
  @callback store_session_token(token :: binary(), user_id :: integer(), metadata :: map()) ::
              {:ok, term()} | {:error, term()}
  
  @doc """
  Retrieves a session token.
  
  ## Parameters
  
  - `token`: The token to retrieve
  
  ## Returns
  
  - `{:ok, user_id}`: If the token was found
  - `{:error, reason}`: If the token was not found or there was an error
  """
  @callback get_session_token(token :: binary()) ::
              {:ok, integer()} | {:error, term()}
  
  @doc """
  Deletes a session token.
  
  ## Parameters
  
  - `token`: The token to delete
  
  ## Returns
  
  - `:ok`: If the token was deleted successfully
  - `{:error, reason}`: If there was an error deleting the token
  """
  @callback delete_session_token(token :: binary()) ::
              :ok | {:error, term()}
  
  @doc """
  Deletes all session tokens for a user except the given token.
  
  ## Parameters
  
  - `user_id`: The ID of the user
  - `except_token`: The token to keep
  
  ## Returns
  
  - `:ok`: If the tokens were deleted successfully
  - `{:error, reason}`: If there was an error deleting the tokens
  """
  @callback delete_user_session_tokens(user_id :: integer(), except_token :: binary()) ::
              :ok | {:error, term()}
  
  @doc """
  Stores an email token.
  
  ## Parameters
  
  - `token`: The token to store
  - `user_id`: The ID of the user associated with the token
  - `context`: The context for the token (e.g., "confirm", "reset_password")
  - `metadata`: Additional metadata about the token
  
  ## Returns
  
  - `{:ok, stored_token}`: If the token was stored successfully
  - `{:error, reason}`: If there was an error storing the token
  """
  @callback store_email_token(token :: binary(), user_id :: integer(), context :: binary(), metadata :: map()) ::
              {:ok, term()} | {:error, term()}
  
  @doc """
  Retrieves an email token.
  
  ## Parameters
  
  - `token`: The token to retrieve
  - `context`: The context for the token
  
  ## Returns
  
  - `{:ok, user_id}`: If the token was found
  - `{:error, reason}`: If the token was not found or there was an error
  """
  @callback get_email_token(token :: binary(), context :: binary()) ::
              {:ok, integer()} | {:error, term()}
  
  @doc """
  Stores social media tokens.
  
  ## Parameters
  
  - `user_id`: The ID of the user
  - `provider`: The social media platform (e.g., :twitter, :facebook)
  - `token_data`: The token data to store
  
  ## Returns
  
  - `{:ok, stored_token}`: If the tokens were stored successfully
  - `{:error, reason}`: If there was an error storing the tokens
  """
  @callback store_social_token(user_id :: integer(), provider :: atom(), token_data :: map()) ::
              {:ok, term()} | {:error, term()}
  
  @doc """
  Retrieves social media tokens.
  
  ## Parameters
  
  - `user_id`: The ID of the user
  - `provider`: The social media platform
  
  ## Returns
  
  - `{:ok, token_data}`: If the tokens were found
  - `{:error, reason}`: If the tokens were not found or there was an error
  """
  @callback get_social_token(user_id :: integer(), provider :: atom()) ::
              {:ok, map()} | {:error, term()}
  
  @doc """
  Updates social media tokens.
  
  ## Parameters
  
  - `user_id`: The ID of the user
  - `provider`: The social media platform
  - `token_data`: The new token data
  
  ## Returns
  
  - `{:ok, updated_token}`: If the tokens were updated successfully
  - `{:error, reason}`: If there was an error updating the tokens
  """
  @callback update_social_token(user_id :: integer(), provider :: atom(), token_data :: map()) ::
              {:ok, term()} | {:error, term()}
  
  @doc """
  Deletes social media tokens.
  
  ## Parameters
  
  - `user_id`: The ID of the user
  - `provider`: The social media platform
  
  ## Returns
  
  - `:ok`: If the tokens were deleted successfully
  - `{:error, reason}`: If there was an error deleting the tokens
  """
  @callback delete_social_token(user_id :: integer(), provider :: atom()) ::
              :ok | {:error, term()}
end
