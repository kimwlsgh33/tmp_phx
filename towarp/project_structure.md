# Project Structure Overview

This document provides an overview of the file and directory structure of the Phoenix/Elixir project.

## Project Overview

This is a Phoenix web application built with Elixir. The application integrates with various social media platforms including YouTube, Instagram, Twitter, and TikTok, providing a unified interface for social media management and content sharing.

## Directory Structure

### Root Level Structure

- **lib/** - Contains the main application code
- **assets/** - Contains frontend assets (CSS, JavaScript)
- **priv/** - Contains database migrations and other resources
- **test/** - Contains test files
- **config/** - Application configuration files
- **docs/** - Project documentation

### Core Application (`lib/myapp/`)

- **accounts/** - User authentication and account management
- **social_auth/** - Authentication modules for social media platforms
- **social_media/** - Integration with social media platforms (YouTube, TikTok, Twitter, Instagram)
- **workers/** - Background job workers
- **mailer/** - Email functionality using Swoosh
- **repo/** - Database interactions and schema definitions

### Web Interface (`lib/myapp_web/`)

- **channels/** - WebSocket channels for real-time features
- **components/** - Reusable UI components
- **controllers/** - HTTP request handlers
- **live/** - LiveView components for interactive features
- **templates/** - HTML templates (HEEX files)
- **router.ex** - Defines application routes
- **endpoint.ex** - Handles HTTP requests

### Frontend Assets (`assets/`)

- **css/** - Stylesheets with TailwindCSS
- **js/** - JavaScript files
  - **hooks/** - LiveView JavaScript hooks
  - **app.js** - Main JavaScript entry point
- **vendor/** - Third-party assets
- **tailwind.config.js** - TailwindCSS configuration

### Database (`priv/repo/migrations/`)

- Contains database migrations
- **seeds.exs** - Database seed data

### Configuration (`config/`)

- **config.exs** - Main application configuration
- **dev.exs** - Development environment configuration
- **prod.exs** - Production environment configuration 
- **runtime.exs** - Runtime configuration for all environments
- **test.exs** - Test environment configuration

### Static Assets (`priv/static/`)

- **assets/** - Compiled CSS and JavaScript
- **images/** - Image assets
- **fonts/** - Font files

### Internationalization (`priv/gettext/`)

- Contains translation files for different languages
- Uses the Gettext library for i18n

## Key Features

1. **Authentication** - Complete user authentication system
1. **Authentication** - Complete user authentication system with:
   - Password-based authentication using Argon2
   - OAuth authentication with Google
2. **Social Media Integration** - Connects to multiple social platforms:
   - YouTube
   - Instagram
   - TikTok
   - Twitter
3. **Real-time Features** - WebSocket channels for real-time communication
4. **LiveView** - Interactive UI components without writing JavaScript
5. **Email Support** - Email functionality using Swoosh mailer
6. **Internationalization** - Multi-language support using Gettext
7. **API Integration** - Various external API connections
## Tech Stack

- **Framework**: Phoenix Framework 1.7.x
- **Language**: Elixir 1.14.x
- **Database**: PostgreSQL
- **Frontend**: 
  - Phoenix LiveView for interactive UIs
  - TailwindCSS for styling
  - HeroIcons for vector icons
- **Authentication**: 
  - Argon2 password hashing
  - Ueberauth for OAuth integration
- **API Integrations**: 
  - YouTube, Instagram, TikTok, Twitter APIs
  - Google API integration
- **Web Server**: Bandit
- **Email**: Swoosh with various adapters
- **Markdown**: Earmark for markdown processing
- **Internationalization**: Gettext
- **JSON**: Jason library
- **Testing**: ExUnit with Floki for HTML parsing
