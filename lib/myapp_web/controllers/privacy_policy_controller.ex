defmodule MyappWeb.PrivacyPolicyController do
  use MyappWeb, :controller

  alias Myapp.PrivacyPolicy

  def page(conn, _params) do
    case PrivacyPolicy.get_policy() do
      {:ok, policy} ->
        render(conn, :page, policy: policy)
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to load privacy policy")
        |> redirect(to: ~p"/")
    end
  end

  def index(conn, _params) do
    case PrivacyPolicy.get_policy() do
      {:ok, policy} ->
        json(conn, policy)
      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to load privacy policy"})
    end
  end

  def show(conn, %{"section" => section_number}) do
    case PrivacyPolicy.get_section(section_number) do
      {:ok, section} ->
        json(conn, section)
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Section not found"})
      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to load privacy policy section"})
    end
  end
end
