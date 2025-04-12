defmodule MyappWeb.Social.ThreadHTML do
  @moduledoc """
  HTML rendering for Thread controller.
  """

  use MyappWeb, :html

  def index(assigns) do
    ~H"""
    <div class="threads-container">
      <h1>Threads</h1>
      <div class="threads-list">
        <%= for thread <- @threads do %>
          <div class="thread-item">
            <h3><%= thread.title %></h3>
            <p><%= thread.content %></p>
            <div class="thread-meta">
              <span>Created: <%= thread.created_at %></span>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def show(assigns) do
    ~H"""
    <div class="thread-detail">
      <h1><%= @thread.title %></h1>
      <div class="thread-content">
        <%= @thread.content %>
      </div>
      <div class="thread-meta">
        <span>Created: <%= @thread.created_at %></span>
        <span>Updated: <%= @thread.updated_at %></span>
      </div>
      <div class="thread-replies">
        <h2>Replies</h2>
        <%= for reply <- @thread.replies do %>
          <div class="reply-item">
            <p><%= reply.content %></p>
            <div class="reply-meta">
              <span>By: <%= reply.user_id %></span>
              <span>At: <%= reply.created_at %></span>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
