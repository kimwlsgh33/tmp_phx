defmodule MyappWeb.PrivacyPolicyController do
  use MyappWeb, :controller

  def index(conn, _params) do
    localized_policy = MyappWeb.PrivacyPolicyLocalizer.localize_privacy_policy()
    render(conn, :index, localized_policy)
  end
end
