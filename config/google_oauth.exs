import Config

# Google OAuth Configuration
# This file contains the settings for Google OAuth integration

config :myapp, Myapp.GoogleOauth,
  client_id: System.get_env("GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET"),
  redirect_uri: System.get_env("GOOGLE_REDIRECT_URI") || "http://localhost:4000/google/oauth/callback",
  site: "https://accounts.google.com",
  authorize_url: "https://accounts.google.com/o/oauth2/v2/auth",
  token_url: "https://oauth2.googleapis.com/token",
  user_info_url: "https://www.googleapis.com/oauth2/v3/userinfo",
  auth_style: :basic,  # For Google OAuth, this setting determines how credentials are passed (in header or in body)
  scopes: ["email", "profile"]

# You need to register your app in the Google Developer Console:
# 1. Go to https://console.developers.google.com/
# 2. Create a new project or select an existing one
# 3. Go to "Credentials" and create an "OAuth client ID"
# 4. Set the application type to "Web application"
# 5. Add your redirect URI (e.g., http://localhost:4000/google/oauth/callback for development)
# 6. Get your Client ID and Client Secret

# Important: To use this configuration in your application, you need to:
# 1. Set the environment variables in your .env file or on your deployment platform:
#    - GOOGLE_CLIENT_ID
#    - GOOGLE_CLIENT_SECRET
#    - GOOGLE_REDIRECT_URI (optional, defaults to localhost in development)
#
# 2. Import this file in your config/config.exs:
#    import_config "google_oauth.exs"
#
# 3. Make sure your GoogleOauth module is configured to use these settings

# Remember to add environment-specific configuration in dev.exs, prod.exs, etc.
# For production, consider using runtime.exs to load secrets from environment variables

