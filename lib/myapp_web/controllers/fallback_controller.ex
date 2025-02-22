defmodule MyappWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.
  """
  use MyappWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: MyappWeb.ErrorJSON)
    |> render(:error, changeset: changeset)
  end

  # This clause is an example of how to handle simple error messages.
  def call(conn, {:error, message}) when is_binary(message) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: message})
  end

  # This clause handles errors returned by our Thread API.
  def call(conn, {:error, %{"error" => _} = error}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(error)
  end

  # This clause is invoked for any other error formats.
  def call(conn, {:error, _}) do
    conn
    |> put_status(:internal_server_error)
    |> json(%{error: "Internal server error"})
  end
end
