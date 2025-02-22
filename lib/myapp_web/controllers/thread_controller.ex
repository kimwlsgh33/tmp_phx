defmodule MyappWeb.ThreadController do
  use MyappWeb, :controller

  alias Myapp.Threads

  action_fallback MyappWeb.FallbackController

  def create(conn, %{"text" => text}) do
    with {:ok, thread} <- Threads.create_thread(text) do
      conn
      |> put_status(:created)
      |> json(thread)
    end
  end

  def reply(conn, %{"thread_id" => thread_id, "text" => text}) do
    with {:ok, reply} <- Threads.reply_to_thread(thread_id, text) do
      conn
      |> put_status(:created)
      |> json(reply)
    end
  end

  def show(conn, %{"id" => thread_id}) do
    with {:ok, thread} <- Threads.get_thread(thread_id) do
      json(conn, thread)
    end
  end

  def delete(conn, %{"id" => thread_id}) do
    with {:ok, _} <- Threads.delete_thread(thread_id) do
      send_resp(conn, :no_content, "")
    end
  end
end
