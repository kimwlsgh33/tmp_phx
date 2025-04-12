defmodule Myapp.ErrorHandler do
  @moduledoc """
  Alias module for Myapp.Shared.ErrorHandler.

  This module exists to provide backward compatibility with code that references
  Myapp.ErrorHandler instead of Myapp.Shared.ErrorHandler.
  """

  # Delegate all functions to Myapp.Shared.ErrorHandler
  defdelegate error(type, message, details \\ %{}, source \\ nil), to: Myapp.Shared.ErrorHandler
  defdelegate normalize(value), to: Myapp.Shared.ErrorHandler
  defdelegate handle(error, source, context \\ %{}), to: Myapp.Shared.ErrorHandler
  defdelegate user_message(error), to: Myapp.Shared.ErrorHandler

  # Private function in Shared.ErrorHandler, so we need to implement it here
  def normalize_reason(reason) do
    # Call normalize and extract the error from the result
    case normalize({:error, reason}) do
      {:error, error} -> error
      other -> other
    end
  end
end
