defmodule Myapp.Tokens.CacheTest do
  use ExUnit.Case, async: false
  
  alias Myapp.Tokens.Cache
  
  setup do
    # Start the cache for testing
    start_supervised!(Myapp.Tokens.Cache)
    # Clear the cache before each test
    Cache.clear_all()
    :ok
  end
  
  describe "session token cache" do
    test "put_session_token/2 and get_session_token/1" do
      token = "test_session_token"
      user_id = 123
      
      assert :ok = Cache.put_session_token(token, user_id)
      assert {:ok, ^user_id} = Cache.get_session_token(token)
    end
    
    test "get_session_token/1 returns error for non-existent token" do
      assert {:error, :not_found} = Cache.get_session_token("non_existent_token")
    end
    
    test "delete_session_token/1 removes token from cache" do
      token = "test_session_token"
      user_id = 123
      
      :ok = Cache.put_session_token(token, user_id)
      assert {:ok, ^user_id} = Cache.get_session_token(token)
      
      :ok = Cache.delete_session_token(token)
      assert {:error, :not_found} = Cache.get_session_token(token)
    end
    
    test "delete_user_session_tokens/2 removes all tokens for a user" do
      user_id = 123
      token1 = "token1"
      token2 = "token2"
      token3 = "token3"
      
      :ok = Cache.put_session_token(token1, user_id)
      :ok = Cache.put_session_token(token2, user_id)
      :ok = Cache.put_session_token(token3, 456) # Different user
      
      :ok = Cache.delete_user_session_tokens(user_id)
      
      assert {:error, :not_found} = Cache.get_session_token(token1)
      assert {:error, :not_found} = Cache.get_session_token(token2)
      assert {:ok, 456} = Cache.get_session_token(token3) # Should still exist
    end
    
    test "delete_user_session_tokens/2 with except option" do
      user_id = 123
      token1 = "token1"
      token2 = "token2"
      
      :ok = Cache.put_session_token(token1, user_id)
      :ok = Cache.put_session_token(token2, user_id)
      
      :ok = Cache.delete_user_session_tokens(user_id, except: token1)
      
      assert {:ok, ^user_id} = Cache.get_session_token(token1) # Should still exist
      assert {:error, :not_found} = Cache.get_session_token(token2)
    end
  end
  
  describe "social token cache" do
    test "put_social_token/3 and get_social_token/2" do
      user_id = 123
      provider = :twitter
      token_data = %{
        access_token: "access_token",
        refresh_token: "refresh_token",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }
      
      assert :ok = Cache.put_social_token(user_id, provider, token_data)
      assert {:ok, ^token_data} = Cache.get_social_token(user_id, provider)
    end
    
    test "get_social_token/2 returns error for non-existent token" do
      assert {:error, :not_found} = Cache.get_social_token(999, :twitter)
    end
    
    test "get_social_token/2 returns error for expired token" do
      user_id = 123
      provider = :twitter
      # Create token that expired 1 hour ago
      token_data = %{
        access_token: "access_token",
        refresh_token: "refresh_token",
        expires_at: DateTime.add(DateTime.utc_now(), -3600, :second)
      }
      
      :ok = Cache.put_social_token(user_id, provider, token_data)
      assert {:error, :not_found} = Cache.get_social_token(user_id, provider)
    end
    
    test "delete_social_token/2 removes token from cache" do
      user_id = 123
      provider = :twitter
      token_data = %{
        access_token: "access_token",
        refresh_token: "refresh_token"
      }
      
      :ok = Cache.put_social_token(user_id, provider, token_data)
      assert {:ok, _} = Cache.get_social_token(user_id, provider)
      
      :ok = Cache.delete_social_token(user_id, provider)
      assert {:error, :not_found} = Cache.get_social_token(user_id, provider)
    end
  end
  
  describe "clear_all/0" do
    test "removes all cached tokens" do
      # Add session token
      :ok = Cache.put_session_token("session_token", 123)
      
      # Add social token
      :ok = Cache.put_social_token(123, :twitter, %{access_token: "access_token"})
      
      # Clear all
      :ok = Cache.clear_all()
      
      # Verify all tokens are gone
      assert {:error, :not_found} = Cache.get_session_token("session_token")
      assert {:error, :not_found} = Cache.get_social_token(123, :twitter)
    end
  end
  
  describe "cleanup_expired_tokens" do
    test "automatically removes expired social tokens" do
      user_id = 123
      provider = :twitter
      # Create token that expires in 1 second
      token_data = %{
        access_token: "access_token",
        refresh_token: "refresh_token",
        expires_at: DateTime.add(DateTime.utc_now(), 1, :second)
      }
      
      :ok = Cache.put_social_token(user_id, provider, token_data)
      assert {:ok, _} = Cache.get_social_token(user_id, provider)
      
      # Wait for token to expire and cleanup to run
      # This is a bit of a hack, but it's the simplest way to test this
      :timer.sleep(1500)
      
      # Send cleanup message directly to force immediate cleanup
      send(Cache, :cleanup)
      :timer.sleep(100) # Give the process time to handle the message
      
      # Token should be gone
      assert {:error, :not_found} = Cache.get_social_token(user_id, provider)
    end
  end
end
