# API Authentication

This document describes the authentication mechanisms used in our Phoenix application's API.

## Authentication Methods

### Bearer Token
The primary authentication method using JWT tokens.

#### Token Format
```
Authorization: Bearer <token>
```

#### Token Generation
```elixir
MyApp.Token.generate(user)
```

### API Keys
For service-to-service communication.

## Implementation

### Guardian Configuration
We use Guardian for JWT token management:

```elixir
config :my_app, MyApp.Guardian,
  issuer: "my_app",
  secret_key: System.get_env("GUARDIAN_SECRET")
```

### Token Lifecycle

1. Generation
2. Validation
3. Refresh
4. Revocation

## Security Considerations

### Token Storage
- Secure storage guidelines
- Token expiration
- Refresh token handling

### CORS Configuration
```elixir
plug CORSPlug,
  origin: ["https://allowed-origin.com"]
```

## Error Handling

### Common Authentication Errors
- Invalid token
- Expired token
- Missing token
- Insufficient permissions

## Testing

### Authentication in Tests
```elixir
# Example test helper
def authenticate(conn, user) do
  token = MyApp.Token.generate(user)
  put_req_header(conn, "authorization", "Bearer #{token}")
end
```
