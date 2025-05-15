defmodule MyappWeb.DashboardLive.Components.UploadTabs.PreviewsUtil do
  @doc """
  Helper function to parse hashtags in description
  """
  def highlight_hashtags(description) when is_binary(description) do
    String.replace(description, ~r/#(\w+)/, "<span class=\"text-blue-500 font-semibold\">#\\1</span>")
  end
  def highlight_hashtags(_), do: ""

  @doc """
  Helper function to generate a username for the platform
  """
  def generate_username(platform) do
    case platform do
      :tiktok -> "@tiktok_user_#{:rand.uniform(999)}"
      :youtube -> "YouTube Creator"
      :instagram -> "@instagram_user_#{:rand.uniform(999)}"
      :twitter -> "@x_user_#{:rand.uniform(999)}"
      :facebook -> "Facebook User"
      _ -> "@user_#{:rand.uniform(999)}"
    end
  end
end
