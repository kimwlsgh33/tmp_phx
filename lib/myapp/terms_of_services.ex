defmodule Myapp.TermsOfServices do
  @moduledoc """
  Handles terms of service retrieval and management.

  This module provides functions for retrieving terms of service documents
  in different versions and languages.
  """

  alias Myapp.ErrorHandler

  @versions ["v1", "v1_en"]

  @doc """
  Returns a list of all available terms of service versions.
  """
  def get_versions, do: @versions

  @doc """
  Retrieves the terms of service document for the specified version.

  ## Parameters

    * `version` - The version of the terms of service to retrieve (e.g., "v1", "v1_en")

  ## Returns

    * `{:ok, terms}` - If the terms of service were retrieved successfully
    * `{:error, error}` - If an error occurs
  """
  def get_terms_of_services(version) when version in @versions do
    priv_dir = Application.app_dir(:myapp, "priv")
    file_path = Path.join([priv_dir, "terms_of_services", "#{version}.json"])

    with {:ok, content} <- File.read(file_path),
         {:ok, term_of_services} <- Jason.decode(content) do
      {:ok, term_of_services}
    else
      {:error, :enoent} ->
        # Use our standardized error handling for file not found
        {:error, ErrorHandler.error(
          :not_found,
          "Terms of service file not found",
          %{version: version, path: file_path},
          __MODULE__
        )}

      {:error, %Jason.DecodeError{} = error} ->
        # Use our standardized error handling for JSON parsing errors
        {:error, ErrorHandler.error(
          :bad_request,
          "Invalid JSON in terms of service file",
          %{version: version, error: error},
          __MODULE__
        )}

      :error ->
        # Use our standardized error handling for invalid format
        {:error, ErrorHandler.error(
          :bad_request,
          "Invalid format in terms of service file",
          %{version: version},
          __MODULE__
        )}

      error ->
        # Use our standardized error handling for other errors
        {:error, ErrorHandler.normalize({:error, error}) |> elem(1)}
    end
  end

  def get_terms_of_services(version) do
    # Use our standardized error handling for invalid version
    {:error, ErrorHandler.error(
      :bad_request,
      "Invalid terms of service version",
      %{version: version, available_versions: @versions},
      __MODULE__
    )}
  end
end
