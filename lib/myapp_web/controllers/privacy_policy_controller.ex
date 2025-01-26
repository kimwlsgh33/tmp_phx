defmodule MyappWeb.PrivacyPolicyController do
  use MyappWeb, :controller

  alias Myapp.PrivacyPolicy

  def page(conn, _params) do
    locale = get_locale(conn)
    
    with {:ok, policy} <- PrivacyPolicy.get_policy(locale),
         {:ok, metadata} <- PrivacyPolicy.get_metadata(locale) do
      render(conn, :page, policy: policy, metadata: metadata)
    else
      {:error, _reason} ->
        conn
        |> put_flash(:error, gettext("Failed to load privacy policy"))
        |> redirect(to: ~p"/")
    end
  end

  def index(conn, _params) do
    locale = get_locale(conn)
    
    with {:ok, policy} <- PrivacyPolicy.get_policy(locale),
         {:ok, metadata} <- PrivacyPolicy.get_metadata(locale) do
      json(conn, %{
        metadata: metadata,
        policy: policy
      })
    else
      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: gettext("Failed to load privacy policy")})
    end
  end

  def show(conn, %{"section" => section_id}) do
    locale = get_locale(conn)
    
    case PrivacyPolicy.get_section(section_id, locale) do
      {:ok, section} ->
        json(conn, section)
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: gettext("Section not found")})
      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: gettext("Failed to load privacy policy section")})
    end
  end

  # Get the current locale from session or default to Korean
  defp get_locale(conn) do
    conn.private[:plug_session]["locale"] || "ko"
  end
end
