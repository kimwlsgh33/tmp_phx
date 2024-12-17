# lib/my_app_web/controllers/chat_html.ex
defmodule MyappWeb.ChatHTML do
  use MyappWeb, :html

  embed_templates "chat_html/*"

  attr :message, :string, default: "Welcome to the chat!"

  def chat(assigns) do
    ~H"""
    <div class="row">
      <div class="col-md-12">
        <h2>Chat Room</h2>
        <p><%= @message %></p>
        <div id="chat-messages" phx-update="append" style="height: 400px; overflow-y: scroll; border: 1px solid #ccc; padding: 10px;"></div>
        <input type="text" id="chat-input" class="form-control" placeholder="Type a message...">
      </div>
    </div>
    """
  end
end
