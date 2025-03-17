defmodule MyappWeb.FeaturesController do
  use MyappWeb, :controller

  def index(conn, _params) do
    features = [
      %{
        id: "social-media",
        title: "Social Media Integration",
        description: "Seamlessly integrate with popular social media platforms",
        platforms: ["YouTube", "Instagram", "TikTok", "Twitter"],
        icon: "share-alt"
      },
      %{
        id: "authentication",
        title: "Authentication System",
        description: "Secure and flexible authentication options for your users",
        methods: ["Password-based", "OAuth with major providers"],
        icon: "lock"
      },
      %{
        id: "realtime",
        title: "Real-time Features",
        description: "Stay connected with instant updates and notifications",
        examples: ["Live notifications", "Real-time analytics", "Instant messaging"],
        icon: "bolt"
      },
      %{
        id: "liveview",
        title: "LiveView Interactive UI",
        description: "Dynamic, responsive interfaces without writing JavaScript",
        benefits: ["Reduced complexity", "Faster development", "Better user experience"],
        icon: "desktop"
      },
      %{
        id: "email",
        title: "Email Support",
        description: "Comprehensive email functionality for your application",
        features: ["Transactional emails", "Marketing campaigns", "Customizable templates"],
        icon: "envelope"
      },
      %{
        id: "multilanguage",
        title: "Multi-language Support",
        description: "Reach a global audience with localization support",
        capabilities: ["Translation management", "Right-to-left language support", "Regional formatting"],
        icon: "language"
      },
      %{
        id: "api",
        title: "API Integrations",
        description: "Connect with third-party services and expand functionality",
        integrations: ["Payment gateways", "Analytics platforms", "Cloud services"],
        icon: "plug"
      }
    ]

    render(conn, :index, features: features)
  end
end

defmodule MyappWeb.FeaturesController do
  use MyappWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
