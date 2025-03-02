defmodule Myapp.TokenStore do
  @moduledoc """
  Provides functions for storing and retrieving authentication tokens
  for various social media providers.
  
  This module uses ETS tables for token storage.
  """

  require Logger

  @doc """
  Retrieves Twitter tokens for a given user ID.
  
  ## Parameters
  
  * `user_id` - The ID of the user whose tokens to retrieve
  
  ## Returns
  
  * `{:ok, tokens}` - If tokens were found, where tokens is a map with 
    `access_token` and `refresh_token` fields
  * `{:error, :not_found}` - If no tokens were found for the user
  * `{:error, reason}` - If an error occurred
  """
  def get_twitter_tokens(user_id) do
    try do
      case :ets.lookup(:twitter_tokens, user_id) do
        [{^user_id, tokens}] -> 
          # Ensure the tokens map has the expected structure
          tokens = normalize_tokens(tokens)
          {:ok, tokens}
          
        [] -> 
          Logger.warning("No Twitter tokens found for user ID: #{inspect(user_id)}")
          {:error, :not_found}
      end
    rescue
      e in ArgumentError ->
        Logger.error("TokenStore error: ETS table :twitter_tokens may not exist - #{inspect(e)}")
        {:error, "Token store not initialized"}
        
      e ->
        Logger.error("Failed to retrieve Twitter tokens: #{inspect(e)}")
        {:error, "Failed to retrieve tokens"}
    end
  end

  # Ensures tokens have the expected structure
  defp normalize_tokens(tokens) when is_map(tokens) do
    # Make sure we have atom keys for access_token and refresh_token
    tokens
    |> ensure_atom_key("access_token")
    |> ensure_atom_key("refresh_token")
  end
  
  defp normalize_tokens(tokens), do: tokens
  
  # Converts string keys to atom keys if needed
  defp ensure_atom_key(map, key) when is_binary(key) do
    atom_key = String.to_atom(key)
    
    cond do
      Map.has_key?(map, atom_key) ->
        map
      Map.has_key?(map, key) ->
        Map.put(map, atom_key, Map.get(map, key))
      true ->
        map
    end
  end
end

