defmodule MyappWeb.Auth do
  @moduledoc """
  Authentication utilities for web requests.

  This module provides functions for verifying session tokens and
  handling authentication in LiveView and controllers.
  """

  alias Myapp.Tokens

  @doc """
  Verifies a session from the socket assigns.

  ## Parameters
    - session: The session map from the socket

  ## Returns
    - {:ok, user} if the session is valid
    - {:error, reason} if the session is invalid
  """
  def verify_session(session) do
    case session["user_token"] do
      nil ->
        {:error, :no_token}
      token ->
        Tokens.verify_session_token(token)
    end
  end
end
