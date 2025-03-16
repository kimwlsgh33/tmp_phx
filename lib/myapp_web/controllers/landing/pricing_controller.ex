defmodule MyappWeb.Landing.PricingController do
  use MyappWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
