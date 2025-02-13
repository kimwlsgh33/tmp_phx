defmodule MyappWeb.PrivacyPolicy do
  @versions ["v1"]

  def get_versions, do: @versions

  def get_privacy_policy(version) when version in @versions do
    priv_dir = Application.app_dir(:myapp, "priv")
    file_path = Path.join([priv_dir, "privacy_policy", "#{version}.json"])

    with {:ok, content} <- File.read(file_path),
         {:ok, policy} <- Jason.decode(content) do
      # {:ok, policy} <- Map.fetch(json, "document") do
      {:ok, policy}
    else
      {:error, :enoent} -> {:error, :not_found}
      {:error, %Jason.DecodeError{}} -> {:error, :invalid_json}
      :error -> {:error, :invalid_format}
      error -> {:error, error}
    end
  end

  def get_privacy_policy(_version), do: {:error, :invalid_version}
end
