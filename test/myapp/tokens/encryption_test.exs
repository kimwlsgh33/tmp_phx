defmodule Myapp.Tokens.EncryptionTest do
  use ExUnit.Case, async: true
  
  alias Myapp.Tokens.Encryption
  
  describe "encrypt/2 and decrypt/3" do
    test "encrypts and decrypts a token" do
      token = "my_secret_token"
      salt = "test_salt"
      
      encrypted = Encryption.encrypt(token, salt)
      assert encrypted != token
      
      {:ok, decrypted} = Encryption.decrypt(encrypted, salt)
      assert decrypted == token
    end
    
    test "decrypt fails with wrong salt" do
      token = "my_secret_token"
      encrypted = Encryption.encrypt(token, "correct_salt")
      
      result = Encryption.decrypt(encrypted, "wrong_salt")
      assert {:error, _} = result
    end
    
    test "decrypt fails with expired token" do
      token = "my_secret_token"
      salt = "test_salt"
      max_age = 0 # Immediately expired
      
      encrypted = Encryption.encrypt(token, salt)
      
      # Wait a moment to ensure the token is expired
      :timer.sleep(10)
      
      result = Encryption.decrypt(encrypted, salt, max_age)
      assert {:error, _} = result
    end
  end
  
  describe "hash/1" do
    test "creates consistent hashes" do
      token = "my_token"
      
      hash1 = Encryption.hash(token)
      hash2 = Encryption.hash(token)
      
      assert hash1 == hash2
      assert is_binary(hash1)
      assert byte_size(hash1) == 32 # SHA-256 produces 32-byte hashes
    end
    
    test "creates different hashes for different tokens" do
      hash1 = Encryption.hash("token1")
      hash2 = Encryption.hash("token2")
      
      assert hash1 != hash2
    end
  end
  
  describe "generate_token/1" do
    test "generates random tokens of specified size" do
      token1 = Encryption.generate_token()
      token2 = Encryption.generate_token()
      
      assert token1 != token2
      assert byte_size(token1) == 32 # Default size
      
      custom_token = Encryption.generate_token(16)
      assert byte_size(custom_token) == 16
    end
  end
  
  describe "generate_url_token/1" do
    test "generates URL-safe tokens" do
      token = Encryption.generate_url_token()
      
      assert is_binary(token)
      assert String.match?(token, ~r/^[A-Za-z0-9_-]+$/)
    end
    
    test "generates tokens of consistent format" do
      tokens = for _ <- 1..10, do: Encryption.generate_url_token()
      
      # All tokens should be URL-safe
      for token <- tokens do
        assert String.match?(token, ~r/^[A-Za-z0-9_-]+$/)
      end
      
      # All tokens should have the same length
      lengths = Enum.map(tokens, &String.length/1)
      assert Enum.uniq(lengths) |> length() == 1
    end
    
    test "generates tokens of specified size" do
      # Default size (32 bytes) will result in a longer base64 string
      default_token = Encryption.generate_url_token()
      
      # 16 bytes will result in a shorter base64 string
      small_token = Encryption.generate_url_token(16)
      
      assert String.length(default_token) > String.length(small_token)
    end
  end
end
