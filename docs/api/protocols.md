# API Protocols

This document outlines the protocols and standards used in our Phoenix application's APIs.

## REST Protocols

### Request Format
```
GET /api/v1/resource HTTP/1.1
Host: api.example.com
Authorization: Bearer <token>
Content-Type: application/json
```

### Response Format
```json
{
  "data": {},
  "meta": {
    "page": 1,
    "total": 100
  }
}
```

## GraphQL Protocols

### Query Format
```graphql
query {
  resource(id: "123") {
    id
    name
    attributes
  }
}
```

### Mutation Format
```graphql
mutation {
  createResource(input: {
    name: "New Resource"
  }) {
    id
    name
  }
}
```

## WebSocket Protocols

### Channel Format
```javascript
channel.push("event", {
  type: "message",
  payload: {}
})
```

### PubSub Format
```elixir
Phoenix.PubSub.broadcast(MyApp.PubSub, "topic", {:event, payload})
```

## Error Protocols

### REST Errors
```json
{
  "errors": [{
    "status": "400",
    "title": "Bad Request",
    "detail": "Invalid parameters"
  }]
}
```

### GraphQL Errors
```json
{
  "errors": [{
    "message": "Not found",
    "path": ["query", "resource"],
    "extensions": {
      "code": "NOT_FOUND"
    }
  }]
}
```

## Security Protocols

### Authentication
- Bearer token
- API keys
- OAuth2

### Authorization
- Role-based access
- Scope-based permissions
- Resource ownership
