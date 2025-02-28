defmodule Myapp.ThreadApi do
  @moduledoc """
  Client for interacting with Thread (Meta) API.
  """

  @base_url "https://graph.facebook.com/v19.0"

  @doc """
  Create a new thread.
  """
  def create_thread(text) do
    request(:post, "/threads", %{text: text})
  end

  @doc """
  Reply to a thread.
  """
  def reply_to_thread(thread_id, text) do
    request(:post, "/#{thread_id}/replies", %{text: text})
  end

  @doc """
  Get thread details.
  """
  def get_thread(thread_id) do
    request(:get, "/#{thread_id}")
  end

  @doc """
  Delete a thread.
  """
  def delete_thread(thread_id) do
    request(:delete, "/#{thread_id}")
  end

  defp request(method, path, body \\ nil) do
    url = @base_url <> path

    headers = [
      {"Authorization", "Bearer #{get_access_token()}"},
      {"Content-Type", "application/json"}
    ]

    body = if body, do: Jason.encode!(body), else: ""

    case :hackney.request(method, url, headers, body, [:with_body]) do
      {:ok, status, _headers, response_body} when status in 200..299 ->
        {:ok, Jason.decode!(response_body)}

      {:ok, _status, _headers, response_body} ->
        {:error, Jason.decode!(response_body)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_access_token do
    Application.get_env(:myapp, :thread_api)[:access_token]
  end
end
