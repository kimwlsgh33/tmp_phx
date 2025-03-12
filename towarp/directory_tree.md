# Project Directory Tree

This document provides a more detailed view of the file structure in a tree-like format.

## Main Directory Structure

```
.
├── assets/                    # Frontend assets
│   ├── css/                   # Stylesheets
│   ├── js/                    # JavaScript files
│   │   └── hooks/             # LiveView hooks
│   └── vendor/                # Third-party assets
│
├── lib/                       # Main application code
│   ├── myapp/                 # Core application logic
│   │   ├── accounts/          # User accounts and authentication
│   │   │   ├── user.ex
│   │   │   ├── user_notifier.ex
│   │   │   └── user_token.ex
│   │   ├── social_auth/       # Social media authentication
│   │   │   ├── instagram.ex
│   │   │   ├── tiktok.ex
│   │   │   ├── twitter.ex
│   │   │   └── youtube.ex
│   │   ├── social_media/      # Social media integration
│   │   │   ├── tiktok.ex
│   │   │   ├── twitter.ex
│   │   │   └── youtube.ex
│   │   └── workers/           # Background workers
│   │
│   └── myapp_web/             # Web interface
│       ├── channels/          # WebSocket channels
│       │   ├── chat_channel.ex
│       │   ├── user_socket.ex
│       │   └── youtube_channel.ex
│       ├── components/        # UI components
│       │   ├── core_components.ex
│       │   ├── docs/          # Documentation components
│       │   └── layouts/       # Page layouts
│       ├── controllers/       # HTTP controllers
│       │   ├── company_controller.ex
│       │   ├── docs_controller.ex
│       │   ├── instagram_controller.ex
│       │   ├── tiktok_controller.ex
│       │   ├── twitter_controller.ex
│       │   ├── user_session_controller.ex
│       │   └── youtube_controller.ex
│       └── live/              # LiveView modules
│           ├── counter_live/
│           ├── file_live/
│           ├── user_confirmation_live.ex
│           ├── user_login_live.ex
│           └── youtube_search_live.ex
│
├── priv/                      # Private application data
│   └── repo/                  # Database related
│       └── migrations/        # Database migrations
│
└── test/                      # Test files
    ├── myapp/                 # Core application tests
    │   └── accounts_test.exs
    └── myapp_web/             # Web interface tests
        ├── controllers/
        ├── live/              # LiveView tests
        └── user_auth_test.exs
```

## Key Files

### Core Configuration Files
- `mix.exs` - Project dependencies and configuration
- `lib/myapp/application.ex` - Application supervision tree
- `lib/myapp_web/endpoint.ex` - Web endpoint configuration
- `lib/myapp_web/router.ex` - HTTP routing

### Authentication
- `lib/myapp/accounts/user.ex` - User schema
- `lib/myapp_web/user_auth.ex` - Authentication plug

### Social Media Integration
- `lib/myapp/social_auth/` - OAuth authentication for social platforms
- `lib/myapp/social_media/` - API integrations for social platforms

### Key Web Components
- `lib/myapp_web/components/layouts/` - Page layouts
- `lib/myapp_web/components/core_components.ex` - Reusable UI components
