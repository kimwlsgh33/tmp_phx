defmodule MyappWeb.Legal.TermsOfServicesController do
  @moduledoc """
  Controller for handling terms of service pages.

  This controller provides endpoints for retrieving and displaying
  terms of service documents in different versions and languages.
  """

  use MyappWeb, :controller

  alias Myapp.ErrorHandler
  alias MyappWeb.ErrorHandler, as: WebErrorHandler

  @doc """
  Renders the terms of service page for the specified version.

  ## Parameters

    * `conn` - The connection
    * `%{"version" => version}` - The version of the terms of service to display
  """
  def page(conn, %{"version" => version}) do
    case Myapp.TermsOfServices.get_terms_of_services(version) do
      {:ok, terms_of_services} ->
        render(conn, :terms_of_services, terms_of_services: terms_of_services)

      {:error, %{type: :not_found} = error} ->
        # Use our standardized error handling for not found errors
        conn
        |> put_status(:not_found)
        |> render(:terms_of_services, terms_of_services: ErrorHandler.user_message(error))

      {:error, %{type: :bad_request} = error} ->
        # Use our standardized error handling for bad request errors
        conn
        |> put_status(:bad_request)
        |> render(:terms_of_services, terms_of_services: ErrorHandler.user_message(error))

      {:error, error} ->
        # Use our standardized web error handling for other errors
        WebErrorHandler.handle_error(conn, error)
    end
  end

  @doc """
  Fallback for when no version is specified. Redirects to the latest version.
  """
  def page(conn, _params) do
    # Get the latest version and redirect to it
    latest_version = List.last(Myapp.TermsOfServices.get_versions())
    redirect(conn, to: ~p"/legal/terms/#{latest_version}")
  end
end
