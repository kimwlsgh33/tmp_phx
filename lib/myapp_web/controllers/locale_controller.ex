defmodule MyappWeb.LocaleController do
  use MyappWeb, :controller

  @doc """
  Sets the locale for the current session and redirects back to the previous page.
  """
  def set(conn, %{"locale" => locale}) when locale in ["en", "ko"] do
    conn
    |> put_session(:locale, locale)
    |> redirect(to: ~p"/")
  end

  def set(conn, _) do
    conn
    |> put_flash(:error, "Invalid locale")
    |> redirect(to: ~p"/")
  end
end
