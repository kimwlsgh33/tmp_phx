defmodule MyappWeb.Router do
  use MyappWeb, :router

  import MyappWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyappWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :log_request
  end

  pipeline :browser_without_layout do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_api_user
  end

  # ----------------------------------------------------------------------

  def log_request(conn, _opts) do
    IO.inspect(conn.request_path, label: "Requested Path")
    IO.inspect(System.get_env("GOOGLE_CLIENT_ID"), label: "Client ID in Controller")
    conn
  end

  # ----------------------------------------------------------------------

  # Landing page route
  scope "/", MyappWeb do
    pipe_through :browser_without_layout

    get "/", LandingController, :index
  end

  # Main browser routes
  scope "/", MyappWeb do
    pipe_through :browser

    # General/Test routes
    get "/test/dashboard", TestController, :dashboard

    # Legal pages
    get "/privacy-policy/:version", PrivacyPolicyController, :page
    get "/terms-of-services/:version", TermsOfServicesController, :page

    # Marketing pages
    scope "/marketing" do
      # Pricing routes
      get "/pricing", PricingController, :index
      get "/features", FeaturesController, :index

      # Company route
      get "/company", CompanyController, :index
    end

    # Documentation routes
    scope "/docs" do
      get "/", DocsController, :index
      get "/:topic", DocsController, :show
    end

    # Social Media Integration

    # TikTok routes
    scope "/tiktok" do
      get "/", TiktokController, :show
      get "/upload", TiktokController, :upload_form
      post "/upload", TiktokController, :upload_video
      get "/connect", TiktokController, :connect
      get "/auth/callback", TiktokController, :auth_callback
    end

    # Twitter routes
    scope "/twitter" do
      get "/", TwitterController, :show
      get "/tweet", TwitterController, :tweet_form
      post "/tweet", TwitterController, :post_tweet
      get "/connect", TwitterController, :connect
      get "/auth/callback", TwitterController, :auth_callback
      delete "/tweet/:id", TwitterController, :delete_tweet
    end

    # Instagram routes
    scope "/instagram" do
      get "/", InstagramController, :show
      get "/upload", InstagramController, :upload_form
      post "/upload", InstagramController, :upload_media
      get "/connect", InstagramController, :connect
      get "/auth/callback", InstagramController, :auth_callback
    end

    # YouTube routes
    scope "/youtube" do
      get "/", YoutubeController, :show
      get "/connect", YoutubeController, :connect
      get "/auth/callback", YoutubeController, :auth_callback
      get "/upload", YoutubeController, :upload_form
      post "/upload", YoutubeController, :upload_video
      post "/search", YoutubeController, :search
      live "/search-live", YoutubeSearchLive
    end

    # LiveView routes
    live "/counter", CounterLive
    live "/files", FileLive
    live "/search", SearchLive
    
    # Replace the three separate upload routes with a single consolidated route
    live "/upload", UploadLive
    
    # Keep the individual routes for direct access if needed, but they can be removed
    # if you want to force users to go through the main upload page
    live "/upload/post", Upload.PostLive
    live "/upload/short", Upload.ShortLive
    live "/upload/long", Upload.LongLive
  end

  # Other scopes may use custom stacks.
  # API routes
  scope "/api", MyappWeb do
    pipe_through :api

    # File operations
    scope "/files" do
      post "/upload", FileController, :upload
      get "/:filename", FileController, :download
    end

    # Thread operations
    scope "/threads" do
      post "/", ThreadController, :create
      get "/:id", ThreadController, :show
      delete "/:id", ThreadController, :delete
      post "/:thread_id/reply", ThreadController, :reply
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:myapp, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MyappWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  # Routes for non-authenticated users
  scope "/", MyappWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{MyappWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create

    # Google OAuth login route
  end

  scope "/auth", MyappWeb do
    pipe_through :browser
    get "/:provider", GoogleController, :request
    get "/:provider/callback", GoogleController, :callback
    delete "/logout", GoogleController, :delete
  end

  # Routes requiring authentication
  scope "/", MyappWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{MyappWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  # Routes available to all users
  scope "/", MyappWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{MyappWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
