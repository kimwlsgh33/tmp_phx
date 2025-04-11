# Token System Usage Guide

This document provides guidance on how to use the new unified token system in your application.

## Overview

The token system provides a consistent API for all token operations, including:

- User authentication tokens (sessions, API)
- Social media platform tokens
- Email verification and password reset tokens

## User Authentication Tokens

### Creating a Session Token

```elixir
# Create a new session token for a user
{:ok, token, metadata} = Myapp.Tokens.create_session_token(user)

# The token can be used for authentication
# The metadata contains additional information about the token
```

### Verifying a Session Token

```elixir
# Verify a session token
case Myapp.Tokens.verify_session_token(token) do
  {:ok, user} -> 
    # Token is valid, user is authenticated
    # Do something with the user
  
  {:error, reason} ->
    # Token is invalid or expired
    # Handle the error
end
```

### Revoking a Session Token

```elixir
# Revoke a session token (e.g., when a user logs out)
:ok = Myapp.Tokens.revoke_session_token(token)
```

### Revoking All Session Tokens Except Current

```elixir
# Revoke all session tokens for a user except the current one
# Useful when a user logs in and you want to invalidate all other sessions
:ok = Myapp.Tokens.revoke_other_session_tokens(user, current_token)
```

## Email Tokens

### Creating an Email Token

```elixir
# Create a token for email confirmation
{:ok, token} = Myapp.Tokens.create_email_token(user, "confirm")

# Create a token for password reset
{:ok, token} = Myapp.Tokens.create_email_token(user, "reset_password")

# Create a token for email change
{:ok, token} = Myapp.Tokens.create_email_token(user, "change:#{user.email}")
```

### Verifying an Email Token

```elixir
# Verify an email confirmation token
case Myapp.Tokens.verify_email_token(token, "confirm") do
  {:ok, user} -> 
    # Token is valid, confirm the user's email
  
  {:error, reason} ->
    # Token is invalid or expired
    # Handle the error
end

# Verify a password reset token
case Myapp.Tokens.verify_email_token(token, "reset_password") do
  {:ok, user} -> 
    # Token is valid, allow password reset
  
  {:error, reason} ->
    # Token is invalid or expired
    # Handle the error
end
```

## Social Media Tokens

### Storing Social Media Tokens

```elixir
# Store tokens for a social media platform
token_data = %{
  "access_token" => "ACCESS_TOKEN",
  "refresh_token" => "REFRESH_TOKEN",
  "expires_in" => 3600,
  "provider_user_id" => "provider123"
}

{:ok, stored_data} = Myapp.Tokens.store_social_token(user_id, :twitter, token_data)
```

### Getting Social Media Tokens

```elixir
# Get tokens for a social media platform
case Myapp.Tokens.get_social_token(user_id, :twitter) do
  {:ok, token_data} -> 
    # Tokens are available
    # token_data contains access_token, refresh_token, expires_at, etc.
    
    # Use the tokens to make API calls
    access_token = token_data.access_token
    
  {:error, :not_found} ->
    # User has not connected this platform
    
  {:error, reason} ->
    # Some other error occurred
    # Handle the error
end
```

### Refreshing Social Media Tokens

```elixir
# Refresh tokens for a social media platform
case Myapp.Tokens.refresh_social_token(user_id, :twitter) do
  {:ok, new_token_data} -> 
    # Tokens have been refreshed
    # new_token_data contains the new access_token, refresh_token, etc.
    
  {:error, reason} ->
    # Failed to refresh tokens
    # Handle the error
end
```

### Revoking Social Media Tokens

```elixir
# Revoke tokens for a social media platform
:ok = Myapp.Tokens.revoke_social_token(user_id, :twitter)
```

## Best Practices

1. **Always Use the Tokens Module**: Use `Myapp.Tokens` for all token operations instead of directly accessing the underlying modules.

2. **Handle Token Errors**: Always handle potential errors when verifying tokens.

3. **Revoke Tokens When No Longer Needed**: To maintain security, revoke tokens when they are no longer needed.

4. **Use Token Caching Wisely**: The token system includes caching for performance, but be aware of potential cache inconsistencies in a distributed environment.

5. **Refresh Tokens Automatically**: The token system will automatically attempt to refresh expired social media tokens when possible.

## Migration from Old Token Systems

If you're migrating from the old token systems, here are some equivalences:

### From UserToken

```elixir
# Old way
token = Accounts.generate_user_session_token(user)
user = Accounts.get_user_by_session_token(token)
Accounts.delete_user_session_token(token)

# New way
{:ok, token, _} = Tokens.create_session_token(user)
{:ok, user} = Tokens.verify_session_token(token)
:ok = Tokens.revoke_session_token(token)
```

### From SocialMediaToken

```elixir
# Old way
SocialMediaToken.store_tokens(user_id, :twitter, token_data)
SocialMediaToken.get_active_tokens(user_id, :twitter)
SocialMediaToken.revoke_active_tokens(user_id, :twitter)

# New way
Tokens.store_social_token(user_id, :twitter, token_data)
Tokens.get_social_token(user_id, :twitter)
Tokens.revoke_social_token(user_id, :twitter)
```

## Troubleshooting

### Token Verification Fails

If token verification fails, check:

1. The token is being passed correctly
2. The token has not expired
3. The token has not been revoked
4. You're using the correct context for email tokens

### Social Media Token Refresh Fails

If social media token refresh fails, check:

1. The refresh token is valid
2. The provider's API is available
3. The user has not revoked access to your application

### Performance Issues

If you're experiencing performance issues:

1. Ensure the token cache is properly configured
2. Monitor cache hit/miss rates
3. Consider adjusting cache settings based on your application's needs
