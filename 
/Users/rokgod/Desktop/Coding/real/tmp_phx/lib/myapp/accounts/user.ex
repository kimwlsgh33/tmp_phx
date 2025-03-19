  
  # Helper to conditionally validate hashed_password existence 
  # only when password hashing is enabled and should have occurred
  defp maybe_require_hashed_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)
    
    require Logger
    email = get_field(changeset, :email)
    
    Logger.debug("Checking if hashed_password is required - Hash enabled: #{hash_password?}, Password present: #{password != nil}, Changeset valid: #{changeset.valid?}")
    
    if hash_password? && password && changeset.valid? do
      Logger.debug("Requiring hashed_password field for user: #{email}")
      
      # Check if hashed_password exists before validation
      hashed_password = get_change(changeset, :hashed_password)
      if hashed_password do
        hash_preview = String.slice(hashed_password, 0, 10) <> "..."
        Logger.debug("Hashed password is present: #{hash_preview}...")
      else
        Logger.warn("Hashed password is missing for user: #{email}")
      end
      
      validate_required(changeset, [:hashed_password], message: "Password hashing failed")
    else
      if !changeset.valid? do
        Logger.debug("Not requiring hashed_password - changeset is invalid for user: #{email}")
      elsif !password do
        Logger.debug("Not requiring hashed_password - no password change for user: #{email}")
      elsif !hash_password? do
        Logger.debug("Not requiring hashed_password - hashing disabled for user: #{email}")
      end
      changeset
    end
  end
  def valid_password?(%Myapp.Accounts.User{hashed_password: hashed_password, email: email} = user, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    require Logger
    
    # Enhanced debug logging with redacted sensitive information
    hash_preview = String.slice(hashed_password, 0, 10) <> "..."
    pass_length = String.length(password)
    
    Logger.debug("Password verification attempt for user: #{email}")
    Logger.debug("Input - Password length: #{pass_length}, Hash prefix: #{hash_preview}")
    
    # Track timing for performance monitoring
    start_time = System.monotonic_time(:millisecond)
    
    # Verify the password
    result = Argon2.verify_pass(password, hashed_password)
    
    # Calculate elapsed time
    elapsed = System.monotonic_time(:millisecond) - start_time
    
    # Log detailed verification results
    Logger.debug("Password verification completed in #{elapsed}ms")
    Logger.debug("Password verification result: #{result} for user: #{email}")
    
    if !result do
      # Additional diagnostics for failed verification
      Logger.debug("Verification failure details - User ID: #{user.id}, Email hash: #{:crypto.hash(:sha256, email) |> Base.encode16()}")
      Logger.debug("Password format valid: #{valid_password_format?(password)}")
    end
    
    result
  end
  def valid_password?(user, password) do
    require Logger
    
    # Log more detailed information about the invalid verification attempt
    user_info = case user do
      %Myapp.Accounts.User{email: email} -> 
        "User exists but hashed_password is nil or invalid. Email: #{email}"
      nil -> 
        "User is nil (not found)"
      _ -> 
        "Unexpected user object: #{inspect(user)}"
    end
    
    password_info = if is_binary(password) do
      "Password provided with length: #{String.length(password)}"
    else
      "Invalid password format: #{inspect(password)}"
    end
    
    Logger.warn("Invalid password verification attempt: #{user_info}")
    Logger.debug("Password details: #{password_info}")
    
    # Use constant-time comparison to prevent timing attacks
    Argon2.no_user_verify()
    false
  end
  # Helper function to validate password format
  defp valid_password_format?(password) when is_binary(password) do
    # Check for common password format requirements
    has_min_length = String.length(password) >= 12
    has_lowercase = String.match?(password, ~r/[a-z]/)
    has_uppercase = String.match?(password, ~r/[A-Z]/)
    has_digit = String.match?(password, ~r/[0-9]/)
    has_special = String.match?(password, ~r/[^a-zA-Z0-9]/)
    
    # Return true if the password meets our basic requirements
    has_min_length && (has_lowercase || has_uppercase) && (has_digit || has_special)
  end
  
  defp valid_password_format?(_), do: false
end

