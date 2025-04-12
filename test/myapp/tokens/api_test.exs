defmodule Myapp.Tokens.APITest do
  use Myapp.DataCase

  alias Myapp.Tokens
  alias Myapp.Accounts.User
  alias Myapp.Repo

  describe "session tokens" do
    setup do
      user = %User{email: "test@example.com", hashed_password: "some_hash"}
      {:ok, user} = Repo.insert(user)
      %{user: user}
    end

    test "create_session_token/1 creates a token", %{user: user} do
      assert {:ok, token, metadata} = Tokens.create_session_token(user)
      assert is_binary(token)
      assert metadata.context == "session"
    end

    test "verify_session_token/1 returns the user", %{user: user} do
      {:ok, token, _metadata} = Tokens.create_session_token(user)
      assert {:ok, found_user} = Tokens.verify_session_token(token)
      assert found_user.id == user.id
    end

    test "revoke_session_token/1 revokes the token", %{user: user} do
      {:ok, token, _metadata} = Tokens.create_session_token(user)
      assert :ok = Tokens.revoke_session_token(token)
      assert {:error, _} = Tokens.verify_session_token(token)
    end

    test "revoke_other_session_tokens/2 keeps the current token", %{user: user} do
      {:ok, token1, _} = Tokens.create_session_token(user)
      {:ok, token2, _} = Tokens.create_session_token(user)
      
      assert :ok = Tokens.revoke_other_session_tokens(user, token1)
      
      assert {:ok, _} = Tokens.verify_session_token(token1)
      assert {:error, _} = Tokens.verify_session_token(token2)
    end
  end

  describe "email tokens" do
    setup do
      user = %User{email: "test@example.com", hashed_password: "some_hash"}
      {:ok, user} = Repo.insert(user)
      %{user: user}
    end

    test "create_email_token/2 creates a token", %{user: user} do
      assert {:ok, token} = Tokens.create_email_token(user, "confirm")
      assert is_binary(token)
    end

    test "verify_email_token/2 returns the user", %{user: user} do
      {:ok, token} = Tokens.create_email_token(user, "confirm")
      assert {:ok, found_user} = Tokens.verify_email_token(token, "confirm")
      assert found_user.id == user.id
    end
  end

  describe "social tokens" do
    setup do
      user = %User{email: "test@example.com", hashed_password: "some_hash"}
      {:ok, user} = Repo.insert(user)
      
      token_data = %{
        "access_token" => "test_access_token",
        "refresh_token" => "test_refresh_token",
        "expires_in" => 3600
      }
      
      %{user: user, token_data: token_data}
    end

    test "store_social_token/3 stores a token", %{user: user, token_data: token_data} do
      assert {:ok, stored_data} = Tokens.store_social_token(user.id, :twitter, token_data)
      assert stored_data.access_token == "test_access_token"
    end

    test "get_social_token/2 retrieves a token", %{user: user, token_data: token_data} do
      {:ok, _} = Tokens.store_social_token(user.id, :twitter, token_data)
      assert {:ok, retrieved_data} = Tokens.get_social_token(user.id, :twitter)
      assert retrieved_data.access_token == "test_access_token"
    end

    test "revoke_social_token/2 revokes a token", %{user: user, token_data: token_data} do
      {:ok, _} = Tokens.store_social_token(user.id, :twitter, token_data)
      assert :ok = Tokens.revoke_social_token(user.id, :twitter)
      assert {:error, _} = Tokens.get_social_token(user.id, :twitter)
    end
  end
end
