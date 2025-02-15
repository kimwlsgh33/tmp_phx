defmodule MyappWeb.TermsOfServicesController do
  use MyappWeb, :controller

  def page(conn, %{"version" => version}) do
    case Myapp.TermsOfServices.get_terms_of_services(version) do
      {:ok, terms_of_services} ->
        render(conn, :terms_of_services, terms_of_services: terms_of_services)
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> render(:terms_of_services, terms_of_services: "Terms of services not found")
      {:error, :invalid_version} ->
        conn
        |> put_status(:bad_request)
        |> render(:terms_of_services, terms_of_services: "Invalid terms of services version")
      {:error, _} ->
        conn
        |> put_status(:internal_server_error)
        |> render(:terms_of_services, terms_of_services: "An error occurred while loading the terms of services")
    end
  end
end
