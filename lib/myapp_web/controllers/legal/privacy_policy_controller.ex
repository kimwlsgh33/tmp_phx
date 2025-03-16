defmodule MyappWeb.Legal.PrivacyPolicyController do
  use MyappWeb, :controller

  def page(conn, %{"version" => version}) do
    case Myapp.PrivacyPolicy.get_privacy_policy(version) do
      {:ok, privacy_policy} ->
        render(conn, :page, privacy_policy: privacy_policy)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> render(:page, privacy_policy: "Privacy policy not found")

      {:error, :invalid_version} ->
        conn
        |> put_status(:bad_request)
        |> render(:page, privacy_policy: "Invalid privacy policy version")

      {:error, :invalid_json} ->
        conn
        |> put_status(:internal_server_error)
        |> render(:page, privacy_policy: "The privacy policy file contains invalid JSON")

      {:error, _} ->
        conn
        |> put_status(:internal_server_error)
        |> render(:page, privacy_policy: "An error occurred while loading the privacy policy")
    end
  end
end
