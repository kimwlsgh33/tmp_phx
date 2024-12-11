defmodule Myapp.FileServer do
  @moduledoc """
  Handles file operations for the application.
  """

  require Logger

  @doc """
  Reads a file from the given path.

  Returns `{:ok, content}` if successful, `{:error, reason}` otherwise.
  """
  def read_file(path) do
    case File.read(path) do
      {:ok, content} ->
        Logger.info("Successfully read file: #{path}")
        {:ok, content}

      {:error, reason} = error ->
        Logger.error("Failed to read file #{path}: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Writes content to a file at the given path.

  Returns `:ok` if successful, `{:error, reason}` otherwise.
  """
  def write_file(path, content) do
    case File.write(path, content) do
      :ok ->
        Logger.info("Successfully wrote to file: #{path}")
        :ok

      {:error, reason} = error ->
        Logger.error("Failed to write to file #{path}: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Checks if a file exists at the given path.
  """
  def file_exists?(path) do
    File.exists?(path)
  end

  @doc """
  Deletes a file at the given path.

  Returns `:ok` if successful, `{:error, reason}` otherwise.
  """
  def delete_file(path) do
    case File.rm(path) do
      :ok ->
        Logger.info("Successfully deleted file: #{path}")
        :ok

      {:error, reason} = error ->
        Logger.error("Failed to delete file #{path}: #{inspect(reason)}")
        error
    end
  end
end
