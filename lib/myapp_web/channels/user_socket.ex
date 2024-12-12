defmodule MyappWeb.UserSocket do
  @moduledoc """
  The Socket handler
  """
  use Phoenix.Socket

  @doc """
  It's possible to control the websocket connection and
  assign values that can be accessed by your channel topics.
  """

  ## Channels
  channel "chat:*", MyappWeb.ChatChannel

  @doc """
  Socket params are passed from the client and can
  be used to verify and authenticate a user. After
  verification, you can put default assigns into
  the socket that will be set for all channels:

  ## Example

      {:ok, assign(socket, :user_id, verified_user_id)}

  To deny connection, return `:error` or `{:error, term}`. To control the
  response the client receives in that case, 
  [define an error handler in the websocket configuration](https://hexdocs.pm/phoenix/Phoenix.Endpoint.html#socket/3-websocket-configuration).

  See `Phoenix.Token` documentation for examples in
  performing token verification on connect.
  """
  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  @doc """
  Socket IDs are topics that allow you to identify all sockets for a given user:

  ## Examples

      iex> socket = %Phoenix.Socket{assigns: %{user_id: "123"}}
      iex> id(socket)
      "user_socket:123"

  Would allow you to broadcast a "disconnect" event and terminate
  all active sockets and channels for a given user:

      iex> MyappWeb.Endpoint.broadcast("user_socket:123", "disconnect", %{})
      :ok

  ## Return values
      
    * A string in the format `"user_socket:user_id"` - identifies the socket for a specific user.
    * `nil` - makes this socket anonymous.
  """
  @impl true
  def id(_socket), do: nil
  # def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  # Elixir.MyappWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
end
