# GraphQL API Documentation

This document outlines the GraphQL API schema and operations available in our Phoenix application.

## Schema

### Types

```graphql
type User {
  id: ID!
  email: String!
  name: String
  posts: [Post!]!
}

type Post {
  id: ID!
  title: String!
  body: String!
  author: User!
}
```

## Queries

### Get User
```graphql
query GetUser($id: ID!) {
  user(id: $id) {
    id
    email
    name
    posts {
      id
      title
    }
  }
}
```

### List Posts
```graphql
query ListPosts($page: Int, $perPage: Int) {
  posts(page: $page, perPage: $perPage) {
    id
    title
    body
    author {
      name
    }
  }
}
```

## Mutations

### Create Post
```graphql
mutation CreatePost($input: PostInput!) {
  createPost(input: $input) {
    id
    title
    body
  }
}
```

## Error Handling

### Error Format
```json
{
  "errors": [
    {
      "message": "Error message",
      "path": ["query", "field"],
      "extensions": {
        "code": "ERROR_CODE"
      }
    }
  ]
}
```

## Authentication

GraphQL endpoints require authentication via Bearer token in the Authorization header.
