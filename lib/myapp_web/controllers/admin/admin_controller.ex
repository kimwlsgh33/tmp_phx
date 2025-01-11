defmodule MyappWeb.AdminController do
  use MyappWeb, :controller

  def index(conn, _params) do
    items = ["Item 1", "Item 2", "Item 3"] # Add your items here
    render(conn, "admin.html", items: items)
  end
end
