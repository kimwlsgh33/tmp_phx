defmodule Myapp.TokenStore do
  @moduledoc """
  Provides functions for storing and retrieving authentication tokens
  for various social media providers using Erlang Term Storage (ETS).

  ## Purpose and Benefits of ETS Storage

  This module uses ETS tables instead of database storage for token management. 
  ETS provides several advantages for token storage:

  * **Performance**: In-memory storage allows for significantly faster token retrieval
    compared to database queries, reducing authentication latency in high-traffic scenarios.
  * **Simplicity**: Avoids database migrations and schema management for ephemeral data.
  * **Process Independence**: Tokens are accessible across processes without additional IPC.
  * **Reduced Database Load**: Keeps high-frequency token operations off the database.

  ## Current Scope

  Currently, this module focuses on Twitter authentication tokens, but is designed
  to be extended for other social media platforms. Each platform uses its own dedicated
  ETS table (e.g., `:twitter_tokens`).

  ## Security Considerations

  In-memory token storage presents different security tradeoffs compared to database storage:

  * **Persistence**: Tokens are lost on application restart, which may be desirable for 
    security but requires re-authentication.
  * **Memory Dumps**: In-memory tokens could be exposed in server memory dumps, making
    this unsuitable for highly sensitive credentials.
  * **No Encryption**: Unlike the `SocialMediaToken` module, tokens stored here are not
    encrypted at rest, relying on system-level security.

  ## When to Use

  Use this module when:
  * You need high-performance token retrieval
  * Tokens are short-lived and don't need to persist across application restarts
  * The application is handling a high volume of authentication requests
  * Immediate token availability is more critical than persistence

  For long-term token storage, persistent sessions, or when additional security measures
  like encryption are required, consider using database-based token modules like
  `Myapp.Accounts.PlatformToken` or `Myapp.Accounts.SocialMediaToken`.

  ## Integration with Other Token Modules

  This module complements the database-based token modules by providing a high-performance
  cache layer. A typical integration pattern is:
  
  1. Initially retrieve tokens from `SocialMediaToken` or `PlatformToken`
  2. Cache frequently used tokens in the `TokenStore` for faster access
  3. Fall back to database retrieval when tokens aren't found in ETS
  4. Update both storage locations when tokens change

  Future improvements may include auto-synchronization between ETS and database storage.
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

