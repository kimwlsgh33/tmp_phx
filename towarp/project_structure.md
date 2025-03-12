# Project Structure Overview

This document provides an overview of the file and directory structure of the Phoenix/Elixir project.

## Project Overview

This is a Phoenix web application built with Elixir. It appears to be a social media management platform that integrates with various services including YouTube, Instagram, Twitter, and TikTok.

## Directory Structure

### Root Level Structure

- **lib/** - Contains the main application code
- **assets/** - Contains frontend assets (CSS, JavaScript)
- **priv/** - Contains database migrations and other resources
- **test/** - Contains test files

### Core Application (`lib/myapp/`)

- **accounts/** - User authentication and account management
- **social_auth/** - Authentication modules for social media platforms
- **social_media/** - Integration with social media platforms (YouTube, TikTok, Twitter, Instagram)
- **workers/** - Background job workers

### Web Interface (`lib/myapp_web/`)

- **channels/** - WebSocket channels for real-time features
- **components/** - Reusable UI components
- **controllers/** - HTTP request handlers
- **live/** - LiveView components for interactive features
- **templates/** - HTML templates (HEEX files)

### Frontend Assets (`assets/`)

- **css/** - Stylesheets
- **js/** - JavaScript files
  - **hooks/** - LiveView JavaScript hooks
- **vendor/** - Third-party assets

### Database (`priv/repo/migrations/`)

- Contains database migrations

## Key Features

1. **Authentication** - Complete user authentication system
2. **Social Media Integration** - Connects to multiple social platforms:
   - YouTube
   - Instagram
   - TikTok
   - Twitter
3. **Real-time Features** - WebSocket channels for real-time communication
4. **LiveView** - Interactive UI components without writing JavaScript

## Tech Stack

- **Framework**: Phoenix Framework
- **Language**: Elixir
- **Database**: PostgreSQL
- **Frontend**: Phoenix LiveView, TailwindCSS
- **Authentication**: Argon2 password hashing
- **API Integrations**: Various social media platforms
