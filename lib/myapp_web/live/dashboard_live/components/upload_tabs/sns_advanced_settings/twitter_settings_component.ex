defmodule MyappWeb.DashboardLive.Components.UploadTabs.SnsAdvancedSettings.TwitterSettingsComponent do
  use MyappWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    platform_key = :twitter
    platform_settings = assigns[:advanced_settings][platform_key] || %{}
    
    # Ensure default values for twitter settings
    default_settings = %{
      "allow_replies" => "everyone", 
      "add_location" => false,
      "alt_text" => "",
      "sensitive_content" => false
    }
    
    socket =
      socket
      |> assign(assigns)
      |> assign(:platform_key, platform_key)
      |> assign(:platform_settings, Map.merge(default_settings, platform_settings))

    {:ok, socket}
  end

  @impl true
  def handle_event("update_setting", params, socket) do
    # 로그를 추가하여 디버깅에 도움이 되도록 합니다
    IO.inspect(params, label: "Twitter form params")
    
    updated_settings = update_settings(socket.assigns.platform_settings, params)

    # 메시지를 대시보드 LiveView로 직접 전송
    send(self(), {:advanced_settings_updated, %{platform: socket.assigns.platform_key, settings: updated_settings}})

    {:noreply, assign(socket, :platform_settings, updated_settings)}
  end
  
  # 폼에서 전달된 파라미터를 처리하는 새로운 함수
  defp update_settings(settings, params) do
    # _target, _csrf 등의 내부 필드는 무시
    params
    |> Enum.reduce(settings, fn
      {"_" <> _, _}, acc -> 
        # 언더스코어로 시작하는 필드는 Phoenix 내부 필드이므로 무시
        acc
      
      {"key=" <> rest, value}, acc ->
        # key= 접두사를 가진 폼 필드 처리
        case String.split(rest, "&") do
          [key, "value"] -> 
            # 값을 가진 필드 (예: select, input text)
            Map.put(acc, key, value)
          
          [key, "checked"] -> 
            # 체크박스
            Map.put(acc, key, value == "on")
            
          _ -> acc
        end
        
      _, acc -> acc  # 기타 필드 무시
    end)
  end
  
  # 폼에서 예상하지 못한 형식의 데이터가 오는 경우에 대한 폴백 처리
  defp update_settings(settings, params) when map_size(params) == 0 do
    settings
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="twitter-advanced-settings">
      <h4 class="text-md font-medium text-blue-400 mb-3 flex items-center">
        <svg class="w-5 h-5 mr-1" viewBox="0 0 24 24" fill="#1DA1F2">
          <path d="M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z"/>
        </svg>
      </h4>

      <div class="space-y-3">
        <form phx-change="update_setting" phx-target={@myself}>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Who can reply</label>
            <select
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              name="key=allow_replies&value"
            >
              <option value="everyone" selected={@platform_settings["allow_replies"] == "everyone"}>Everyone</option>
              <option value="following" selected={@platform_settings["allow_replies"] == "following"}>People you follow</option>
              <option value="mentioned" selected={@platform_settings["allow_replies"] == "mentioned"}>Only people you mention</option>
            </select>
          </div>

          <div class="mt-3">
            <label class="flex items-center">
              <input
                type="checkbox"
                class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
                name="key=add_location&checked"
                checked={@platform_settings["add_location"]}
              />
              <span class="ml-2 text-sm text-gray-700">Add location information</span>
            </label>
          </div>

          <div class="mt-3">
            <label class="block text-sm font-medium text-gray-700 mb-1">Image alt text</label>
            <input
              type="text"
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              placeholder="Describe your image for visually impaired"
              name="key=alt_text&value"
              value={@platform_settings["alt_text"]}
            />
            <p class="mt-1 text-xs text-gray-500">Make your images accessible</p>
          </div>

          <div class="mt-3">
            <label class="flex items-center">
              <input
                type="checkbox"
                class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
                name="key=sensitive_content&checked"
                checked={@platform_settings["sensitive_content"]}
              />
              <span class="ml-2 text-sm text-gray-700">Mark as sensitive content</span>
            </label>
          </div>
        </form>
      </div>
    </div>
    """
  end
end
