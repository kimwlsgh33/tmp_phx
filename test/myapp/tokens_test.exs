defmodule Myapp.TokensTest do
  use Myapp.DataCase, async: true

  alias Myapp.Tokens
  alias Myapp.Accounts.User
  alias Myapp.Accounts.UserToken
  import Myapp.AccountsFixtures

  describe "create_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token with the user", %{user: user} do
      {:ok, token, metadata} = Tokens.create_session_token(user)
      
      assert is_binary(token)
      assert metadata.context == "session"
      assert is_struct(metadata.created_at, DateTime) || is_struct(metadata.created_at, NaiveDateTime)
      
      # Verify the token is stored in the database
      assert user_token = Repo.get_by(UserToken, user_id: user.id, context: "session")
      assert user_token.inserted_at
    end
  end

  describe "verify_session_token/1" do
    setup do
      user = user_fixture()
      {:ok, token, _metadata} = Tokens.create_session_token(user)
      %{user: user, token: token}
    end

    test "returns the user for a valid token", %{user: user, token: token} do
      assert {:ok, returned_user} = Tokens.verify_session_token(token)
      assert returned_user.id == user.id
    end

    test "does not return the user for an invalid token" do
      assert {:error, :invalid_token} = Tokens.verify_session_token("invalid token")
    end

    test "does not return the user for an expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert {:error, :invalid_token} = Tokens.verify_session_token(token)
    end
  end

  describe "revoke_session_token/1" do
    setup do
      user = user_fixture()
      {:ok, token, _metadata} = Tokens.create_session_token(user)
      %{user: user, token: token}
    end

    test "revokes the token", %{token: token} do
      assert :ok = Tokens.revoke_session_token(token)
      assert {:error, :invalid_token} = Tokens.verify_session_token(token)
      assert Repo.all(UserToken) |> length() == 0
    end

    test "returns error for invalid token" do
      assert {:error, :token_not_found} = Tokens.revoke_session_token("invalid token")
    end
  end

  describe "revoke_other_session_tokens/2" do
    setup do
      user = user_fixture()
      {:ok, token1, _} = Tokens.create_session_token(user)
      {:ok, token2, _} = Tokens.create_session_token(user)
      %{user: user, token1: token1, token2: token2}
    end

    test "revokes all tokens except the given one", %{user: user, token1: token1, token2: token2} do
      assert :ok = Tokens.revoke_other_session_tokens(user, token1)
      
      # token1 should still be valid
      assert {:ok, _} = Tokens.verify_session_token(token1)
      
      # token2 should be revoked
      assert {:error, :invalid_token} = Tokens.verify_session_token(token2)
    end
  end

  describe "create_email_token/2" do
    setup do
      %{user: user_fixture()}
    end

    test "creates a token for email confirmation", %{user: user} do
      assert {:ok, token} = Tokens.create_email_token(user, "confirm")
      assert is_binary(token)
      
      # Verify the token is stored in the database
      assert user_token = Repo.get_by(UserToken, user_id: user.id, context: "confirm")
      assert user_token.sent_to == user.email
    end

    test "creates a token for password reset", %{user: user} do
      assert {:ok, token} = Tokens.create_email_token(user, "reset_password")
      assert is_binary(token)
      
      # Verify the token is stored in the database
      assert user_token = Repo.get_by(UserToken, user_id: user.id, context: "reset_password")
      assert user_token.sent_to == user.email
    end

    test "creates a token for email change", %{user: user} do
      assert {:ok, token} = Tokens.create_email_token(user, "change:#{user.email}")
      assert is_binary(token)
      
      # Verify the token is stored in the database
      assert user_token = Repo.get_by(UserToken, user_id: user.id, context: "change:#{user.email}")
      assert user_token.sent_to == user.email
    end
  end

  describe "verify_email_token/2" do
    setup do
      user = user_fixture()
      
      token_confirm = extract_user_token(fn url ->
        Myapp.Accounts.deliver_user_confirmation_instructions(user, url)
      end)
      
      {:ok, token_reset} = Tokens.create_email_token(user, "reset_password")
      
      %{user: user, token_confirm: token_confirm, token_reset: token_reset}
    end

    test "returns the user with a valid confirmation token", %{user: user, token_confirm: token} do
      assert {:ok, returned_user} = Tokens.verify_email_token(token, "confirm")
      assert returned_user.id == user.id
    end

    test "returns the user with a valid reset password token", %{user: user, token_reset: token} do
      assert {:ok, returned_user} = Tokens.verify_email_token(token, "reset_password")
      assert returned_user.id == user.id
    end

    test "does not return the user with an invalid token" do
      assert {:error, :invalid_token} = Tokens.verify_email_token("invalid token", "confirm")
    end

    test "does not return the user with a token for the wrong context", %{token_confirm: token} do
      assert {:error, :invalid_token} = Tokens.verify_email_token(token, "reset_password")
    end
  end

  describe "store_social_token/3" do
    setup do
      user = user_fixture()
      token_data = %{
        "access_token" => "ACCESS_TOKEN",
        "refresh_token" => "REFRESH_TOKEN",
        "expires_in" => 3600,
        "provider_user_id" => "provider123"
      }
      %{user: user, token_data: token_data}
    end

    test "stores social media tokens", %{user: user, token_data: token_data} do
      assert {:ok, stored_data} = Tokens.store_social_token(user.id, :twitter, token_data)
      
      assert stored_data.access_token == token_data["access_token"]
      assert stored_data.refresh_token == token_data["refresh_token"]
      assert stored_data.provider_user_id == token_data["provider_user_id"]
      assert stored_data.expires_at
    end
  end

  describe "get_social_token/2" do
    setup do
      user = user_fixture()
      token_data = %{
        "access_token" => "ACCESS_TOKEN",
        "refresh_token" => "REFRESH_TOKEN",
        "expires_in" => 3600,
        "provider_user_id" => "provider123"
      }
      {:ok, _} = Tokens.store_social_token(user.id, :twitter, token_data)
      %{user: user, token_data: token_data}
    end

    test "retrieves stored social media tokens", %{user: user, token_data: token_data} do
      assert {:ok, retrieved_data} = Tokens.get_social_token(user.id, :twitter)
      
      assert retrieved_data.access_token == token_data["access_token"]
      assert retrieved_data.refresh_token == token_data["refresh_token"]
      assert retrieved_data.provider_user_id == token_data["provider_user_id"]
    end

    test "returns error for non-existent tokens" do
      assert {:error, :not_found} = Tokens.get_social_token(999, :twitter)
    end
  end

  describe "revoke_social_token/2" do
    setup do
      user = user_fixture()
      token_data = %{
        "access_token" => "ACCESS_TOKEN",
        "refresh_token" => "REFRESH_TOKEN",
        "expires_in" => 3600
      }
      {:ok, _} = Tokens.store_social_token(user.id, :twitter, token_data)
      %{user: user}
    end

    test "revokes social media tokens", %{user: user} do
      assert :ok = Tokens.revoke_social_token(user.id, :twitter)
      assert {:error, :not_found} = Tokens.get_social_token(user.id, :twitter)
    end
  end
end
