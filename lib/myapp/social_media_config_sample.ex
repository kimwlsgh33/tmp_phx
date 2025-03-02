defmodule Myapp.SocialMediaConfigSample do
  @moduledoc """
  Sample configuration file for social media integrations.
  
  This file demonstrates how to configure social media integrations in a centralized way.
  Copy this file to your config.exs (or the appropriate environment config file) and 
  update the values with your actual credentials.
  """

  def sample_config do
    """
    # Social Media Configuration
    # Add this to your config.exs, dev.exs, prod.exs, etc.

    # Centralized social media configuration
    config :myapp, :social_media,
      providers: [:twitter, :tiktok, :instagram, :youtube, :thread],
      default_scopes: %{
        twitter: ["tweet.read", "tweet.write", "users.read", "offline.access"],
        tiktok: ["user.info.basic", "video.upload", "video.list"],
        instagram: ["user_profile", "user_media"],
        youtube: ["youtube.readonly", "youtube.upload"],
        thread: ["threads.read", "threads.write"]
      },
      # Map of provider to implementation modules
      implementations: %{
        twitter: %{
          auth: Myapp.SocialAuth.Twitter,
          api: Myapp.SocialMedia.Twitter
        },
        tiktok: %{
          auth: Myapp.SocialAuth.Tiktok,
          api: Myapp.SocialMedia.Tiktok
        },
        instagram: %{
          auth: Myapp.SocialAuth.Instagram,
          api: Myapp.SocialMedia.Instagram
        },
        youtube: %{
          auth: Myapp.SocialAuth.Youtube,
          api: Myapp.SocialMedia.Youtube
        },
        thread: %{
          auth: Myapp.SocialAuth.Thread,
          api: Myapp.SocialMedia.Thread
        }
      }

    # Twitter API credentials
    config :myapp, :twitter_api,
      api_key: System.get_env("TWITTER_API_KEY"),
      api_secret: System.get_env("TWITTER_API_SECRET"),
      redirect_uri: System.get_env("TWITTER_REDIRECT_URI"),
      version: "2.0"

    # TikTok API credentials
    config :myapp, :tiktok_api,
      client_key: System.get_env("TIKTOK_CLIENT_KEY"),
      client_secret: System.get_env("TIKTOK_CLIENT_SECRET"),
      redirect_uri: System.get_env("TIKTOK_REDIRECT_URI")

    # Instagram API credentials
    config :myapp, :instagram_api,
      client_id: System.get_env("INSTAGRAM_CLIENT_ID"),
      client_secret: System.get_env("INSTAGRAM_CLIENT_SECRET"),
      redirect_uri: System.get_env("INSTAGRAM_REDIRECT_URI")

    # YouTube API credentials
    config :myapp, :youtube_api,
      client_id: System.get_env("YOUTUBE_CLIENT_ID"),
      client_secret: System.get_env("YOUTUBE_CLIENT_SECRET"),
      redirect_uri: System.get_env("YOUTUBE_REDIRECT_URI"),
      api_key: System.get_env("YOUTUBE_API_KEY")
    
    # Thread API credentials
    config :myapp, :thread_api,
      client_id: System.get_env("THREAD_CLIENT_ID"),
      client_secret: System.get_env("THREAD_CLIENT_SECRET"),
      redirect_uri: System.get_env("THREAD_REDIRECT_URI")

    # Common configurations for all social media platforms
    config :myapp, :social_media_common,
      timeout: 30_000,
      max_retries: 3,
      media_storage: %{
        temp_dir: System.get_env("MEDIA_TEMP_DIR") || "/tmp/myapp/social_media",
        max_file_size: 15_000_000,  # 15MB
        allowed_extensions: [".jpg", ".jpeg", ".png", ".gif", ".mp4", ".mov"]
      },
      rate_limiting: %{
        default_limit: 100,
        window_size: 3_600_000,  # 1 hour in milliseconds
        provider_limits: %{
          twitter: 300,
          tiktok: 200,
          instagram: 200,
          youtube: 100,
          thread: 150
        }
      }
    """
  end
end

