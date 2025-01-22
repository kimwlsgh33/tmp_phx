defmodule Myapp.PrivacyPolicy do
  @privacy_policy_path "priv/privacy_policy/v1.json"

  @doc """
  Gets the privacy policy content.
  Returns {:ok, policy} on success, {:error, reason} on failure
  """
  def get_policy do
    case File.read(Application.app_dir(:myapp, @privacy_policy_path)) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, policy} -> {:ok, policy}
          {:error, _} = error -> error
        end

      {:error, _} = error -> error
    end
  end

  @doc """
  Gets a specific section of the privacy policy by section number.
  Returns {:ok, section} if found, {:error, :not_found} if not found
  """
  def get_section(section_number) do
    with {:ok, policy} <- get_policy(),
         section when not is_nil(section) <- find_section(policy["Terms"], section_number) do
      {:ok, section}
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  defp find_section(terms, section_number) do
    Enum.find(terms, fn section ->
      section["SectionNumber"] == section_number
    end)
  end
end
