defmodule MyappWeb.AccountController do
  use MyappWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
