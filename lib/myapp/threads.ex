defmodule Myapp.Threads do
  @moduledoc """
  The Threads context.
  """

  alias Myapp.ThreadApi

  @doc """
  Creates a new thread.

  ## Examples

      iex> create_thread("Hello, Thread!")
      {:ok, %{"id" => "123", ...}}

      iex> create_thread("")
      {:error, %{"error" => %{"message" => "Invalid text"}}}

  """
  def create_thread(text) when is_binary(text) and text != "" do
    ThreadApi.create_thread(text)
  end

  def create_thread(_), do: {:error, "Text is required"}

  @doc """
  Replies to a thread.

  ## Examples

      iex> reply_to_thread("123", "This is a reply")
      {:ok, %{"id" => "456", ...}}

      iex> reply_to_thread("invalid", "Reply")
      {:error, %{"error" => %{"message" => "Thread not found"}}}

  """
  def reply_to_thread(thread_id, text) when is_binary(thread_id) and is_binary(text) and text != "" do
    ThreadApi.reply_to_thread(thread_id, text)
  end

  def reply_to_thread(_, _), do: {:error, "Thread ID and text are required"}

  @doc """
  Gets a thread by ID.

  ## Examples

      iex> get_thread("123")
      {:ok, %{"id" => "123", ...}}

      iex> get_thread("invalid")
      {:error, %{"error" => %{"message" => "Thread not found"}}}

  """
  def get_thread(thread_id) when is_binary(thread_id) do
    ThreadApi.get_thread(thread_id)
  end

  def get_thread(_), do: {:error, "Thread ID is required"}

  @doc """
  Deletes a thread.

  ## Examples

      iex> delete_thread("123")
      {:ok, %{"success" => true}}

      iex> delete_thread("invalid")
      {:error, %{"error" => %{"message" => "Thread not found"}}}

  """
  def delete_thread(thread_id) when is_binary(thread_id) do
    ThreadApi.delete_thread(thread_id)
  end

  def delete_thread(_), do: {:error, "Thread ID is required"}
end
