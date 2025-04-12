defmodule Myapp.Tokens.Storage.Factory do
  @moduledoc """
  Factory for creating token storage adapters.
  
  This module provides a way to create the appropriate storage adapter
  based on configuration, allowing the application to switch between
  different storage backends without changing code.
  """
  
  alias Myapp.Tokens.Storage.{Database, Cache, Hybrid}
  
  @doc """
  Creates a storage adapter based on the configured storage type.
  
  ## Parameters
  
  - `type`: The type of storage adapter to create (default: :hybrid)
  
  ## Returns
  
  - A module that implements the `Myapp.Tokens.Storage.Adapter` behaviour
  
  ## Examples
  
      iex> adapter = Myapp.Tokens.Storage.Factory.create(:database)
      iex> adapter.store_session_token("token", 1, %{})
  """
  def create(type \\ :hybrid) do
    case type do
      :database -> Database
      :cache -> Cache
      :hybrid -> Hybrid
      _ -> raise ArgumentError, "Unknown storage type: #{inspect(type)}"
    end
  end
  
  @doc """
  Creates a storage adapter based on the application configuration.
  
  This function reads the storage type from the application configuration
  and creates the appropriate adapter.
  
  ## Returns
  
  - A module that implements the `Myapp.Tokens.Storage.Adapter` behaviour
  
  ## Examples
  
      iex> adapter = Myapp.Tokens.Storage.Factory.create_from_config()
      iex> adapter.store_session_token("token", 1, %{})
  """
  def create_from_config do
    type = Application.get_env(:myapp, :token_storage, :hybrid)
    create(type)
  end
end
