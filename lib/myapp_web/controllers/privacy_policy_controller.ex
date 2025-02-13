defmodule MyappWeb.PrivacyPolicyController do
  use MyappWeb, :controller

  def page(conn, %{"version" => version}) do
    case MyappWeb.PrivacyPolicy.get_privacy_policy(version) do
      {:ok, privacy_policy} ->
        render(conn, :privacy_policy, privacy_policy: privacy_policy)
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> render(:privacy_policy, privacy_policy: "Privacy policy not found")
      {:error, :invalid_version} ->
        conn
        |> put_status(:bad_request)
        |> render(:privacy_policy, privacy_policy: "Invalid privacy policy version")
      {:error, _} ->
        conn
        |> put_status(:internal_server_error)
        |> render(:privacy_policy, privacy_policy: "An error occurred while loading the privacy policy")
    end
  end
end
