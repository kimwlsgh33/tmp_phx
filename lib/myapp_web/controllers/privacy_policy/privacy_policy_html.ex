defmodule MyappWeb.PrivacyPolicyHTML do
  @moduledoc """
  This module contains pages rendered by PrivacyPolicyController.

  See the `privacy_policy_html` directory for all templates available.
  """
  use MyappWeb, :html

  embed_templates "privacy_policy_html/*"
end
