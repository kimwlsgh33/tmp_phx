defmodule Myapp.TokensBehaviour do
  @moduledoc """
  Behaviour module defining the interface for token operations.

  This module specifies the contract for token-related operations like
  creating, verifying, and revoking tokens. It allows for easy mocking in tests.
  """

  @doc """
  Creates a session token for a user.

  ## Parameters
    * `user` - The user for whom to create a token
    * `opts` - Optional parameters

  ## Returns
    * `{:ok, token, metadata}` - Successfully created token with metadata
    * `{:error, reason}` - Error with reason
  """
  @callback create_session_token(user :: struct(), opts :: keyword()) ::
    {:ok, String.t(), map()} |
    {:error, any()}

  @doc """
  Verifies a session token.

  ## Parameters
    * `token` - The token to verify
    * `opts` - Optional parameters

  ## Returns
    * `{:ok, user}` - Successfully verified token, returns the user
    * `{:error, reason}` - Error with reason
  """
  @callback verify_session_token(token :: String.t(), opts :: keyword()) ::
    {:ok, struct()} |
    {:error, any()}

  @doc """
  Verifies a session token (single parameter version).

  ## Parameters
    * `token` - The token to verify

  ## Returns
    * `{:ok, user}` - Successfully verified token, returns the user
    * `{:error, reason}` - Error with reason
  """
  @callback verify_session_token(token :: String.t()) ::
    {:ok, struct()} |
    {:error, any()}

  @doc """
  Revokes a session token.

  ## Parameters
    * `token` - The token to revoke
    * `opts` - Optional parameters

  ## Returns
    * `:ok` - Successfully revoked token
    * `{:error, reason}` - Error with reason
  """
  @callback revoke_session_token(token :: String.t(), opts :: keyword()) ::
    :ok |
    {:error, any()}
end
