defmodule MyappWeb.DashboardLive.DashboardService do
  @moduledoc """
  Service module for dashboard-related functionality.
  This module handles data loading and processing for the dashboard.
  """

  @social_platforms [:twitter, :instagram, :tiktok, :youtube, :facebook]

  @doc """
  Returns the list of supported social platforms.
  """
  def social_platforms, do: @social_platforms

  @doc """
  Load social media accounts for the current user.
  In a real implementation, this would fetch the actual connection status
  for each platform from the database or API.
  """
  def load_social_accounts do
    # This is just a placeholder. In a real app, you would check if the
    # user is authenticated with each platform
    Enum.into(@social_platforms, %{}, fn platform ->
      connected = Enum.random([true, false])
      {platform, %{connected: connected}}
    end)
  end

  @doc """
  Load recent uploads for the current user.
  In a real implementation, this would fetch recent uploads from the database.
  """
  def load_recent_uploads do
    [
      %{
        id: "1",
        timestamp: ~N[2025-04-05 10:30:00],
        platforms: [:twitter, :instagram],
        status: :success,
        links: %{
          twitter: "https://twitter.com/user/status/123456789",
          instagram: "https://instagram.com/p/ABC123"
        }
      },
      %{
        id: "2",
        timestamp: ~N[2025-04-04 15:45:00],
        platforms: [:youtube],
        status: :processing,
        links: %{
          youtube: nil
        }
      },
      %{
        id: "3",
        timestamp: ~N[2025-04-03 09:15:00],
        platforms: [:tiktok, :facebook],
        status: :failed,
        links: %{},
        error: "Upload failed: invalid token"
      }
    ]
  end

  @doc """
  Format a list of platform atoms into a comma-separated string.
  """
  def format_platform_names(platforms) do
    Enum.map_join(platforms, ", ", fn p ->
      p |> Atom.to_string() |> String.capitalize()
    end)
  end

  @doc """
  Toggle a platform in the selected platforms list.
  """
  def toggle_platform(selected_platforms, platform) do
    if platform in selected_platforms do
      Enum.reject(selected_platforms, fn p -> p == platform end)
    else
      [platform | selected_platforms]
    end
  end

  @doc """
  Update the connection status of a platform.
  """
  def disconnect_platform(social_accounts, platform) do
    Map.update!(
      social_accounts,
      platform,
      fn status -> %{status | connected: false} end
    )
  end

  @doc """
  Get the color class for a platform.
  """
  def platform_color(platform) do
    case platform do
      :twitter -> "bg-blue-500"
      :instagram -> "bg-pink-600"
      :facebook -> "bg-blue-700"
      :youtube -> "bg-red-600"
      :tiktok -> "bg-black"
      # Default color
      _ -> "bg-gray-600"
    end
  end
end
