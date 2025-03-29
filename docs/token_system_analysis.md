# Token System Analysis and Refactoring Plan

## Current State

Our codebase currently has four separate token-related modules:

1. **`UserToken`** - For user authentication, session management, and account operations
2. **`PlatformToken`** - For storing social media platform access tokens in plaintext
3. **`SocialMediaToken`** - For storing encrypted social media platform tokens with extended functionality
4. **`TokenStore`** - For in-memory ETS-based token storage (currently Twitter-focused)

## Code Duplication Analysis

### PlatformToken vs. SocialMediaToken

These modules have significant functional overlap but different implementations:

| Feature | PlatformToken | SocialMediaToken |
|---------|---------------|-----------------|
| **Storage Type** | Database | Database |
| **Token Security** | Plaintext | Encrypted |
| **Fields Tracked** | Basic (platform, tokens, expiry) | Extended (+ provider user ID, metadata, revocation) |
| **Token Lifecycle** | Basic expiry check | Full lifecycle (creation, refresh, expiry, revocation) |
| **Provider Support** | String-based enum | Atom-based enum |
| **Schema Design** | Simple schema | Comprehensive schema with virtual fields |
| **Security Features** | None | Encryption using Phoenix.Token |
| **Migration Path** | None defined | Has revocation for transition |

### Encryption Logic Duplication

SocialMediaToken implements its own encryption logic, while similar encryption could be useful in UserToken and other security contexts.

### Token Validity Logic

Multiple implementations of token expiration/validity checking exist:
- `PlatformToken.expired?/1`
- `SocialMediaToken.needs_refresh?/1` and `refresh_token_valid?/1` 
- `UserToken` validity checking via queries

### Token Storage Approaches

The codebase uses three different token storage approaches:
- Database storage with plaintext tokens (PlatformToken)
- Database storage with encrypted tokens (SocialMediaToken)
- In-memory ETS storage (TokenStore)

## Refactoring Recommendations

### 1. Consolidate Social Media Token Functionality

SocialMediaToken appears to be a more secure, feature-complete replacement for PlatformToken. We recommend:

- Deprecate PlatformToken and migrate to SocialMediaToken
- Create a migration path for existing PlatformToken records
- Update all code that uses PlatformToken to use SocialMediaToken instead

### 2. Extract Common Token Functionality

Create a shared Token functionality module:

```elixir
defmodule Myapp.Tokens.Common do
  @moduledoc """
  Common token functionality shared across token systems.
  """
  
  # Encryption/decryption helpers
  def encrypt_token(token, salt) do
    # Implement common encryption
  end
  
  def decrypt_token(encrypted, salt) do
    # Implement common decryption
  end
  
  # Expiration helpers
  def expired?(expires_at) do
    # Common expiration logic
  end
  
  def calculate_expiry(expires_in, from \\ nil) do
    # Common expiry calculation
  end
end
```

### 3. Standardize Token Operations

Establish consistent patterns for token management:

- Creation: Always use a `create_token` or `store_token` function naming
- Validation: Consistent `valid?` or `expired?` helpers
- Refresh: Standard `refresh_token` function with common parameters
- Revocation: Consistent `revoke_token` function

### 4. Clarify ETS vs. Database Usage

Establish clear guidelines for when to use each storage approach:

- **Database (SocialMediaToken)**: For persistent, secure token storage
- **ETS (TokenStore)**: As a performance cache for frequently accessed tokens
- Add helper functions to synchronize between the two when appropriate

### 5. Security Improvements

- Add encryption to all sensitive token storage
- Ensure proper token revocation on security events
- Implement consistent token refresh policies
- Add audit logging for token operations

## Migration Strategy

1. Create migration script to move data from PlatformToken to SocialMediaToken
2. Update all code references to use SocialMediaToken instead of PlatformToken
3. Implement the Common token module and gradually refactor to use it
4. Add deprecation warnings to PlatformToken
5. Once all functionality is migrated, remove PlatformToken in a future release

## Timeline and Impact

This refactoring can be implemented in phases:

1. **Phase 1 (Immediate)**: Documentation updates and common module creation
2. **Phase 2 (Short-term)**: Migration path and deprecation warnings
3. **Phase 3 (Medium-term)**: Code updates to use new patterns
4. **Phase 4 (Long-term)**: Complete removal of deprecated modules

The main impact will be on code using the PlatformToken module directly, which will need to be updated to use SocialMediaToken.

