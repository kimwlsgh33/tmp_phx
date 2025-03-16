# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :myapp,
  ecto_repos: [Myapp.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :myapp, MyappWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MyappWeb.Error.ErrorHTML, json: MyappWeb.Error.ErrorJSON],
    layout: false
  ],
  pubsub_server: Myapp.PubSub,
  live_view: [signing_salt: "JqSKVQGL"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :myapp, Myapp.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  myapp: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  myapp: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configures the Youtube API
config :google_api_you_tube,
  key: System.get_env("YOUTUBE_API_KEY")

# Configures the Thread API
config :myapp, :thread_api, access_token: System.get_env("THREAD_API_ACCESS_TOKEN")

# Configures the TikTok API
config :myapp, :tiktok_api,
  client_key: System.get_env("TIKTOK_CLIENT_KEY"),
  client_secret: System.get_env("TIKTOK_CLIENT_SECRET"),
  access_token: System.get_env("TIKTOK_ACCESS_TOKEN")

# Instagram configuration
config :myapp, Myapp.Instagram,
  access_token: System.get_env("INSTAGRAM_ACCESS_TOKEN"),
  client_id: System.get_env("INSTAGRAM_CLIENT_ID"),
  client_secret: System.get_env("INSTAGRAM_CLIENT_SECRET"),
  redirect_uri: System.get_env("INSTAGRAM_REDIRECT_URI")

# Configures the Twitter API
config :myapp, :twitter_api,
  api_key: System.get_env("TWITTER_API_KEY"),
  api_secret: System.get_env("TWITTER_API_SECRET"),
  redirect_uri: System.get_env("TWITTER_REDIRECT_URI")

config :dotenv, env_file: ".env"

# Basic Ueberauth configuration - provider-specific config moved to runtime.exs
# Log OAuth configuration during application startup
config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "email profile"]}
  ]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
