defmodule Myapp.Tokens.Cache do
  @moduledoc """
  Provides caching functionality for tokens to improve performance.

  This module uses ETS tables to store tokens in memory for fast access.
  It handles automatic expiration and cleanup of cached tokens.
  """

  use GenServer
  require Logger
  alias Myapp.Tokens.Metrics

  @session_table :token_session_cache
  @social_table :token_social_cache
  @cleanup_interval 60_000 # 1 minute

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Stores a session token in the cache.
  """
  def put_session_token(token, user_id) do
    true = :ets.insert(@session_table, {token, user_id, timestamp()})
    :ok
  end

  @doc """
  Retrieves a session token from the cache.

  Returns `{:ok, user_id}` if found, or `{:error, :not_found}` if not found.
  """
  def get_session_token(token) do
    case :ets.lookup(@session_table, token) do
      [{^token, user_id, _timestamp}] -> {:ok, user_id}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Removes a session token from the cache.
  """
  def delete_session_token(token) do
    true = :ets.delete(@session_table, token)
    :ok
  end

  @doc """
  Removes all session tokens for a user except the specified token.
  """
  def delete_user_session_tokens(user_id, opts \\ []) do
    except_token = Keyword.get(opts, :except)

    # This is inefficient as it requires a full table scan
    # In a production system, you'd want to maintain a separate index
    :ets.match_object(@session_table, {:_, user_id, :_})
    |> Enum.each(fn {token, ^user_id, _} ->
      if token != except_token do
        :ets.delete(@session_table, token)
      end
    end)

    :ok
  end

  @doc """
  Stores a social media token in the cache.
  """
  def put_social_token(user_id, provider, token_data) do
    key = {user_id, provider}
    expires_at = Map.get(token_data, :expires_at)

    cache_entry = {
      key,
      token_data,
      timestamp(),
      expires_at
    }

    true = :ets.insert(@social_table, cache_entry)
    :ok
  end

  @doc """
  Retrieves a social media token from the cache.

  Returns `{:ok, token_data}` if found, or `{:error, :not_found}` if not found.
  """
  def get_social_token(user_id, provider) do
    key = {user_id, provider}

    case :ets.lookup(@social_table, key) do
      [{^key, token_data, _timestamp, expires_at}] ->
        if is_nil(expires_at) or DateTime.compare(expires_at, DateTime.utc_now()) == :gt do
          {:ok, token_data}
        else
          # Token is expired, remove from cache
          :ets.delete(@social_table, key)
          {:error, :not_found}
        end

      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  Removes a social media token from the cache.
  """
  def delete_social_token(user_id, provider) do
    key = {user_id, provider}
    true = :ets.delete(@social_table, key)
    :ok
  end

  @doc """
  Clears all cached tokens.
  """
  def clear_all do
    :ets.delete_all_objects(@session_table)
    :ets.delete_all_objects(@social_table)
    :ok
  end

  # Server callbacks

  @impl true
  def init(_) do
    # Create ETS tables
    :ets.new(@session_table, [:set, :named_table, :public, read_concurrency: true])
    :ets.new(@social_table, [:set, :named_table, :public, read_concurrency: true])

    # Schedule periodic cleanup
    schedule_cleanup()

    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_expired_tokens()
    schedule_cleanup()
    {:noreply, state}
  end

  # Private helpers

  defp timestamp do
    DateTime.utc_now()
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end

  defp cleanup_expired_tokens do
    now = DateTime.utc_now()

    # Clean up expired social tokens
    # This is a simple implementation that scans the whole table
    # In production, you might want a more efficient approach
    :ets.match_object(@social_table, {:_, :_, :_, :_})
    |> Enum.each(fn {key, _token_data, _timestamp, expires_at} ->
      if not is_nil(expires_at) and DateTime.compare(expires_at, now) == :lt do
        :ets.delete(@social_table, key)
      end
    end)

    # For session tokens, we don't have expiration in the cache
    # They're cleaned up when the actual token expires in the database
    # or when explicitly deleted

    :ok
  end
end
