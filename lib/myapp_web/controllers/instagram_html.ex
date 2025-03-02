defmodule MyappWeb.InstagramHTML do
  use MyappWeb, :html
  embed_templates "instagram_html/*"

  @doc """
  Extracts the value for a specific field from a changeset.
  Handles both string and atom keys for flexibility.

  ## Parameters
    - changeset: The Ecto.Changeset struct
    - field: The field name (atom or string)

  ## Returns
    The current value for the field from the changeset
  """
  def input_value(changeset, field) when is_binary(field) do
    input_value(changeset, String.to_existing_atom(field))
  rescue
    ArgumentError -> nil
  end

  def input_value(changeset, field) when is_atom(field) do
    case Ecto.Changeset.fetch_field(changeset, field) do
      {:changes, value} -> value
      {:data, value} -> value
      :error -> nil
    end
  end
end
