defmodule MyappWeb.PrivacyPolicyHTML do
  use MyappWeb, :html

  embed_templates "privacy_policy_html/*"

  @doc """
  Renders the privacy policy page.
  """
  attr :policy, :map, required: true

  def page(assigns)
end
