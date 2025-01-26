defmodule MyappWeb.PageController do
  use MyappWeb, :controller

  alias MyappWeb.PrivacyPolicy

  def home(conn, _params) do
    locale = get_locale(conn)
    
    privacy_policy = %{
      metadata: PrivacyPolicy.get_metadata(locale),
      sections: PrivacyPolicy.get_all_sections(locale)
    }

    render(conn, :home, privacy_policy: privacy_policy)
  end

  # Get the current locale from session or default to Korean
  defp get_locale(conn) do
    conn.private[:plug_session]["locale"] || "ko"
  end
end
