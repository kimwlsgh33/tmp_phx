defmodule MyappWeb.DashboardLive.Components.UploadTabs.SnsAdvancedSettings.TiktokSettingsComponent do
  use MyappWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    platform_key = :tiktok
    platform_settings = assigns[:advanced_settings][platform_key] || %{}

    socket =
      socket
      |> assign(assigns)
      |> assign(:platform_key, platform_key)
      |> assign(:platform_settings, Map.merge(%{
        "privacy" => "public",
        "allow_comments" => true,
        "allow_duet" => true,
        "allow_stitch" => true,
        "automatically_add_captions" => false
      }, platform_settings))

    {:ok, socket}
  end

  @impl true
  def handle_event("update_setting", params, socket) do
    updated_settings = update_settings(socket.assigns.platform_settings, params)

    # 메시지를 대시보드 LiveView로 직접 전송
    send(self(), {:advanced_settings_updated, %{platform: socket.assigns.platform_key, settings: updated_settings}})

    {:noreply, assign(socket, :platform_settings, updated_settings)}
  end

  # Process form parameters with the specific format used by the web form
  defp update_settings(settings, params) do
    params
    |> Enum.reduce(settings, fn
      # Skip target and unused parameters
      {"_target", _}, acc -> acc
      {"_unused_" <> _, _}, acc -> acc
      
      # Handle select/dropdown values (key=field&value format)
      {key, value}, acc when is_binary(key) and binary_part(key, 0, min(4, byte_size(key))) == "key=" ->
        case String.split(key, "&") do
          [param_key, "value"] -> 
            # For select inputs, just use the value directly
            real_key = String.replace_prefix(param_key, "key=", "")
            Map.put(acc, real_key, value)
            
          [param_key, "checked"] -> 
            # For checkbox inputs, convert to boolean
            real_key = String.replace_prefix(param_key, "key=", "")
            is_checked = value == "on" || value == "true"
            Map.put(acc, real_key, is_checked)
            
          _ -> acc  # Skip unknown formats
        end
        
      # Skip any other parameters
      _, acc -> acc
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="tiktok-advanced-settings">
      <h4 class="text-md font-medium text-black mb-3 flex items-center">
        <svg class="w-5 h-5 mr-1" viewBox="0 0 24 24">
          <path fill="#000000" d="M19.59 6.69a4.83 4.83 0 01-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 01-5.2 1.74 2.89 2.89 0 012.31-4.64 2.93 2.93 0 01.88.13V9.4a6.84 6.84 0 00-1-.05A6.33 6.33 0 005 20.1a6.34 6.34 0 0010.86-4.43v-7a8.16 8.16 0 004.77 1.52v-3.4a4.85 4.85 0 01-1-.1z"/>
        </svg>
      </h4>

      <div class="space-y-3">
        <form phx-change="update_setting" phx-target={@myself}>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Privacy</label>
            <select
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              name="key=privacy&value"
            >
              <option value="public" selected={@platform_settings["privacy"] == "public"}>Public</option>
              <option value="friends" selected={@platform_settings["privacy"] == "friends"}>Friends</option>
              <option value="private" selected={@platform_settings["privacy"] == "private"}>Only Me</option>
            </select>
          </div>

          <div class="mt-3">
            <label class="flex items-center">
              <input
                type="checkbox"
                class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
                name="key=allow_comments&checked"
                checked={@platform_settings["allow_comments"]}
              />
              <span class="ml-2 text-sm text-gray-700">Allow comments</span>
            </label>
          </div>

          <div class="mt-3">
            <label class="flex items-center">
              <input
                type="checkbox"
                class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
                name="key=allow_duet&checked"
                checked={@platform_settings["allow_duet"]}
              />
              <span class="ml-2 text-sm text-gray-700">Allow duet</span>
            </label>
          </div>

          <div class="mt-3">
            <label class="flex items-center">
              <input
                type="checkbox"
                class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
                name="key=allow_stitch&checked"
                checked={@platform_settings["allow_stitch"]}
              />
              <span class="ml-2 text-sm text-gray-700">Allow stitch</span>
            </label>
          </div>

          <div class="mt-3">
            <label class="flex items-center">
              <input
                type="checkbox"
                class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
                name="key=automatically_add_captions&checked"
                checked={@platform_settings["automatically_add_captions"]}
              />
              <span class="ml-2 text-sm text-gray-700">Auto-generate captions</span>
            </label>
          </div>
        </form>
      </div>
    </div>
    """
  end
end
