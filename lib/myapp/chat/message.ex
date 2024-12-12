defmodule Myapp.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :content, :string
    field :user_id, :integer
    field :username, :string
    
    belongs_to :room, Myapp.Chat.Room

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :user_id, :username, :room_id])
    |> validate_required([:content, :username, :room_id])
    |> validate_length(:content, min: 1, max: 1000)
    |> foreign_key_constraint(:room_id)
  end
end
