# Project File Structure

This document outlines the current file structure of the Phoenix Documentation project.

## Root Files
- `.formatter.exs` - Code formatter configuration
- `.gitignore` - Git ignore rules
- `mix.exs` - Mix project configuration
- `mix.lock` - Dependency lock file
- `README.md` - Project overview
- `FILE_STRUCTURE.md` - This file structure documentation

## Assets (Frontend)
```
assets/
├── package.json - Node.js dependencies
├── tailwind.config.js - Tailwind CSS configuration
├── css/
│   └── app.css - Main stylesheet with Tailwind imports
└── js/
    ├── app.js - Main JavaScript entry point
    ├── hooks/ - LiveView hooks
```

## Configuration
```
config/
├── config.exs - Base configuration
├── dev.exs - Development environment configuration
├── prod.exs - Production environment configuration
├── runtime.exs - Runtime configuration
└── test.exs - Test environment configuration
```

## Documentation
```
docs/
├── Claude-Code.md - Claude AI coding documentation
├── Cloudflare.md - Cloudflare service documentation
├── Instagram.md - Instagram platform documentation
├── LLC.md - LLC formation documentation
├── Tiktok.md - TikTok platform documentation
└── Youtube.md - YouTube platform documentation
```

## Application Code
```
lib/
├── myapp.ex - Main application module
├── myapp_web.ex - Web-related module imports and aliases
├── myapp/ - Core application logic
│   ├── application.ex - OTP Application setup
│   ├── repo.ex - Database repository
│   └── [other core modules]
└── myapp_web/ - Web interface
    ├── endpoint.ex - HTTP endpoint configuration
    ├── router.ex - URL routing
    ├── channels/ - WebSocket channels
    ├── components/ - Reusable UI components
    │   ├── core_components.ex
    │   ├── layouts.ex
    │   └── layouts/
    ├── controllers/ - Request handlers
    │   ├── error_html.ex
    │   ├── error_json.ex
    │   └── [other controllers]
    └── live/ - LiveView modules
        └── [LiveView controllers]
```

## Private Files
```
priv/
├── gettext/ - Internationalization
├── repo/
│   ├── seeds.exs - Database seed data
│   └── migrations/ - Database migrations
└── static/ - Static files served by Phoenix
    ├── favicon.ico
    ├── robots.txt
    ├── assets/ - Compiled assets
    └── images/ - Static images
```

## Tests
```
test/
├── test_helper.exs - Test configuration
├── myapp/ - Core application tests
└── myapp_web/ - Web interface tests
    ├── controllers/
    └── live/
```

## Scripts
```
scripts/
└── [utility scripts]
```

## Release Configuration
```
rel/
└── [release configuration]
```
