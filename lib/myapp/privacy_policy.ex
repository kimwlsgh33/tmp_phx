defmodule Myapp.PrivacyPolicy do
  @moduledoc """
  Handles privacy policy data management and retrieval.
  """

  @privacy_policy_path_v1 "priv/privacy_policy/v1.json"
  @privacy_policy_path_v2 "priv/privacy_policy/v2.json"

  alias MyappWeb.PrivacyPolicy, as: PolicyPresenter

  @doc """
  Gets the privacy policy content with localization support.
  Returns {:ok, policy} on success, {:error, reason} on failure

  ## Parameters
    * locale - Optional locale to get the policy in. Defaults to current locale.
  """
  def get_policy(locale \\ nil) do
    with {:ok, content} <- File.read(Application.app_dir(:myapp, @privacy_policy_path_v2)),
         {:ok, policy} <- Jason.decode(content) do
      localized_policy = PolicyPresenter.get_all_sections(locale)
      {:ok, Map.put(policy, "localized_content", localized_policy)}
    else
      {:error, _} = error -> error
    end
  end

  @doc """
  Gets a specific section of the privacy policy by section number.
  Returns {:ok, section} if found, {:error, :not_found} if not found

  ## Parameters
    * section_id - The section ID to retrieve
    * locale - Optional locale to get the section in. Defaults to current locale.
  """
  def get_section(section_id, locale \\ nil) do
    case PolicyPresenter.get_section(section_id, locale) do
      nil -> {:error, :not_found}
      section -> {:ok, section}
    end
  end

  @doc """
  Gets the metadata for the privacy policy.
  Returns {:ok, metadata} on success, {:error, reason} on failure

  ## Parameters
    * locale - Optional locale to get the metadata in. Defaults to current locale.
  """
  def get_metadata(locale \\ nil) do
    {:ok, PolicyPresenter.get_metadata(locale)}
  end
end
