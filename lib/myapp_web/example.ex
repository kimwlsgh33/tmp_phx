defmodule MyappWeb.Example do
  @moduledoc """
  This module is used to test the localization of the application.
  """

  # Use Gettext with correct backend syntax
  use Gettext, backend: MyappWeb.Gettext

  def get_privacy_policy(_locale \\ nil) do
    # This is a placeholder function for now
    %{version: "1.0", content: "This is a privacy policy"}
  end
end
