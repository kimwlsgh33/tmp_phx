defmodule MyappWeb.Landing.CompanyController do
  use MyappWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
