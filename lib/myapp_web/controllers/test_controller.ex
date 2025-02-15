defmodule MyappWeb.TestController do
  use MyappWeb, :controller

  def page(conn, _params) do
    render(conn, :test)
  end
end
