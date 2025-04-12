defmodule Myapp.Threads.Behaviour do
  @moduledoc """
  Behaviour module defining the interface for thread operations.

  This module specifies the contract for thread-related operations like
  creating, deleting, listing, updating, and retrieving threads. It allows
  for easy mocking in tests.
  """

  @type thread_id :: String.t()
  @type user_id :: String.t()
  @type thread :: %{
    id: thread_id,
    title: String.t(),
    content: String.t(),
    user_id: user_id,
    created_at: DateTime.t(),
    updated_at: DateTime.t()
  }
  @type thread_params :: %{
    title: String.t(),
    content: String.t(),
    user_id: user_id
  }
  @type update_params :: %{
    optional(:title) => String.t(),
    optional(:content) => String.t()
  }

  @doc """
  Creates a new thread.

  ## Parameters
    * `user_id` - ID of the user creating the thread
    * `params` - Map containing thread parameters (title, content)

  ## Returns
    * `{:ok, thread}` - Successfully created thread
    * `{:error, reason}` - Error with reason
  """
  @callback create_thread(String.t()) ::
    {:ok, map()} |
    {:error, String.t()}

  @callback create_thread(user_id(), thread_params()) ::
    {:ok, thread()} |
    {:error, String.t()}

  @doc """
  Lists threads for a user.

  ## Parameters
    * `user_id` - ID of the user whose threads should be listed

  ## Returns
    * `{:ok, threads}` - List of threads
    * `{:error, reason}` - Error with reason
  """
  @callback list_threads(user_id()) ::
    {:ok, [thread()]} |
    {:error, String.t()}

  @doc """
  Updates thread details.

  ## Parameters
    * `thread_id` - ID of the thread to be updated
    * `params` - Map containing thread parameters to update (title, content)

  ## Returns
    * `{:ok, thread}` - Updated thread
    * `{:error, reason}` - Error with reason
  """
  @callback update_thread(thread_id(), update_params()) ::
    {:ok, thread()} |
    {:error, String.t()}

  @doc """
  Deletes a thread.

  ## Parameters
    * `thread_id` - ID of the thread to be deleted

  ## Returns
    * `:ok` - Successfully deleted thread
    * `{:error, reason}` - Error with reason
  """
  @callback delete_thread(thread_id()) ::
    {:ok, thread()} |
    {:error, String.t()}

  @doc """
  Gets thread details.

  ## Parameters
    * `thread_id` - ID of the thread to retrieve

  ## Returns
    * `{:ok, thread}` - Thread details
    * `{:error, reason}` - Error with reason
  """
  @callback get_thread(thread_id()) ::
    {:ok, thread()} |
    {:error, String.t()}

  @doc """
  Replies to a thread.

  ## Parameters
    * `thread_id` - ID of the thread to reply to
    * `text` - Content of the reply

  ## Returns
    * `{:ok, reply}` - Successfully created reply
    * `{:error, reason}` - Error with reason
  """
  @callback reply_to_thread(thread_id(), String.t()) ::
    {:ok, map()} |
    {:error, String.t()}
end
