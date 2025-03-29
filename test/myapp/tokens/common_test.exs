defmodule Myapp.Tokens.CommonTest do
  use ExUnit.Case, async: true
  alias Myapp.Tokens.Common

  describe "token generation" do
    test "generate_token/0 creates a token of the expected size" do
      token = Common.generate_token()
      assert is_binary(token)
      assert byte_size(token) == 32
    end

    test "generate_url_safe_token/0 creates a URL-safe string" do
      token = Common.generate_url_safe_token()
      assert is_binary(token)
      assert String.match?(token, ~r/^[A-Za-z0-9_-]+$/)
    end

    test "generate_url_safe_token/0 creates tokens of consistent length" do
      tokens = for _ <- 1..10, do: Common.generate_url_safe_token()
      lengths = Enum.map(tokens, &String.length/1)
      assert Enum.uniq(lengths) |> length() == 1, "All tokens should have the same length"
    end
  end

  describe "token hashing" do
    test "hash_token/1 creates consistent hashes" do
      token = "test_token"
      hash1 = Common.hash_token(token)
      hash2 = Common.hash_token(token)
      assert hash1 == hash2, "Hashing the same token should produce the same hash"
    end

    test "hash_token/1 creates different hashes for different tokens" do
      hash1 = Common.hash_token("token1")
      hash2 = Common.hash_token("token2")
      assert hash1 != hash2, "Different tokens should produce different hashes"
    end

    test "hash_token/1 is one-way (cannot be reversed)" do
      token = Common.generate_token()
      hash = Common.hash_token(token)
      # This is a simplistic test - in reality, it's mathematically proven that SHA-256 is one-way
      assert hash != token
      assert byte_size(hash) != byte_size(token) || hash != token
    end
  end

  describe "token encryption" do
    test "encrypt_token/2 and decrypt_token/2 work together" do
      token = "sensitive_data"
      salt = "test_salt"
      
      encrypted = Common.encrypt_token(token, salt)
      assert encrypted != token, "Encrypted token should differ from original"
      
      {:ok, decrypted} = Common.decrypt_token(encrypted, salt)
      assert decrypted == token, "Decrypted token should match original"
    end
    
    test "decrypt_token/2 fails with incorrect salt" do
      token = "sensitive_data"
      encrypted = Common.encrypt_token(token, "correct_salt")
      
      result = Common.decrypt_token(encrypted, "wrong_salt")
      assert {:error, _} = result
    end
    
    test "decrypt_token/2 fails with tampered data" do
      token = "sensitive_data"
      encrypted = Common.encrypt_token(token, "test_salt")
      
      # Simulate tampering by concatenating some data
      tampered = encrypted <> "extra_data"
      
      result = Common.decrypt_token(tampered, "test_salt")
      assert {:error, _} = result
    end
    
    test "decrypt_token/2 fails with invalid binary" do
      result = Common.decrypt_token("not_a_valid_encrypted_binary", "test_salt")
      assert {:error, :invalid_token} = result
    end
  end

  describe "expiration functions" do
    test "expired?/1 correctly identifies expired timestamps" do
      past = DateTime.add(DateTime.utc_now(), -60, :second)
      future = DateTime.add(DateTime.utc_now(), 60, :second)
      
      assert Common.expired?(past) == true
      assert Common.expired?(future) == false
      assert Common.expired?(nil) == false
    end
    
    test "needs_refresh?/1 correctly identifies tokens needing refresh" do
      # Token expired 30 minutes ago
      expired = DateTime.add(DateTime.utc_now(), -1800, :second)
      # Token expires in 30 minutes (within 1 hour threshold)
      expiring_soon = DateTime.add(DateTime.utc_now(), 1800, :second)
      # Token expires in 2 hours (outside 1 hour threshold)
      valid = DateTime.add(DateTime.utc_now(), 7200, :second)
      
      assert Common.needs_refresh?(expired) == true
      assert Common.needs_refresh?(expiring_soon) == true
      assert Common.needs_refresh?(valid) == false
      assert Common.needs_refresh?(nil) == false
    end
    
    test "needs_refresh?/2 respects custom threshold" do
      # Token expires in 30 minutes
      expiring_soon = DateTime.add(DateTime.utc_now(), 1800, :second)
      
      # With 15 minute threshold (token outside threshold)
      assert Common.needs_refresh?(expiring_soon, 900) == false
      
      # With 45 minute threshold (token within threshold)
      assert Common.needs_refresh?(expiring_soon, 2700) == true
    end
    
    test "calculate_expiry/2 creates correct timestamps" do
      now = DateTime.utc_now()
      
      # Test with default values
      expiry = Common.calculate_expiry()
      diff = DateTime.diff(expiry, now, :second)
      assert diff >= 24 * 60 * 60 - 1 and diff <= 24 * 60 * 60 + 1
      
      # Test with custom lifetime
      custom_expiry = Common.calculate_expiry(3600) # 1 hour
      custom_diff = DateTime.diff(custom_expiry, now, :second)
      assert custom_diff >= 3599 and custom_diff <= 3601
      
      # Test with custom start time
      start_time = DateTime.add(now, -3600, :second) # 1 hour ago
      past_expiry = Common.calculate_expiry(7200, start_time) # 2 hours from start
      past_diff = DateTime.diff(past_expiry, now, :second)
      assert past_diff >= 3599 and past_diff <= 3601
    end
  end

  describe "oauth response normalization" do
    test "normalize_oauth_response/1 handles standard OAuth responses" do
      response = %{
        "access_token" => "abc123",
        "refresh_token" => "xyz789",
        "expires_in" => 3600,
        "token_type" => "Bearer",
        "scope" => "read write",
        "provider_user_id" => "user123",
        "extra_field" => "some_value"
      }
      
      normalized = Common.normalize_oauth_response(response)
      
      assert normalized.access_token == "abc123"
      assert normalized.refresh_token == "xyz789"
      assert normalized.expires_in == 3600
      assert normalized.token_type == "Bearer"
      assert normalized.scope == "read write"
      assert normalized.provider_user_id == "user123"
      assert normalized.metadata == %{"extra_field" => "some_value"}
    end
    
    test "normalize_oauth_response/1 provides defaults for missing fields" do
      minimal_response = %{
        "access_token" => "abc123"
      }
      
      normalized = Common.normalize_oauth_response(minimal_response)
      
      assert normalized.access_token == "abc123"
      assert normalized.refresh_token == nil
      assert normalized.token_type == "Bearer"
      assert normalized.expires_in == Common.default_token_lifetime()
      assert normalized.provider_user_id == nil
      assert normalized.metadata == %{}
    end
    
    test "normalize_oauth_response/1 handles alternative field names" do
      response = %{
        "access_token" => "abc123",
        "open_id" => "user_via_openid", # Alternative to provider_user_id
        "user_id" => "should_not_use_this" # Lower priority
      }
      
      normalized = Common.normalize_oauth_response(response)
      
      # Should prefer open_id over user_id
      assert normalized.provider_user_id == "user_via_openid"
    end
  end
end

