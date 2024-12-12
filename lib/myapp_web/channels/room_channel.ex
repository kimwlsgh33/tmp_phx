defmodule MyappWeb.RoomChannel do
  use MyappWeb, :channel
  alias Myapp.Chat

  @impl true
  def join("room:" <> room_id, _params, socket) do
    if room = Chat.get_room(room_id) do
      messages = Chat.list_messages(room_id)
      response = %{
        room: %{id: room.id, name: room.name},
        messages: messages
      }
      {:ok, response, assign(socket, :room_id, room.id)}
    else
      {:error, %{reason: "Room not found"}}
    end
  end

  @impl true
  def handle_in("new_message", %{"content" => content, "username" => username}, socket) do
    room_id = socket.assigns.room_id
    
    case Chat.create_message(%{
      content: content,
      username: username,
      room_id: room_id
    }) do
      {:ok, message} ->
        broadcast!(socket, "new_message", %{
          id: message.id,
          content: message.content,
          username: message.username,
          inserted_at: message.inserted_at
        })
        {:reply, :ok, socket}

      {:error, _changeset} ->
        {:reply, {:error, %{reason: "Failed to create message"}}, socket}
    end
  end
end
