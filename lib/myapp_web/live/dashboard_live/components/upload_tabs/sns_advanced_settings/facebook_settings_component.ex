defmodule MyappWeb.DashboardLive.Components.UploadTabs.SnsAdvancedSettings.FacebookSettingsComponent do
  use MyappWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    platform_key = assigns.platform_key
    # Extract platform-specific settings from the complete settings map
    # Support both string and atom keys for backward compatibility
    platform_settings =
      Map.get(assigns.advanced_settings, platform_key, %{}) ||
      Map.get(assigns.advanced_settings, String.to_existing_atom(platform_key), %{})

    # Ensure default values for facebook settings
    default_settings = %{
      "privacy" => "public",
      "allow_comments" => true,
      "location" => "",
      "feeling" => ""
    }

    # Merge defaults with existing settings
    merged_settings = Map.merge(default_settings, platform_settings)

    socket =
      socket
      |> assign(assigns)
      |> assign(:platform_settings, merged_settings)

    {:ok, socket}
  end

  @impl true
  def handle_event("update_setting", params, socket) do
    # Log incoming params to help with debugging
    IO.inspect(params, label: "Facebook Settings update_setting params")

    updated_settings = update_settings(socket.assigns.platform_settings, params)

    # Store updated settings locally
    socket = assign(socket, :platform_settings, updated_settings)

    # Send event to the root LiveView instead of directly to parent component
    # This will enable us to bypass the problematic CID parent_pid
    send(self(), {:advanced_settings_updated, %{
      platform: socket.assigns.platform_key,
      settings: updated_settings
    }})

    {:noreply, socket}
  end

  # Handle "key=field&value" format
  defp update_settings(settings, %{"key" => key_value_pair, "value" => value}) do
    case String.split(key_value_pair, "=", parts: 2) do
      [key, _] -> Map.put(settings, key, value)
      _ -> settings # If no valid key format, return settings unchanged
    end
  end

  # Handle "key=field&checked" format
  defp update_settings(settings, %{"key" => key_value_pair, "checked" => checked}) do
    case String.split(key_value_pair, "=", parts: 2) do
      [key, _] -> Map.put(settings, key, checked == "true")
      _ -> settings # If no valid key format, return settings unchanged
    end
  end

  # Handle direct key-value pairs (fallback for other formats)
  defp update_settings(settings, %{"value" => value}) do
    # For direct value updates without a key, just return the original settings
    # This is a fallback for when we receive unexpected data format
    settings
  end

  # Fallback clause to prevent crashes
  defp update_settings(settings, _params) do
    # If we get an unexpected parameter format, just return the original settings
    settings
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="facebook-advanced-settings">
      <div class="space-y-3">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Privacy</label>
          <select
            class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            phx-change="update_setting"
            phx-target={@myself}
            name="key=privacy&value"
          >
            <option value="public" selected={@platform_settings["privacy"] == "public"}>Public</option>
            <option value="friends" selected={@platform_settings["privacy"] == "friends"}>Friends</option>
            <option value="private" selected={@platform_settings["privacy"] == "private"}>Only Me</option>
          </select>
        </div>

        <div>
          <label class="flex items-center">
            <input
              type="checkbox"
              class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
              phx-change="update_setting"
              phx-target={@myself}
              name="key=allow_comments&checked"
              checked={@platform_settings["allow_comments"]}
            />
            <span class="ml-2 text-sm text-gray-700">Allow comments</span>
          </label>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Location</label>
          <input
            type="text"
            class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            placeholder="Add a location"
            phx-blur="update_setting"
            phx-target={@myself}
            name="key=location&value"
            value={@platform_settings["location"]}
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Feeling/Activity</label>
          <input
            type="text"
            class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            placeholder="How are you feeling?"
            phx-blur="update_setting"
            phx-target={@myself}
            name="key=feeling&value"
            value={@platform_settings["feeling"]}
          />
        </div>
      </div>
    </div>
    """
  end
end
