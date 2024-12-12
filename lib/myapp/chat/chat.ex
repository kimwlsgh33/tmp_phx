defmodule Myapp.Chat do
  @moduledoc """
  The Chat context.
  Handles all chat-related business logic including rooms and messages.
  """

  import Ecto.Query, warn: false
  alias Myapp.Repo
  alias Myapp.Chat.{Room, Message}

  @doc """
  Returns the list of rooms.
  """
  def list_rooms do
    Repo.all(Room)
  end

  @doc """
  Gets a single room.
  Returns nil if the Room does not exist.
  """
  def get_room(id), do: Repo.get(Room, id)

  @doc """
  Creates a room.
  """
  def create_room(attrs \\ %{}) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the list of messages for a room.
  """
  def list_messages(room_id) do
    Message
    |> where([m], m.room_id == ^room_id)
    |> order_by([m], asc: m.inserted_at)
    |> Repo.all()
  end

  @doc """
  Creates a message.
  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end
end
