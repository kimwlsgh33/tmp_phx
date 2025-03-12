# Project Directory Tree

This document provides a detailed view of the project's file structure in a tree-like format.

## Main Directory Structure

```
.
├── assets/                     # Frontend assets
│   ├── css/                    # Stylesheets
│   │   └── app.css
│   ├── js/                     # JavaScript files
│   │   ├── app.js
│   │   └── hooks/              # LiveView hooks
│   └── tailwind.config.js      # Tailwind configuration
│
├── config/                     # Application configuration
│   ├── config.exs
│   ├── dev.exs
│   ├── prod.exs
│   ├── runtime.exs
│   └── test.exs
│
├── lib/                        # Main application code
│   ├── tmp_phx/                # Core application logic
│   │   ├── application.ex
│   │   ├── mailer.ex
│   │   └── repo.ex
│   └── tmp_phx_web/            # Web interface
│       ├── components/         # UI components
│       │   ├── core_components.ex
│       │   └── layouts/        # Page layouts
│       │       ├── app.html.heex
│       │       └── root.html.heex
│       ├── controllers/        # HTTP controllers
│       │   ├── error_html.ex
│       │   ├── error_json.ex
│       │   ├── page_controller.ex
│       │   └── page_html/
│       │       └── home.html.heex
│       ├── endpoint.ex
│       ├── gettext.ex
│       ├── router.ex
│       └── telemetry.ex
│
├── priv/                       # Private application data
│   ├── gettext/                # Internationalization
│   │   └── en/
│   │       └── LC_MESSAGES/
│   │           ├── default.po
│   │           └── errors.po
│   ├── repo/                   # Database related
│   │   └── migrations/         # Database migrations
│   └── static/                 # Static assets
│       ├── assets/
│       │   ├── app.css
│       │   └── app.js
│       ├── favicon.ico
│       ├── images/
│       │   └── phoenix.png
│       └── robots.txt
│
├── test/                       # Test files
│   ├── support/                # Test support modules
│   │   ├── conn_case.ex
│   │   ├── data_case.ex
│   │   └── fixtures/
│   ├── tmp_phx/                # Core application tests
│   └── tmp_phx_web/            # Web interface tests
│       ├── controllers/
│       │   └── page_controller_test.exs
│       └── error_html_test.exs
│
└── towarp/                     # Project documentation
    └── directory_tree.md
```

## Key Files

### Root Configuration Files
- `.formatter.exs` - Code formatter configuration
- `.gitignore` - Git ignore patterns
- `mix.exs` - Project dependencies and configuration
- `mix.lock` - Locked dependency versions

### Core Configuration Files
- `config/config.exs` - Base configuration
- `config/dev.exs` - Development environment configuration
- `config/prod.exs` - Production environment configuration
- `lib/tmp_phx/application.ex` - Application supervision tree
- `lib/tmp_phx_web/endpoint.ex` - Web endpoint configuration
- `lib/tmp_phx_web/router.ex` - HTTP routing

### Web Components
- `lib/tmp_phx_web/components/layouts/` - Page layouts
- `lib/tmp_phx_web/components/core_components.ex` - Reusable UI components
- `lib/tmp_phx_web/controllers/page_controller.ex` - Main page controller
