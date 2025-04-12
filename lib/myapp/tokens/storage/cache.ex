defmodule Myapp.Tokens.Storage.Cache do
  @moduledoc """
  Cache storage adapter for tokens.

  This module implements the `Myapp.Tokens.Storage.Adapter` behaviour
  using ETS tables for high-performance, in-memory token storage.
  """

  @behaviour Myapp.Tokens.Storage.Adapter

  @session_table :token_session_cache
  @social_table :token_social_cache
  @email_table :token_email_cache

  # Helper function to get the current timestamp
  defp timestamp do
    System.system_time(:second)
  end

  @impl true
  def store_session_token(token, user_id, _metadata) do
    true = :ets.insert(@session_table, {token, user_id, timestamp()})
    {:ok, token}
  end

  @impl true
  def get_session_token(token) do
    case :ets.lookup(@session_table, token) do
      [{^token, user_id, _timestamp}] -> {:ok, user_id}
      [] -> {:error, :not_found}
    end
  end

  @impl true
  def delete_session_token(token) do
    :ets.delete(@session_table, token)
    :ok
  end

  @impl true
  def delete_user_session_tokens(user_id, except_token) do
    # This is inefficient in ETS as we need to scan the whole table
    # A better approach would be to have a separate table indexed by user_id
    :ets.foldl(
      fn
        {token, ^user_id, _timestamp}, _acc when token != except_token ->
          :ets.delete(@session_table, token)
          nil
        {_, _, _}, acc ->
          acc
      end,
      nil,
      @session_table
    )

    :ok
  end

  @impl true
  def store_email_token(token, user_id, context, _metadata) do
    true = :ets.insert(@email_table, {{token, context}, user_id, timestamp()})
    {:ok, token}
  end

  @impl true
  def get_email_token(token, context) do
    case :ets.lookup(@email_table, {token, context}) do
      [{{^token, ^context}, user_id, _timestamp}] -> {:ok, user_id}
      [] -> {:error, :not_found}
    end
  end

  @impl true
  def store_social_token(user_id, provider, token_data) do
    key = {user_id, provider}

    # Add timestamp to the token data
    token_data_with_timestamp = Map.put(token_data, :cached_at, timestamp())

    true = :ets.insert(@social_table, {key, token_data_with_timestamp})
    {:ok, token_data}
  end

  @impl true
  def get_social_token(user_id, provider) do
    key = {user_id, provider}

    case :ets.lookup(@social_table, key) do
      [{^key, token_data}] -> {:ok, token_data}
      [] -> {:error, :not_found}
    end
  end

  @impl true
  def update_social_token(user_id, provider, token_data) do
    # For cache, update is the same as store
    store_social_token(user_id, provider, token_data)
  end

  @impl true
  def delete_social_token(user_id, provider) do
    key = {user_id, provider}
    :ets.delete(@social_table, key)
    :ok
  end

  # Additional functions for cache management

  @doc """
  Initializes the cache tables.
  Should be called when the application starts.
  """
  def init do
    # Create the session token table if it doesn't exist
    if :ets.info(@session_table) == :undefined do
      :ets.new(@session_table, [:set, :public, :named_table])
    end

    # Create the social token table if it doesn't exist
    if :ets.info(@social_table) == :undefined do
      :ets.new(@social_table, [:set, :public, :named_table])
    end

    # Create the email token table if it doesn't exist
    if :ets.info(@email_table) == :undefined do
      :ets.new(@email_table, [:set, :public, :named_table])
    end

    :ok
  end

  @doc """
  Cleans up expired tokens from the cache.
  """
  def cleanup(max_age \\ 86400) do
    now = timestamp()
    expiry = now - max_age

    # Clean up session tokens
    :ets.foldl(
      fn {token, _user_id, timestamp}, count when timestamp < expiry ->
        :ets.delete(@session_table, token)
        count + 1
      fn _, count -> count end
      end,
      0,
      @session_table
    )

    # Clean up email tokens
    :ets.foldl(
      fn {{token, context}, _user_id, timestamp}, count when timestamp < expiry ->
        :ets.delete(@email_table, {token, context})
        count + 1
      fn _, count -> count end
      end,
      0,
      @email_table
    )

    # Clean up social tokens (if they have an expires_at field)
    :ets.foldl(
      fn {key, token_data}, count ->
        case token_data do
          %{expires_at: expires_at} when not is_nil(expires_at) ->
            if DateTime.compare(expires_at, DateTime.utc_now()) == :lt do
              :ets.delete(@social_table, key)
              count + 1
            else
              count
            end

          _ ->
            # If no expires_at, check cached_at
            case token_data do
              %{cached_at: cached_at} when cached_at < expiry ->
                :ets.delete(@social_table, key)
                count + 1

              _ ->
                count
            end
        end
      end,
      0,
      @social_table
    )
  end
end
