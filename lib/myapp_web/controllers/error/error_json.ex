defmodule MyappWeb.Error.ErrorJSON do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on JSON requests.

  It handles both standard Phoenix error templates and our custom error format.
  """

  @doc """
  Renders a standardized error response.

  ## Parameters

  - `"error.json"`: The template name
  - `%{error: error}`: The assigns map containing the error

  ## Examples

      iex> error = Myapp.ErrorHandler.error(:not_found, "User not found")
      iex> MyappWeb.Error.ErrorJSON.render("error.json", %{error: error})
      %{error: %{message: "User not found", type: :not_found}}
  """
  def render("error.json", %{error: %{type: type, message: message} = error}) do
    response = %{
      error: %{
        type: type,
        message: message
      }
    }

    # Add details in non-production environments
    if Application.get_env(:myapp, :env) != :prod and Map.has_key?(error, :details) do
      put_in(response, [:error, :details], error.details)
    else
      response
    end
  end

  @doc """
  Renders a changeset error response.

  ## Parameters

  - `"error.json"`: The template name
  - `%{changeset: changeset}`: The assigns map containing the changeset

  ## Examples

      iex> changeset = Ecto.Changeset.add_error(%Ecto.Changeset{}, :email, "is invalid")
      iex> MyappWeb.Error.ErrorJSON.render("error.json", %{changeset: changeset})
      %{errors: %{email: ["is invalid"]}}
  """
  def render("error.json", %{changeset: changeset}) do
    # Convert changeset errors to a map
    errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)

    %{errors: errors}
  end

  # Handle standard Phoenix error templates
  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
