defmodule MyappWeb.LandingController do
  use MyappWeb, :controller

  def index(conn, _params) do
    render(conn, :index, layout: false)
  end
end
