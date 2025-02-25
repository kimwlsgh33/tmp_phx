defmodule MyappWeb.DocsController do
  use MyappWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
  
  def show(conn, %{"topic" => topic}) do
    render(conn, :show, topic: topic)
  end
end