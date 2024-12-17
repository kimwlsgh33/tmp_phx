defmodule MyappWeb.UserSocket do
  use Phoenix.Socket

 channel "room:*", MyappWeb.RoomChannel

 def connect(_params, socket, _connect_info) do
   {:ok, socket}
 end

 def id(_socket), do: nil #id -> socket id

end
