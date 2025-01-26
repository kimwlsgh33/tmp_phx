# Project File Structure

## Root Files
- `.formatter.exs` - Code formatter configuration
- `.gitignore` - Git ignore rules
- `elixir_buildpack.config` - Buildpack configuration
- `mix.exs` - Mix project configuration
- `mix.lock` - Dependency lock file
- `phoenix_static_buildpack.config` - Phoenix static assets build config
- `README.md` - Project overview

## Assets (Frontend)
```
assets/
├── package.json
├── tailwind.config.js
├── css/
│   └── app.css
└── js/
    ├── app.js
    ├── user_socket.js
    └── hooks/
        └── theme_toggle.js
```

## Configuration
```
config/
├── config.exs
├── dev.exs
├── prod.exs
├── runtime.exs
└── test.exs
```

## Documentation
```
docs/
├── CONTRIBUTING.md
├── README.md
├── STYLE-GUIDE.md
├── api/
│   ├── authentication.md
│   ├── graphql.md
│   ├── protocols.md
│   └── rest.md
├── architecture/
│   ├── communication.md
│   ├── components.md
│   ├── error-handling.md
│   ├── overview.md
│   ├── postgresql.md
│   └── state-management.md
├── deployment/
│   ├── environments.md
│   ├── operations.md
│   ├── performance.md
│   ├── README.md
│   └── reliability.md
├── development/
│   ├── README.md
│   ├── guidelines/
│   ├── implementation/
│   └── processes/
├── frontend/
│   ├── components.md
│   ├── js-interop.md
│   └── styling.md
├── getting-started/
│   ├── configuration.md
│   ├── installation.md
│   └── quick-start.md
├── procedure/
│   ├── errs/
│   ├── feats/
│   └── usages/
└── testing/
    ├── integration.md
    └── unit.md
```

## Application Code
```
lib/
├── myapp.ex
├── myapp_web.ex
├── myapp/
│   ├── accounts.ex
│   ├── application.ex
│   ├── file_server.ex
│   ├── mailer.ex
│   ├── privacy_policy.ex
│   ├── release.ex
│   ├── repo.ex
│   └── accounts/
│       ├── user_notifier.ex
│       ├── user_token.ex
│       └── user.ex
└── myapp_web/
    ├── endpoint.ex
    ├── gettext.ex
    ├── privacy_policy_localizer.ex
    ├── router.ex
    ├── telemetry.ex
    ├── user_auth.ex
    ├── channels/
    │   ├── chat_channel.ex
    │   └── user_socket.ex
    ├── components/
    │   ├── core_components.ex
    │   ├── layouts.ex
    │   └── layouts/
    ├── controllers/
    │   ├── error_html.ex
    │   ├── error_json.ex
    │   ├── file_controller.ex
    │   ├── privacy_policy_controller.ex
    │   ├── privacy_policy_html.ex
    │   ├── user_session_controller.ex
    │   ├── page/
    │   └── privacy_policy_html/
    └── live/
        ├── user_confirmation_instructions_live.ex
        ├── user_confirmation_live.ex
        ├── user_forgot_password_live.ex
        ├── user_login_live.ex
        ├── user_registration_live.ex
        ├── user_reset_password_live.ex
        ├── user_settings_live.ex
        ├── counter_live/
        └── file_live/
```

## Private Files
```
priv/
├── gettext/
│   ├── default.pot
│   ├── errors.pot
│   ├── en/
│   └── ko/
├── privacy_policy/
│   ├── Paid Terms of Services.md
│   ├── v1.json
│   ├── v1.md
│   ├── v2.json
│   └── v2.md
├── repo/
│   ├── seeds.exs
│   └── migrations/
└── static/
    ├── favicon.ico
    ├── robots.txt
    ├── assets/
    ├── images/
    └── uploads/
```

## Tests
```
test/
├── test_helper.exs
├── myapp/
│   └── accounts_test.exs
└── myapp_web/
    ├── user_auth_test.exs
    ├── channels/
    │   └── chat_channel_test.exs
    ├── controllers/
    │   ├── error_html_test.exs
    │   ├── error_json_test.exs
    │   ├── page_controller_test.exs
    │   └── user_session_controller_test.exs
    └── live/
        ├── user_confirmation_instructions_live_test.exs
        ├── user_confirmation_live_test.exs
        ├── user_forgot_password_live_test.exs
        ├── user_login_live_test.exs
        ├── user_registration_live_test.exs
        ├── user_reset_password_live_test.exs
        └── user_settings_live_test.exs
```

## Build and Release
```
_build/
rel/
└── overlays/
    └── bin/
        ├── migrate
        ├── migrate.bat
        ├── server
        └── server.bat
