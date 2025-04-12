defmodule Myapp.HttpClient do
  @moduledoc """
  HTTP client for making API requests.
  
  This module provides a simple wrapper around HTTPoison for making HTTP requests.
  """

  @doc """
  Makes a GET request to the specified URL.
  
  ## Parameters
    * `url` - The URL to request
    * `options` - Additional options for the request
    
  ## Options
    * `:headers` - HTTP headers to include in the request
    * `:params` - Query parameters to include in the URL
    * `:timeout` - Request timeout in milliseconds
    
  ## Returns
    * `{:ok, %{status_code: status_code, body: body}}` - If the request was successful
    * `{:error, reason}` - If there was an error
  """
  def get(url, options \\ []) do
    headers = Keyword.get(options, :headers, [])
    params = Keyword.get(options, :params, %{})
    timeout = Keyword.get(options, :timeout, 30_000)
    
    url_with_params = if Enum.empty?(params), do: url, else: url <> "?" <> URI.encode_query(params)
    
    case HTTPoison.get(url_with_params, headers, recv_timeout: timeout) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:ok, %{status_code: status_code, body: body}}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @doc """
  Makes a POST request to the specified URL.
  
  ## Parameters
    * `url` - The URL to request
    * `options` - Additional options for the request
    
  ## Options
    * `:headers` - HTTP headers to include in the request
    * `:body` - Request body
    * `:json` - JSON data to include in the request body (will be encoded)
    * `:form` - Form data to include in the request body (will be encoded)
    * `:timeout` - Request timeout in milliseconds
    
  ## Returns
    * `{:ok, %{status_code: status_code, body: body}}` - If the request was successful
    * `{:error, reason}` - If there was an error
  """
  def post(url, options \\ []) do
    headers = Keyword.get(options, :headers, [])
    body = prepare_body(options)
    timeout = Keyword.get(options, :timeout, 30_000)
    
    case HTTPoison.post(url, body, headers, recv_timeout: timeout) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:ok, %{status_code: status_code, body: body}}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @doc """
  Makes a PUT request to the specified URL.
  
  ## Parameters
    * `url` - The URL to request
    * `options` - Additional options for the request
    
  ## Options
    * `:headers` - HTTP headers to include in the request
    * `:body` - Request body
    * `:json` - JSON data to include in the request body (will be encoded)
    * `:form` - Form data to include in the request body (will be encoded)
    * `:timeout` - Request timeout in milliseconds
    
  ## Returns
    * `{:ok, %{status_code: status_code, body: body}}` - If the request was successful
    * `{:error, reason}` - If there was an error
  """
  def put(url, options \\ []) do
    headers = Keyword.get(options, :headers, [])
    body = prepare_body(options)
    timeout = Keyword.get(options, :timeout, 30_000)
    
    case HTTPoison.put(url, body, headers, recv_timeout: timeout) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:ok, %{status_code: status_code, body: body}}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @doc """
  Makes a DELETE request to the specified URL.
  
  ## Parameters
    * `url` - The URL to request
    * `options` - Additional options for the request
    
  ## Options
    * `:headers` - HTTP headers to include in the request
    * `:params` - Query parameters to include in the URL
    * `:timeout` - Request timeout in milliseconds
    
  ## Returns
    * `{:ok, %{status_code: status_code, body: body}}` - If the request was successful
    * `{:error, reason}` - If there was an error
  """
  def delete(url, options \\ []) do
    headers = Keyword.get(options, :headers, [])
    params = Keyword.get(options, :params, %{})
    timeout = Keyword.get(options, :timeout, 30_000)
    
    url_with_params = if Enum.empty?(params), do: url, else: url <> "?" <> URI.encode_query(params)
    
    case HTTPoison.delete(url_with_params, headers, recv_timeout: timeout) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:ok, %{status_code: status_code, body: body}}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  # Private helper functions

  defp prepare_body(options) do
    cond do
      body = Keyword.get(options, :body) ->
        body
      json = Keyword.get(options, :json) ->
        headers = Keyword.get(options, :headers, [])
        headers = [{"Content-Type", "application/json"} | headers]
        Keyword.put(options, :headers, headers)
        Jason.encode!(json)
      form = Keyword.get(options, :form) ->
        headers = Keyword.get(options, :headers, [])
        headers = [{"Content-Type", "application/x-www-form-urlencoded"} | headers]
        Keyword.put(options, :headers, headers)
        URI.encode_query(form)
      true ->
        ""
    end
  end
end
