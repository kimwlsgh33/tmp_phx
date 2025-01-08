defmodule MyappWeb.AdminController do
  use MyappWeb, :controller

  def index(conn, _params) do
    conn
    |> put_layout(html: :admin)
    |> render(:admin)
  end
end
