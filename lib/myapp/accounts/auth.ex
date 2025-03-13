defmodule Myapp.Accounts.Auth do
  @moduledoc """
  Handles user authentication and token management for social media platforms.
  """

  alias Myapp.Repo
  alias Myapp.Accounts.{User, PlatformToken}
  import Ecto.Query

  @doc """
  Verifies if a session is valid and returns the associated user.
  """
  def verify_session(session) do
    with user_id when not is_nil(user_id) <- Map.get(session, "user_id"),
         %User{} = user <- Repo.get(User, user_id) do
      {:ok, user}
    else
      nil -> {:error, :invalid_session}
      _ -> {:error, :user_not_found}
    end
  end

  @doc """
  Gets a platform token for a user.
  """
  def get_platform_token(user_id, platform) do
    case Repo.get_by(PlatformToken, user_id: user_id, platform: platform) do
      nil -> {:error, :token_not_found}
      token -> {:ok, token}
    end
  end

  @doc """
  Stores a platform token for a user.
  """
  def store_platform_token(user_id, platform, token_data) do
    %PlatformToken{}
    |> PlatformToken.changeset(%{
      user_id: user_id,
      platform: platform,
      access_token: token_data.access_token,
      refresh_token: token_data.refresh_token,
      expires_at: calculate_expiry(token_data.expires_in)
    })
    |> Repo.insert_or_update()
  end

  @doc """
  Revokes a platform token.
  """
  def revoke_platform_token(user_id, platform) do
    case get_platform_token(user_id, platform) do
      {:ok, token} -> Repo.delete(token)
      error -> error
    end
  end

  @doc """
  Lists all active platform tokens for a user.
  """
  def list_platform_tokens(user_id) do
    PlatformToken
    |> where(user_id: ^user_id)
    |> Repo.all()
  end

  # Private Functions

  defp calculate_expiry(expires_in) when is_integer(expires_in) do
    DateTime.utc_now()
    |> DateTime.add(expires_in, :second)
    |> DateTime.truncate(:second)
  end

  defp calculate_expiry(_), do: nil
end

