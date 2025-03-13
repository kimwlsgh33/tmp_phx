defmodule Myapp.HttpClient do
  @moduledoc """
  Centralized HTTP client using Finch for all HTTP requests.
  Provides a consistent interface for making HTTP requests across the application.
  """

  require Logger

  @doc """
  Performs a GET request.

  ## Options
    * `:headers` - List of request headers
    * `:params` - Map or keyword list of query parameters
  """
  def get(url, opts \\ []) do
    headers = Keyword.get(opts, :headers, [])
    params = Keyword.get(opts, :params)
    
    url = if params, do: append_query_params(url, params), else: url

    Finch.build(:get, url, headers)
    |> send_request()
  end

  @doc """
  Performs a POST request.

  ## Options
    * `:headers` - List of request headers
    * `:body` - Request body (will be encoded based on content-type)
  """
  def post(url, opts \\ []) do
    headers = Keyword.get(opts, :headers, [])
    body = encode_body(opts[:body], headers)

    Finch.build(:post, url, headers, body)
    |> send_request()
  end

  # Private helpers

  defp send_request(req) do
    case Finch.request(req, Myapp.Finch) do
      {:ok, %Finch.Response{status: status, body: body}} ->
        {:ok, %{status_code: status, body: body}}
      
      {:error, reason} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, %{reason: reason}}
    end
  end

  defp encode_body(nil, _headers), do: ""
  defp encode_body(body, headers) do
    case get_content_type(headers) do
      "application/x-www-form-urlencoded" ->
        URI.encode_query(body)
      
      "application/json" ->
        Jason.encode!(body)
      
      _ ->
        body
    end
  end

  defp get_content_type(headers) do
    case List.keyfind(headers, "Content-Type", 0) do
      {_, content_type} -> content_type
      nil -> "application/json"
    end
  end

  defp append_query_params(url, params) when is_map(params) or is_list(params) do
    uri = URI.parse(url)
    existing_query = uri.query || ""
    existing_params = URI.decode_query(existing_query)
    
    new_params = 
      if is_map(params) do
        Map.merge(existing_params, params)
      else
        Enum.into(params, existing_params)
      end
    
    query = URI.encode_query(new_params)
    %{uri | query: query} |> URI.to_string()
  end
end

