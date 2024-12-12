# REST API Documentation

This document outlines the REST API endpoints available in our Phoenix application.

## API Overview

### Base URL
```
https://api.example.com/v1
```

### Authentication
All API requests require authentication using Bearer tokens:
```
Authorization: Bearer <token>
```

## Endpoints

### Resource Endpoints

#### GET /api/resource
Retrieve a list of resources

**Parameters:**
- `page`: Page number (default: 1)
- `per_page`: Items per page (default: 20)

**Response:**
```json
{
  "data": [...],
  "meta": {
    "total": 100,
    "page": 1,
    "per_page": 20
  }
}
```

#### POST /api/resource
Create a new resource

**Request Body:**
```json
{
  "resource": {
    "name": "string",
    "description": "string"
  }
}
```

## Error Handling

### Error Responses
```json
{
  "errors": {
    "detail": "Error message",
    "status": 400
  }
}
```

### Status Codes
- 200: Success
- 201: Created
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 422: Unprocessable Entity
- 500: Internal Server Error
