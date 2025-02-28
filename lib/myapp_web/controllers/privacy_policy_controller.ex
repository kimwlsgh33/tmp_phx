defmodule MyappWeb.PrivacyPolicyController do
  use MyappWeb, :controller

  def page(conn, %{"version" => version}) do
    # A simple Privacy Policy controller
    render(conn, :page, version: version)
  end
end
