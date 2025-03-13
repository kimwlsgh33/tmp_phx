defmodule MyappWeb.TestController do
  use MyappWeb, :controller

  def dashboard(conn, _params) do
    # Example data to pass to the template
    render(conn, :test, page_title: "Test Page", message: "Hello from controller!")
  end
end
