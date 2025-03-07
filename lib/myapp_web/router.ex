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

  scope "/", MyappWeb do
    pipe_through :browser_without_layout

    get "/", LandingController, :index
  end

  scope "/", MyappWeb do
    pipe_through :browser

    get "/test/landing", PageController, :home
    get "/test", TestController, :page
    post "/test/search", TestController, :search
    
    # YouTube routes
    get "/youtube", YoutubeController, :index
    post "/youtube/search", YoutubeController, :search
    
    get "/privacy-policy/:version", PrivacyPolicyController, :page
    get "/terms-of-services/:version", TermsOfServicesController, :page
    live "/counter", CounterLive
    live "/files", FileLive

    # Documentation routes
    get "/docs", DocsController, :index
    get "/docs/:topic", DocsController, :show

    # Pricing route
    get "/pricing", PricingController, :index
    get "/features", FeaturesController, :index

    # Company route
    get "/company", CompanyController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", MyappWeb do
    pipe_through :api

    post "/files/upload", FileController, :upload
    get "/files/:filename", FileController, :download

    # Thread API routes
    post "/threads", ThreadController, :create
    post "/threads/:thread_id/reply", ThreadController, :reply
    get "/threads/:id", ThreadController, :show
    delete "/threads/:id", ThreadController, :delete
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
  end

  scope "/", MyappWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{MyappWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

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
