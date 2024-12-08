# Configuration Guide

This document outlines the configuration options for our Phoenix application.

## Environment Configuration

### Development
Configuration file: `config/dev.exs`
```elixir
config :myapp, MyappWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "your-dev-key",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:myapp, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:myapp, ~w(--watch)]}
  ]

config :myapp, Myapp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "myapp_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

### Test
Configuration file: `config/test.exs`
```elixir
config :myapp, MyappWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test-key",
  server: false

config :myapp, Myapp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "myapp_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox
```

### Production
Configuration file: `config/runtime.exs`
```elixir
config :myapp, MyappWeb.Endpoint,
  url: [host: System.get_env("PHX_HOST") || "example.com"],
  http: [port: String.to_integer(System.get_env("PORT") || "4000")],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  server: true

config :myapp, Myapp.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
```

## Feature Configuration

### LiveView
```elixir
config :myapp, MyappWeb.Endpoint,
  live_view: [signing_salt: "your-salt"]
```

### Tailwind CSS
```elixir
config :tailwind,
  version: "3.4.0",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]
```

### Mailer (Swoosh)
```elixir
config :myapp, Myapp.Mailer,
  adapter: Swoosh.Adapters.Local
```

## Environment Variables

### Required Variables
- `SECRET_KEY_BASE`: Application secret key
- `DATABASE_URL`: Database connection URL (production)
- `PHX_HOST`: Application host (production)
- `PORT`: HTTP port (production)

### Optional Variables
- `POOL_SIZE`: Database connection pool size
- `MIX_TEST_PARTITION`: Test database partition
- `PHX_SERVER`: Whether to start the server

## Asset Configuration

### esbuild
```elixir
config :esbuild,
  version: "0.17.11",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]
```

## Logging Configuration
```elixir
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
```
