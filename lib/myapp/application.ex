defmodule Myapp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    # Load environment variables with strict checking (will raise on errors)
    Logger.info("Loading environment variables from .env file...")
    Dotenv.load!()
    
    # Configure OAuth settings explicitly
    configure_oauth()
    
    # Verify critical environment variables
    verify_environment_variables()
    
    children = [
      MyappWeb.Telemetry,
      Myapp.Repo,
      {DNSCluster, query: Application.get_env(:myapp, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Myapp.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Myapp.Finch},
      # Start the YouTube API client
      Myapp.Youtube,
      # Start to serve requests, typically the last entry
      MyappWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Myapp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MyappWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Configure OAuth settings explicitly after loading environment variables
  defp configure_oauth do
    Logger.info("Configuring OAuth settings...")
    
    client_id = System.get_env("GOOGLE_CLIENT_ID")
    client_secret = System.get_env("GOOGLE_CLIENT_SECRET")
    
    if client_id && client_secret do
      # Mask sensitive values in logs
      masked_id = if client_id, do: String.slice(client_id, 0, 6) <> "..." <> String.slice(client_id, -4, 4), else: "nil"
      masked_secret = if client_secret, do: String.slice(client_secret, 0, 3) <> "..." <> String.slice(client_secret, -3, 3), else: "nil"
      
      Logger.info("OAuth Configuration: client_id=#{masked_id}, client_secret=#{masked_secret}")
      
      # Set up OAuth config at runtime using Application.put_env
      oauth_config = [
        client_id: client_id,
        client_secret: client_secret,
        redirect_uri: "http://localhost:4000/auth/google/callback"
      ]
      
      # Configure Ueberauth.Strategy.Google.OAuth
      Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth, oauth_config)
      
      # Configure Ueberauth providers
      ueberauth_config = [
        providers: [
          google: {Ueberauth.Strategy.Google, [
            default_scope: "email profile",
            prompt: "consent",
            access_type: "offline"
          ]}
        ]
      ]
      
      # Apply the Ueberauth config
      Application.put_env(:ueberauth, Ueberauth, ueberauth_config)
      
      # Verify and log the actual configuration that will be used
      actual_oauth_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Google.OAuth)
      Logger.info("Verified OAuth configuration: #{inspect(actual_oauth_config, pretty: true)}")
      
      :ok
    else
      Logger.warning("OAuth credentials not found in environment variables")
      :error
    end
  end

  # Verify that all required environment variables are set
  defp verify_environment_variables do
    Logger.info("Verifying environment variables...")
    
    required_vars = [
      {"GOOGLE_CLIENT_ID", "Google OAuth client ID"},
      {"GOOGLE_CLIENT_SECRET", "Google OAuth client secret"}
    ]
    
    missing_vars = Enum.filter(required_vars, fn {var, _desc} -> 
      val = System.get_env(var)
      is_nil(val) || val == ""
    end)
    
    case missing_vars do
      [] -> 
        Logger.info("✅ All required environment variables are set")
        :ok
      vars -> 
        vars_desc = Enum.map_join(vars, ", ", fn {var, desc} -> "#{var} (#{desc})" end)
        Logger.error("❌ Missing required environment variables: #{vars_desc}")
        # Don't raise here to allow the application to start for debugging purposes
        # But log a prominent error message
        Logger.error("WARNING: Application may not function correctly without required environment variables")
        :error
    end
  end
end

