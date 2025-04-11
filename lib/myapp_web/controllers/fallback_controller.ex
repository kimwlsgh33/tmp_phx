defmodule MyappWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  This controller is used as a fallback for actions that may return error tuples.
  It uses the standardized error handling system to convert errors into appropriate
  HTTP responses.
  """
  use MyappWeb, :controller

  alias Myapp.ErrorHandler
  alias MyappWeb.ErrorHandler, as: WebErrorHandler

  @doc """
  Handles various error formats and converts them to appropriate HTTP responses.

  ## Examples

      # In a controller action
      def show(conn, %{"id" => id}) do
        case Accounts.get_user(id) do
          {:ok, user} -> render(conn, :show, user: user)
          error -> error
        end
      end

      # The fallback controller will handle the error
      action_fallback MyappWeb.FallbackController
  """

  # This clause handles errors that are already in our standard format
  def call(conn, {:error, %{type: _type, message: _message} = error}) do
    WebErrorHandler.handle_error(conn, error)
  end

  # This clause handles errors returned by Ecto's insert/update/delete
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: MyappWeb.Error.ErrorJSON)
    |> render(:error, changeset: changeset)
  end

  # This clause handles string error messages
  def call(conn, {:error, message}) when is_binary(message) do
    error = ErrorHandler.error(:bad_request, message)
    WebErrorHandler.handle_error(conn, error)
  end

  # This clause handles errors returned by our Thread API
  def call(conn, {:error, %{"error" => _} = api_error}) do
    error = ErrorHandler.error(:api_error, "API Error", api_error)
    WebErrorHandler.handle_error(conn, error)
  end

  # This clause handles atom error reasons
  def call(conn, {:error, reason}) when is_atom(reason) do
    error = ErrorHandler.normalize({:error, reason})
    WebErrorHandler.handle_error(conn, error)
  end

  # This clause is invoked for any other error formats
  def call(conn, {:error, reason}) do
    error = ErrorHandler.error(:internal_error, "Internal server error", %{reason: reason})
    WebErrorHandler.handle_error(conn, error)
  end

  # Handle non-error responses that somehow got to the fallback
  def call(conn, response) do
    error = ErrorHandler.error(
      :internal_error,
      "Unexpected response in fallback controller",
      %{response: response}
    )

    WebErrorHandler.handle_error(conn, error)
  end
end
