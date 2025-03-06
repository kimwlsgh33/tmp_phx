defmodule Myapp.PrivacyPolicy do
  @versions ["v1", "v1_en", "v2", "v2_en"]

  def get_versions, do: @versions

  def get_privacy_policy(version) when version in @versions do
    priv_dir = Application.app_dir(:myapp, "priv")
    file_path = Path.join([priv_dir, "privacy_policy", "#{version}.json"])

    with {:ok, content} <- File.read(file_path),
         {:ok, privacy_policy} <- Jason.decode(content) do
      {:ok, privacy_policy}
    else
      {:error, :enoent} -> {:error, :not_found}
      {:error, %Jason.DecodeError{}} -> {:error, :invalid_json}
      :error -> {:error, :invalid_format}
      error -> {:error, error}
    end
  end

  def get_privacy_policy(_version), do: {:error, :invalid_version}
end
