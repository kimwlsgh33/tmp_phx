defmodule Myapp.Chat.Room do
  @moduledoc """
  Represents a chat room.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :name, :string
    field :description, :string
    field :slug, :string

    has_many :messages, Myapp.Chat.Message

    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :description, :slug])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 100)
    |> generate_slug()
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :name) do
      nil ->
        changeset

      name ->
        slug =
          name
          |> String.downcase()
          |> String.replace(~r/[^\w-]+/u, "-")

        put_change(changeset, :slug, slug)
    end
  end
end
