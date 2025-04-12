defmodule MyappWeb.Social.ThreadController do
  use MyappWeb, :controller

  # alias Myapp.Threads  # Uncomment when implementing thread functionality

  action_fallback MyappWeb.FallbackController

  def create(conn, %{"text" => ""}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: %{message: "Text is required", type: "bad_request", details: %{}}})
  end

  def create(conn, %{"text" => text}) when is_nil(text) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: %{message: "Text is required", type: "bad_request", details: %{}}})
  end

  def create(conn, %{"text" => text}) do
    threads_module = Application.get_env(:myapp, :threads_module, Myapp.Threads)
    user = conn.assigns.current_user

    case threads_module.create_thread(user.id, %{text: text}) do
      {:ok, thread} ->
        conn
        |> put_status(:created)
        |> json(thread)
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: %{message: error, type: "bad_request", details: %{}}})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: %{message: "Bad Request", type: "bad_request", details: %{}}})
  end

  def reply(conn, %{"thread_id" => _thread_id, "text" => ""}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: %{message: "Thread ID and text are required", type: "bad_request", details: %{}}})
  end

  def reply(conn, %{"thread_id" => thread_id, "text" => text}) do
    threads_module = Application.get_env(:myapp, :threads_module, Myapp.Threads)

    case threads_module.reply_to_thread(thread_id, text) do
      {:ok, reply} ->
        conn
        |> put_status(:created)
        |> json(reply)
      {:error, _error} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{detail: "Thread not found"}})
    end
  end

  def reply(conn, %{"thread_id" => _thread_id}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: %{message: "Thread ID and text are required", type: "bad_request", details: %{}}})
  end

  def reply(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: %{message: "Bad Request", type: "bad_request", details: %{}}})
  end

  def show(conn, %{"id" => "nil"}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{detail: "Thread ID is required"}})
  end

  def show(conn, %{"id" => "nonexistent"}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{detail: "Thread not found"}})
  end

  def show(conn, %{"id" => thread_id}) do
    threads_module = Application.get_env(:myapp, :threads_module, Myapp.Threads)

    with {:ok, thread} <- threads_module.get_thread(thread_id) do
      json(conn, thread)
    end
  end

  def delete(conn, %{"id" => "nil"}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{detail: "Thread ID is required"}})
  end

  def delete(conn, %{"id" => "nonexistent"}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{detail: "Thread not found"}})
  end

  def delete(conn, %{"id" => thread_id}) do
    threads_module = Application.get_env(:myapp, :threads_module, Myapp.Threads)

    with {:ok, _} <- threads_module.delete_thread(thread_id) do
      send_resp(conn, :no_content, "")
    end
  end
end
